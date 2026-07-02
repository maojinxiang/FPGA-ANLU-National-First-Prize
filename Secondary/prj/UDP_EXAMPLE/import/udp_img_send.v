// ============================================================
// 模块名称: udp_img_send
// 功能描述: 子板图片UDP发送模块（照抄母板udp_cam_ctrl.v）
//           从SDRAM读取图片数据并通过UDP发送
// ============================================================
module udp_img_send(
    input               clk,
    input               rst_n,

    // ===== SDRAM 读取接口 =====
    output reg          read_req,
    input               read_req_ack,
    output reg          read_en,
    input [31:0]        read_data,

    // ===== UDP 发送接口 =====
    input               udp_tx_ready,
    input               app_tx_ack,
    output reg          app_tx_data_request,
    output reg          app_tx_data_valid,
    output reg [7:0]    app_tx_data,
    output reg [15:0]   udp_data_length,

    // ===== 控制接口 =====
    input               start_send       // 开始发送触发信号（key3）
);

// ============================================================================
// 参数定义
// ============================================================================

localparam  IMG_HEADER      = 32'hAA0055FF;
localparam  IMG_WIDTH       = 32'd640;
localparam  IMG_HEIGHT      = 32'd480;
localparam  IMG_TOTAL       = IMG_WIDTH * IMG_HEIGHT * 3;
localparam  IMG_FRAMSIZE    = 32'd636;
localparam  IMG_FRAMTOTAL   = 32'd1450;
localparam  IMG_HEADER_LEN  = 256;

// 测试模式开关（改为1启用测试图案，改为0使用SDRAM数据）
parameter   TEST_PATTERN    = 1'b1;

// ============================================================================
// 状态机定义
// ============================================================================

localparam  IDLE            = 3'd0;
localparam  START_UDP       = 3'd1;
localparam  WAIT_FIFO_RDY   = 3'd2;
localparam  WAIT_UDP_DATA   = 3'd3;
localparam  WAIT_ACK        = 3'd4;
localparam  SEND_UDP_HEADER = 3'd5;
localparam  SEND_UDP_DATA   = 3'd6;
localparam  DELAY           = 3'd7;

reg [2:0]   STATE;

// ============================================================================
// 寄存器定义
// ============================================================================

reg [31:0]  IMG_FRAMSEQ;
reg [31:0]  IMG_PICSEQ;
reg [31:0]  IMG_OFFSET;

reg [8:0]   app_tx_header_cnt;
reg [11:0]  fifo_read_data_cnt;
reg [21:0]  delay_cnt;

// 发送触发信号边沿检测
reg         start_send_d1;
reg         start_send_d2;
wire        start_send_posedge;

// ============================================================================
// UDP 包头
// ============================================================================

wire [255:0] UDP_HEADER_32 = {
    IMG_FRAMSIZE,
    IMG_FRAMSEQ,
    IMG_PICSEQ,
    IMG_OFFSET,
    IMG_TOTAL,
    IMG_HEIGHT,
    IMG_WIDTH,
    IMG_HEADER
};

// ============================================================================
// 像素数据处理
// ============================================================================

reg [31:0] read_data_buf;
reg [1:0]  byte_select_cnt;
reg        read_en_d1;
reg        read_en_d2;

// 测试图案生成（8条彩色竖条）
reg [7:0] test_r, test_g, test_b;
reg [31:0] test_pixel_cnt;  // 测试模式像素计数

