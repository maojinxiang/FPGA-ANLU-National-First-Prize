// ============================================================
// 模块名称: udp_tx_simple
// 功能描述: 简化版UDP主动发送模块（照抄udp_cam_ctrl的状态机结构）
//           按键控制：按下key2切换模式并发送对应数据
// ============================================================
module udp_tx_simple(
    input               clk,
    input               rst_n,
    input               key2,       // 按键输入（低电平有效）

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
localparam  IDLE            = 4'd0;  // 等待按键触发
localparam  SEND_MODE_CMD   = 4'd1;  // 发送0x0002模式切换命令
localparam  WAIT_MODE_ACK   = 4'd2;  // 等待模式切换命令应答
localparam  SEND_MODE_DATA  = 4'd3;  // 发送模式命令数据
localparam  MODE_DELAY      = 4'd4;  // 模式切换延迟
localparam  WAIT_UDP_DATA   = 4'd5;  // 等待UDP准备好
localparam  WAIT_ACK        = 4'd6;  // 等待UDP应答
localparam  SEND_UDP_DATA   = 4'd7;  // 发送LED数据
localparam  DONE            = 4'd8;  // 完成

reg [3:0]   STATE;

// ============================================================================
// 固定测试数据
// ============================================================================
// 模式切换命令：0x0002（大端序，2字节）
// 注意：从[7:0]开始发送，所以低8位是第一个字节
wire [15:0] MODE_CMD = 16'h0200;  // 发送顺序: 0x00, 0x02

// LED模式：3字节打包成24位（注意：从[7:0]开始发送，所以第一个字节放在低8位）
wire [23:0] LED_DATA = {8'hF0, 8'h0F, 8'hAF};  // 发送顺序: AF, 0F, F0

// 数码管模式：5字节打包成40位（同样，第一个字节放在低8位）
wire [39:0] SEG_DATA = {8'h21, 8'h43, 8'h65, 8'h87, 8'h00};  // 发送顺序: 00, 87, 65, 43, 21

// ============================================================================
// 按键检测（去抖动和边缘检测）
// ============================================================================
reg [19:0]  key2_cnt;       // 按键去抖计数器 (125MHz, 20位支持约8ms)
reg         key2_stable;    // 稳定后的按键值
reg         key2_stable_d1; // 延迟1拍
wire        key2_negedge;   // 按键按下沿（下降沿）

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key2_cnt <= 20'd0;
        key2_stable <= 1'b1;
    end
    else begin
        if(key2 == key2_stable) begin
            key2_cnt <= 20'd0;
        end
        else begin
            key2_cnt <= key2_cnt + 1'd1;
            if(key2_cnt >= 20'd1000000) begin  // 8ms去抖
                key2_stable <= key2;
                key2_cnt <= 20'd0;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        key2_stable_d1 <= 1'b1;
    else
        key2_stable_d1 <= key2_stable;
end

assign key2_negedge = key2_stable_d1 && !key2_stable;  // 按下沿

// ============================================================================
// 寄存器定义
// ============================================================================
reg [15:0]  send_data_cnt;
reg [15:0]  delay_cnt;      // 延迟计数器
reg         mode_sel;       // 0=LED, 1=数码管
reg         sending_mode_cmd; // 标志：当前正在发送模式切换命令

// ============================================================================
// 主状态机（按键控制 + 模式切换命令）
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        STATE               <= IDLE;
        app_tx_data_request <= 1'b0;
        app_tx_data_valid   <= 1'b0;
        app_tx_data         <= 8'd0;
        udp_data_length     <= 16'd2;  // 初始发送模式命令2字节
        send_data_cnt       <= 16'd0;
        delay_cnt           <= 16'd0;
        mode_sel            <= 1'b0;   // 默认LED模式
        sending_mode_cmd    <= 1'b0;
    end
    else begin
        case(STATE)
            // ========== 状态 0：空闲，等待按键触发 ==========
            IDLE: begin
                app_tx_data_request <= 1'b0;
                app_tx_data_valid   <= 1'b0;
                send_data_cnt       <= 16'd0;
                delay_cnt           <= 16'd0;

                if(key2_negedge) begin
                    sending_mode_cmd <= 1'b1;  // 标记：开始发送模式命令
                    udp_data_length  <= 16'd2; // 模式命令2字节
                    STATE            <= SEND_MODE_CMD;
                end
                else begin
                    STATE <= IDLE;
                end
            end

            // ========== 状态 1：发送模式切换命令（0x0002） ==========
            SEND_MODE_CMD: begin
                if(udp_tx_ready) begin
                    app_tx_data_request <= 1'b1;
                    STATE               <= WAIT_MODE_ACK;
                end
                else begin
                    app_tx_data_request <= 1'b0;
                    STATE               <= SEND_MODE_CMD;
                end
            end

            // ========== 状态 2：等待模式命令应答 ==========
            WAIT_MODE_ACK: begin
                if(app_tx_ack) begin
                    app_tx_data_request <= 1'b0;
                    app_tx_data_valid   <= 1'b1;
                    send_data_cnt       <= 16'd1;

                    // 发送模式命令第一个字节（0x00）
                    app_tx_data <= MODE_CMD[7:0];  // 大端序：先发0x00
                    STATE       <= SEND_MODE_DATA;
                end
                else begin
                    app_tx_data_request <= 1'b1;
                    STATE               <= WAIT_MODE_ACK;
                end
            end

            // ========== 状态 3：发送模式命令数据 ==========
            SEND_MODE_DATA: begin
                if(send_data_cnt >= 16'd2) begin
                    // 模式命令发送完成
                    send_data_cnt     <= 16'd0;
                    app_tx_data_valid <= 1'b0;
                    sending_mode_cmd  <= 1'b0;  // 清除标志
                    STATE             <= MODE_DELAY;
                end
                else begin
                    // 继续发送模式命令
                    send_data_cnt     <= send_data_cnt + 1'd1;
                    app_tx_data_valid <= 1'b1;
                    app_tx_data       <= MODE_CMD[send_data_cnt*8 +: 8];
                    STATE             <= SEND_MODE_DATA;
                end
            end

            // ========== 状态 4：模式切换延迟 ==========
            MODE_DELAY: begin
                if(delay_cnt >= 16'd10000) begin  // 延迟10000周期（约80us）
                    delay_cnt <= 16'd0;

                    // 设置LED/数码管数据长度
                    if(mode_sel == 1'b0)
                        udp_data_length <= 16'd3;  // LED模式3字节
                    else
                        udp_data_length <= 16'd5;  // 数码管模式5字节

                    STATE <= WAIT_UDP_DATA;
                end
                else begin
                    delay_cnt <= delay_cnt + 1'd1;
                    STATE     <= MODE_DELAY;
                end
            end

            // ========== 状态 5：等待UDP准备好发送LED/数码管数据 ==========
            WAIT_UDP_DATA: begin
                if(udp_tx_ready) begin
                    app_tx_data_request <= 1'b1;
                    STATE               <= WAIT_ACK;
                end
                else begin
                    app_tx_data_request <= 1'b0;
                    STATE               <= WAIT_UDP_DATA;
                end
            end

            // ========== 状态 6：等待LED/数码管数据应答 ==========
            WAIT_ACK: begin
                if(app_tx_ack) begin
                    app_tx_data_request <= 1'b0;
                    app_tx_data_valid   <= 1'b1;
                    send_data_cnt       <= 16'd1;

                    // 发送第一个字节
                    if(mode_sel == 1'b0)
                        app_tx_data <= LED_DATA[7:0];
                    else
                        app_tx_data <= SEG_DATA[7:0];

                    STATE <= SEND_UDP_DATA;
                end
                else begin
                    app_tx_data_request <= 1'b1;
                    STATE               <= WAIT_ACK;
                end
            end

            // ========== 状态 7：发送LED/数码管数据 ==========
            SEND_UDP_DATA: begin
                if(send_data_cnt >= udp_data_length) begin
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
                    if(mode_sel == 1'b0)
                        app_tx_data <= LED_DATA[send_data_cnt*8 +: 8];
                    else
                        app_tx_data <= SEG_DATA[send_data_cnt*8 +: 8];

                    STATE <= SEND_UDP_DATA;
                end
            end

            // ========== 状态 8：发送完成，切换模式，回到空闲 ==========
            DONE: begin
                app_tx_data_valid <= 1'b0;
                mode_sel          <= ~mode_sel;  // 切换LED/数码管模式
                STATE             <= IDLE;
            end

            default: STATE <= IDLE;
        endcase
    end
end

endmodule
