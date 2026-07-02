// ============================================================
// 模块名称: udp_simple_send
// 功能描述: 完全参考母板udp_cam_ctrl.v，发送纯RGB字节流（无包头）
// 版本: v3.0 - 完全照抄母板时序逻辑
// ============================================================
module udp_simple_send(
    input               clk,
    input               rst_n,

    // ===== SDRAM 读取接口（与母板一致）=====
    output reg          read_req,
    input               read_req_ack,
    output reg          read_en,
    input [31:0]        read_data,

    // ===== UDP 发送接口（与母板一致）=====
    input               udp_tx_ready,
    input               app_tx_ack,
    output reg          app_tx_data_request,
    output reg          app_tx_data_valid,
    output reg [7:0]    app_tx_data,
    output reg [15:0]   udp_data_length,

    // ===== 控制接口 =====
    input               start_send
);

// ============================================================================
// 参数定义（照抄母板）
// ============================================================================
localparam  IMG_FRAMSIZE    = 32'd636;
localparam  IMG_FRAMTOTAL   = 32'd1450;

// ============================================================================
// 状态机定义（照抄母板）
// ============================================================================
localparam  IDLE            = 3'd0;
localparam  START_UDP       = 3'd1;
localparam  WAIT_FIFO_RDY   = 3'd2;
localparam  WAIT_UDP_DATA   = 3'd3;
localparam  WAIT_ACK        = 3'd4;
localparam  SEND_UDP_DATA   = 3'd5;
localparam  DELAY           = 3'd6;
localparam  DONE            = 3'd7;

reg [2:0]   STATE;

// ============================================================================
// 寄存器定义（照抄母板）
// ============================================================================
reg [31:0]  IMG_FRAMSEQ;
reg [31:0]  IMG_PICSEQ;
reg [31:0]  IMG_OFFSET;

reg [11:0]  fifo_read_data_cnt;
reg [21:0]  delay_cnt;

// 像素数据处理（照抄母板）
reg [31:0] read_data_buf;
reg [1:0]  byte_select_cnt;
reg        read_en_d1;
reg        read_en_d2;

// 触发信号边沿检测
reg         start_send_d1;
reg         start_send_d2;
wire        start_send_posedge;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_send_d1 <= 1'b0;
        start_send_d2 <= 1'b0;
    end
    else begin
        start_send_d1 <= start_send;
        start_send_d2 <= start_send_d1;
    end
end

assign start_send_posedge = start_send_d1 && !start_send_d2;