always @(*) begin
    // 根据像素位置生成彩色条纹（8条，每条80像素宽）
    case(test_pixel_cnt % 640 / 80)
        3'd0: {test_r, test_g, test_b} = {8'hFF, 8'h00, 8'h00};  // 红
        3'd1: {test_r, test_g, test_b} = {8'h00, 8'hFF, 8'h00};  // 绿
        3'd2: {test_r, test_g, test_b} = {8'h00, 8'h00, 8'hFF};  // 蓝
        3'd3: {test_r, test_g, test_b} = {8'hFF, 8'hFF, 8'h00};  // 黄
        3'd4: {test_r, test_g, test_b} = {8'hFF, 8'h00, 8'hFF};  // 品红
        3'd5: {test_r, test_g, test_b} = {8'h00, 8'hFF, 8'hFF};  // 青
        3'd6: {test_r, test_g, test_b} = {8'hFF, 8'hFF, 8'hFF};  // 白
        3'd7: {test_r, test_g, test_b} = {8'h80, 8'h80, 8'h80};  // 灰
        default: {test_r, test_g, test_b} = {8'h00, 8'h00, 8'h00};
    endcase
end

// ============================================================================
// 发送触发边沿检测
// ============================================================================

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
// 主状态机
// ============================================================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        STATE               <= IDLE;
        app_tx_data_request <= 1'b0;
        app_tx_data_valid   <= 1'b0;
        app_tx_data         <= 8'd0;
        udp_data_length     <= 16'd668;
        IMG_FRAMSEQ         <= 32'd0;
        IMG_PICSEQ          <= 32'd0;
        IMG_OFFSET          <= 32'd0;
        app_tx_header_cnt   <= 9'd0;
        fifo_read_data_cnt  <= 12'd0;
        delay_cnt           <= 22'd0;
        read_req            <= 1'b0;
        read_en             <= 1'b0;
        read_en_d1          <= 1'b0;
        read_en_d2          <= 1'b0;
        byte_select_cnt     <= 2'd0;
        read_data_buf       <= 32'd0;
        test_pixel_cnt      <= 32'd0;
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

                // 修改：使用上升沿触发，单次发送（避免重复发送空数据）
                if(start_send_posedge) begin
                    STATE <= START_UDP;
                end
            end

            // ========== 状态 1：开始新帧 ==========
            START_UDP: begin
                app_tx_data_request <= 1'b0;
                app_tx_data_valid   <= 1'b0;
                fifo_read_data_cnt  <= 12'd0;
                IMG_FRAMSEQ         <= 32'd0;      // 修改：重置帧序号（与母板一致）
                IMG_OFFSET          <= 32'd0;      // 修改：重置偏移（与母板一致）
                read_req            <= 1'b0;
                read_en             <= 1'b0;
                IMG_PICSEQ          <= IMG_PICSEQ + 1'd1;
                delay_cnt           <= 22'd0;
                byte_select_cnt     <= 2'd0;
                read_en_d1          <= 1'b0;
                read_en_d2          <= 1'b0;
                test_pixel_cnt      <= 32'd0;     // 重置测试像素计数
                STATE               <= WAIT_FIFO_RDY;
            end

            // ========== 状态 2：等待 FIFO 准备好 ==========
            WAIT_FIFO_RDY: begin
                if(delay_cnt >= 2000) begin  // 与母板一致
                    delay_cnt <= 22'd0;
                    STATE     <= WAIT_UDP_DATA;
                end
                else begin
                    delay_cnt <= delay_cnt + 1'd1;
                    STATE     <= WAIT_FIFO_RDY;
                end

                if(delay_cnt == 10)  // 与母板一致
                    read_req <= 1'b1;
                else if(read_req_ack)
                    read_req <= 1'b0;
            end

            // ========== 状态 3：等待 UDP 准备好 ==========
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

            // ========== 状态 4：等待 UDP 应答 ==========
            WAIT_ACK: begin
                if(app_tx_ack) begin
                    app_tx_data_request <= 1'b0;
                    app_tx_header_cnt   <= 9'd8;
                    app_tx_data_valid   <= 1'b1;
                    app_tx_data         <= UDP_HEADER_32[7:0];
                    STATE               <= SEND_UDP_HEADER;
                end
                else begin
                    app_tx_data_request <= 1'b1;
                    STATE               <= WAIT_ACK;
                end
            end

            // ========== 状态 5：发送 UDP 包头 ==========
            SEND_UDP_HEADER: begin
                // 提前3个周期开始读取
                if(app_tx_header_cnt == 9'd232) begin
                    read_en <= 1'b1;
                end
                else if(app_tx_header_cnt == 9'd240) begin
                    read_en <= 1'b0;
                    read_en_d1 <= 1'b1;
                end
                else if(app_tx_header_cnt == 9'd248) begin
                    read_en_d1 <= 1'b0;
                    read_en_d2 <= 1'b1;
                end

                if(app_tx_header_cnt >= IMG_HEADER_LEN) begin
                    STATE              <= SEND_UDP_DATA;
                    app_tx_data_valid  <= 1'b1;
                    app_tx_data        <= UDP_HEADER_32[app_tx_header_cnt +: 8];
                    app_tx_header_cnt  <= 9'd0;
                    fifo_read_data_cnt <= 12'd0;
                    byte_select_cnt    <= 2'd0;
                end
                else begin
                    STATE             <= SEND_UDP_HEADER;
                    app_tx_data_valid <= 1'b1;
                    app_tx_data       <= UDP_HEADER_32[app_tx_header_cnt +: 8];
                    app_tx_header_cnt <= app_tx_header_cnt + 8;
                end
            end

            // ========== 状态 6：发送图像数据 (3字节/像素) ==========
            SEND_UDP_DATA: begin
                // read_en 延迟打拍（非测试模式需要）
                if(!TEST_PATTERN) begin
                    read_en_d2 <= read_en_d1;
                    read_en_d1 <= read_en;

                    if(read_en_d2) begin
                        read_data_buf <= read_data;
                    end

                    // 读使能控制
                    if(byte_select_cnt == 2'd2) begin
                        read_en <= 1'b1;
                    end
                    else begin
                        read_en <= 1'b0;
                    end
                end

                // 数据输出（根据TEST_PATTERN选择数据源）
                if(TEST_PATTERN) begin
                    // 测试模式：发送彩色条纹
                    case(byte_select_cnt)
                        2'd0: app_tx_data <= test_r;
                        2'd1: app_tx_data <= test_g;
                        2'd2: app_tx_data <= test_b;
                        default: app_tx_data <= 8'h00;
                    endcase
                end
                else begin
                    // 正常模式：从SDRAM读取
                    case(byte_select_cnt)
                        2'd0: app_tx_data <= read_data_buf[31:24];  // R
                        2'd1: app_tx_data <= read_data_buf[23:16];  // G
                        2'd2: app_tx_data <= read_data_buf[15:8];   // B
                        default: app_tx_data <= 8'h00;
                    endcase
                end

                // 包发送控制
                if(fifo_read_data_cnt >= (IMG_FRAMSIZE - 1)) begin
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

                    // 字节选择计数器递增
                    if(byte_select_cnt >= 2'd2) begin
                        byte_select_cnt <= 2'd0;
                        // 测试模式：每3个字节（1个像素）递增像素计数
                        if(TEST_PATTERN)
                            test_pixel_cnt <= test_pixel_cnt + 1'd1;
                    end
                    else begin
                        byte_select_cnt <= byte_select_cnt + 1;
                    end
                end
            end

            // ========== 状态 7：延迟 ==========
            DELAY: begin
                if(delay_cnt >= 1500) begin  // 与母板一致
                    delay_cnt  <= 22'd0;
                    IMG_FRAMSEQ <= IMG_FRAMSEQ + 1'd1;
                    IMG_OFFSET  <= IMG_OFFSET + IMG_FRAMSIZE;

                    if(IMG_FRAMSEQ >= (IMG_FRAMTOTAL - 1)) begin
                        // 修改：发送完一帧后回到IDLE，等待下次key3触发
                        STATE <= IDLE;  // 单次发送完成
                    end
                    else begin
                        STATE <= WAIT_UDP_DATA;
                    end
                end
                else begin
                    delay_cnt <= delay_cnt + 1'd1;
                    STATE     <= DELAY;
                end
            end

            default: STATE <= IDLE;
        endcase
    end
end

endmodule
