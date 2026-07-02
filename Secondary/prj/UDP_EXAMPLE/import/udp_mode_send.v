// ============================================================
// 模块名称: udp_mode_send
// 功能描述: 发送16位模式切换命令给母板（大端序）
//           命令格式：2字节，高字节在前
//           0x0001 = 摄像头模式
//           0x0003 = SD卡模式
// ============================================================
module udp_mode_send(
    input               clk,
    input               rst_n,

    // 输入命令
    input [15:0]        mode_cmd,           // 16位命令（0x0001或0x0003）
    input               mode_cmd_valid,     // 命令有效信号（脉冲）

    // UDP发送接口
    input               udp_tx_ready,
    input               app_tx_ack,
    output reg          app_tx_data_request,
    output reg          app_tx_data_valid,
    output reg [7:0]    app_tx_data,
    output reg [15:0]   udp_data_length
);

// 状态机定义
localparam  IDLE            = 3'd0;
localparam  WAIT_READY      = 3'd1;
localparam  SEND_HIGH_BYTE  = 3'd2;
localparam  SEND_LOW_BYTE   = 3'd3;
localparam  DONE            = 3'd4;

reg [2:0]   state;
reg [15:0]  cmd_reg;    // 命令寄存器

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state               <= IDLE;
        app_tx_data_request <= 1'b0;
        app_tx_data_valid   <= 1'b0;
        app_tx_data         <= 8'h00;
        udp_data_length     <= 16'd2;     // 固定2字节
        cmd_reg             <= 16'h0000;
    end
    else begin
        case(state)
            // ========== 空闲状态 ==========
            IDLE: begin
                app_tx_data_request <= 1'b0;
                app_tx_data_valid   <= 1'b0;

                // 检测到命令有效信号
                if(mode_cmd_valid) begin
                    cmd_reg             <= mode_cmd;
                    app_tx_data_request <= 1'b1;
                    state               <= WAIT_READY;
                end
            end

            // ========== 等待UDP就绪 ==========
            WAIT_READY: begin
                if(udp_tx_ready && app_tx_ack) begin
                    app_tx_data_request <= 1'b0;
                    state               <= SEND_HIGH_BYTE;
                end
            end

            // ========== 发送高字节 ==========
            SEND_HIGH_BYTE: begin
                app_tx_data       <= cmd_reg[15:8];  // 高字节
                app_tx_data_valid <= 1'b1;
                state             <= SEND_LOW_BYTE;
            end

            // ========== 发送低字节 ==========
            SEND_LOW_BYTE: begin
                app_tx_data       <= cmd_reg[7:0];   // 低字节
                app_tx_data_valid <= 1'b1;
                state             <= DONE;
            end

            // ========== 发送完成 ==========
            DONE: begin
                app_tx_data_valid <= 1'b0;
                state             <= IDLE;
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
