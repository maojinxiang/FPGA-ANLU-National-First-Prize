// ============================================================
// 模块名称: udp_mode_tx
// 功能描述: key4按键触发，发送模式切换命令给母板
//           完全参考udp_tx_simple的实现方式
//           按下key4切换：0x0004左目摄像头原始图像 ↔ 0x0003 SD卡
// ============================================================
module udp_mode_tx(
    input               clk,
    input               rst_n,
    input               key4,       // 按键输入（低电平有效）

    // UDP发送接口
    input               udp_tx_ready,
    input               app_tx_ack,
    output reg          app_tx_data_request,
    output reg          app_tx_data_valid,
    output reg [7:0]    app_tx_data,
    output reg [15:0]   udp_data_length
);

// ============================================================================
// 状态机定义
// ============================================================================
localparam  IDLE            = 3'd0;  // 等待按键触发
localparam  WAIT_UDP        = 3'd1;  // 等待UDP准备好
localparam  WAIT_ACK        = 3'd2;  // 等待UDP应答
localparam  SEND_DATA       = 3'd3;  // 发送命令数据
localparam  DONE            = 3'd4;  // 完成

reg [2:0]   STATE;

// ============================================================================
// 按键检测（去抖动和边缘检测）
// ============================================================================
reg [19:0]  key4_cnt;       // 按键去抖计数器
reg         key4_stable;    // 稳定后的按键值
reg         key4_stable_d1; // 延迟1拍
wire        key4_negedge;   // 按键按下沿

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key4_cnt <= 20'd0;
        key4_stable <= 1'b1;
    end
    else begin
        if(key4 == key4_stable) begin
            key4_cnt <= 20'd0;
        end
        else begin
            key4_cnt <= key4_cnt + 1'd1;
            if(key4_cnt >= 20'd1000000) begin  // 8ms去抖
                key4_stable <= key4;
                key4_cnt <= 20'd0;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        key4_stable_d1 <= 1'b1;
    else
        key4_stable_d1 <= key4_stable;
end

assign key4_negedge = key4_stable_d1 && !key4_stable;  // 按下沿

// ============================================================================
// 寄存器定义
// ============================================================================
reg [15:0]  send_data_cnt;
reg         mode_toggle;    // 0=SD卡(0x0003), 1=左目摄像头(0x0004)

// 模式命令（大端序）
wire [15:0] MODE_CMD_CAM = 16'h0400;  // 0x0004 左目摄像头原始图像，发送顺序: 0x00, 0x04
wire [15:0] MODE_CMD_SD  = 16'h0300;  // 0x0003 SD卡，发送顺序: 0x00, 0x03

// ============================================================================
// 主状态机
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        STATE               <= IDLE;
        app_tx_data_request <= 1'b0;
        app_tx_data_valid   <= 1'b0;
        app_tx_data         <= 8'd0;
        udp_data_length     <= 16'd2;  // 固定2字节
        send_data_cnt       <= 16'd0;
        mode_toggle         <= 1'b1;   // 初始值1，首次按下切换到0（SD卡模式）
    end
    else begin
        case(STATE)
            // ========== 状态 0：空闲，等待按键触发 ==========
            IDLE: begin
                app_tx_data_request <= 1'b0;
                app_tx_data_valid   <= 1'b0;
                send_data_cnt       <= 16'd0;

                if(key4_negedge) begin
                    // 切换模式
                    mode_toggle <= ~mode_toggle;
                    STATE       <= WAIT_UDP;
                end
            end

            // ========== 状态 1：等待UDP准备好 ==========
            WAIT_UDP: begin
                if(udp_tx_ready) begin
                    app_tx_data_request <= 1'b1;
                    STATE               <= WAIT_ACK;
                end
                else begin
                    app_tx_data_request <= 1'b0;
                end
            end

            // ========== 状态 2：等待应答 ==========
            WAIT_ACK: begin
                if(app_tx_ack) begin
                    app_tx_data_request <= 1'b0;
                    app_tx_data_valid   <= 1'b1;
                    send_data_cnt       <= 16'd1;

                    // 发送第一个字节（高字节 = 0x00）
                    if(mode_toggle)
                        app_tx_data <= MODE_CMD_CAM[7:0];  // 摄像头：先发0x00
                    else
                        app_tx_data <= MODE_CMD_SD[7:0];   // SD卡：先发0x00

                    STATE <= SEND_DATA;
                end
                else begin
                    app_tx_data_request <= 1'b1;
                end
            end

            // ========== 状态 3：发送命令数据 ==========
            SEND_DATA: begin
                if(send_data_cnt >= 16'd2) begin
                    // 发送完成
                    send_data_cnt     <= 16'd0;
                    app_tx_data_valid <= 1'b0;
                    STATE             <= DONE;
                end
                else begin
                    // 继续发送
                    send_data_cnt     <= send_data_cnt + 1'd1;
                    app_tx_data_valid <= 1'b1;

                    // 发送下一个字节
                    if(mode_toggle)
                        app_tx_data <= MODE_CMD_CAM[send_data_cnt*8 +: 8];
                    else
                        app_tx_data <= MODE_CMD_SD[send_data_cnt*8 +: 8];
                end
            end

            // ========== 状态 4：发送完成，回到空闲 ==========
            DONE: begin
                app_tx_data_valid <= 1'b0;
                STATE             <= IDLE;
            end

            default: STATE <= IDLE;
        endcase
    end
end

endmodule