// ============================================================================
// 主状态机（完全照抄母板udp_cam_ctrl.v）
// ============================================================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        STATE               <= IDLE;
        app_tx_data_request <= 1'b0;
        app_tx_data_valid   <= 1'b0;
        app_tx_data         <= 8'd0;
        udp_data_length     <= 16'd636;
        IMG_FRAMSEQ         <= 32'd0;
        IMG_PICSEQ          <= 32'd0;
        IMG_OFFSET          <= 32'd0;
        fifo_read_data_cnt  <= 12'd0;
        delay_cnt           <= 22'd0;
        read_req            <= 1'b0;
        read_en             <= 1'b0;
        read_en_d1          <= 1'b0;
        read_en_d2          <= 1'b0;
        byte_select_cnt     <= 2'd0;
        read_data_buf       <= 32'd0;
    end
    else begin
        case(STATE)
            // ========== 状态 0：空闲，等待触发 ==========
            IDLE: begin
                app_tx_data_request <= 1'b0;
                app_tx_data_valid   <= 1'b0;
                fifo_read_data_cnt  <= 12'd0;
                IMG_FRAMSEQ         <= 32'd0;
                IMG_OFFSET          <= 32'd0;
                read_req            <= 1'b0;
                read_en             <= 1'b0;
                delay_cnt           <= 22'd0;
                byte_select_cnt     <= 2'd0;
                read_en_d1          <= 1'b0;
                read_en_d2          <= 1'b0;

                if(start_send_posedge) begin
                    STATE <= START_UDP;
                end
            end

            // ========== 状态 1：开始新帧（照抄母板 START_UDP）==========
            START_UDP: begin
                app_tx_data_request <= 1'b0;
                app_tx_data_valid   <= 1'b0;
                fifo_read_data_cnt  <= 12'd0;
                IMG_FRAMSEQ         <= 32'd0;
                IMG_OFFSET          <= 32'd0;
                read_req            <= 1'b0;
                read_en             <= 1'b0;
                IMG_PICSEQ          <= IMG_PICSEQ + 1'd1;
                delay_cnt           <= 22'd0;
                byte_select_cnt     <= 2'd0;
                read_en_d1          <= 1'b0;
                read_en_d2          <= 1'b0;
                STATE               <= WAIT_FIFO_RDY;
            end

            // ========== 状态 2：等待 FIFO 准备好（照抄母板 WAIT_FIFO_RDY）==========
            WAIT_FIFO_RDY: begin
                if(delay_cnt >= 2000) begin
                    delay_cnt <= 22'd0;
                    STATE     <= WAIT_UDP_DATA;
                end
                else begin
                    delay_cnt <= delay_cnt + 1'd1;
                    STATE     <= WAIT_FIFO_RDY;
                end

                if(delay_cnt == 10)
                    read_req <= 1'b1;
                else if(read_req_ack)
                    read_req <= 1'b0;
            end

            // ========== 状态 3：等待 UDP 准备好（照抄母板 WAIT_UDP_DATA）==========
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

            // ========== 状态 4：等待 UDP 应答（照抄母板 WAIT_ACK）==========
            WAIT_ACK: begin
                if(app_tx_ack) begin
                    app_tx_data_request <= 1'b0;
                    fifo_read_data_cnt  <= 12'd0;
                    byte_select_cnt     <= 2'd0;
                    // 关键：直接进入SEND_UDP_DATA，但fifo_read_data_cnt=0会触发预热
                    STATE               <= SEND_UDP_DATA;
                end
                else begin
                    app_tx_data_request <= 1'b1;
                    STATE               <= WAIT_ACK;
                end
            end

            // ========== 状态 5：发送图像数据（照抄母板 SEND_UDP_DATA，但添加预热）==========
            SEND_UDP_DATA: begin
                // ===== 预热阶段（前3个周期，模拟母板SEND_UDP_HEADER的232-256）=====
                if(fifo_read_data_cnt == 12'd0) begin
                    // Cycle 0: 启动read_en（对应母板header_cnt==232）
                    read_en            <= 1'b1;
                    app_tx_data_valid  <= 1'b0;
                    fifo_read_data_cnt <= fifo_read_data_cnt + 1'd1;
                end
                else if(fifo_read_data_cnt == 12'd1) begin
                    // Cycle 1: read_en传播到read_en_d1（对应母板header_cnt==240）
                    read_en            <= 1'b0;
                    read_en_d1         <= 1'b1;
                    app_tx_data_valid  <= 1'b0;
                    fifo_read_data_cnt <= fifo_read_data_cnt + 1'd1;
                end
                else if(fifo_read_data_cnt == 12'd2) begin
                    // Cycle 2: read_en_d1传播到read_en_d2（对应母板header_cnt==248）
                    read_en_d1         <= 1'b0;
                    read_en_d2         <= 1'b1;
                    app_tx_data_valid  <= 1'b0;
                    fifo_read_data_cnt <= fifo_read_data_cnt + 1'd1;
                end
                // ===== 正常发送阶段（从Cycle 3开始，完全照抄母板）=====
                else begin
                    // read_en 延迟打拍（照抄母板）
                    read_en_d2 <= read_en_d1;
                    read_en_d1 <= read_en;

                    if(read_en_d2) begin
                        read_data_buf <= read_data;
                    end

                    // 读使能控制（照抄母板）
                    if(byte_select_cnt == 2'd2) begin
                        read_en <= 1'b1;
                    end
                    else begin
                        read_en <= 1'b0;
                    end

                    // 数据输出（照抄母板，适配{R,G,B,0}格式）
                    case(byte_select_cnt)
                        2'd0: app_tx_data <= read_data_buf[31:24];  // R
                        2'd1: app_tx_data <= read_data_buf[23:16];  // G
                        2'd2: app_tx_data <= read_data_buf[15:8];   // B
                        default: app_tx_data <= 8'h00;
                    endcase

                    // 包发送控制（照抄母板，但+3补偿预热周期）
                    if(fifo_read_data_cnt >= (IMG_FRAMSIZE + 3 - 1)) begin
                        fifo_read_data_cnt <= 12'd0;
                        app_tx_data_valid  <= 1'b0;
                        read_en            <= 1'b0;
                        read_en_d1         <= 1'b0;
                        read_en_d2         <= 1'b0;
                        byte_select_cnt    <= 2'd0;
                        STATE              <= DELAY;
                    end
                    else begin
                        fifo_read_data_cnt <= fifo_read_data_cnt + 1'd1;
                        app_tx_data_valid  <= 1'b1;
                        STATE              <= SEND_UDP_DATA;

                        if(byte_select_cnt >= 2'd2)
                            byte_select_cnt <= 2'd0;
                        else
                            byte_select_cnt <= byte_select_cnt + 1;
                    end
                end
            end

            // ========== 状态 6：延迟（照抄母板 DELAY）==========
            DELAY: begin
                if(delay_cnt >= 1500) begin
                    delay_cnt  <= 22'd0;
                    IMG_FRAMSEQ <= IMG_FRAMSEQ + 1'd1;
                    IMG_OFFSET  <= IMG_OFFSET + IMG_FRAMSIZE;

                    if(IMG_FRAMSEQ >= (IMG_FRAMTOTAL - 1))
                        STATE <= DONE;
                    else
                        STATE <= WAIT_UDP_DATA;
                end
                else begin
                    delay_cnt <= delay_cnt + 1'd1;
                    STATE     <= DELAY;
                end
            end

            // ========== 状态 7：发送完成 ==========
            DONE: begin
                if(!start_send) begin
                    STATE <= IDLE;
                end
            end

            default: STATE <= IDLE;
        endcase
    end
end

endmodule
