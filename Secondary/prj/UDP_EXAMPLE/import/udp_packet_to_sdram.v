`timescale 1ns / 1ps

//********************************************************************************
// Module : udp_packet_to_sdram
// Function: 接收母板发送的分包UDP数据，解析包头后写入SDRAM
//           兼容母板udp_cam_ctrl.v的协议格式
//********************************************************************************
module udp_packet_to_sdram
#(
    parameter PIXEL_COUNT = 307200 // 640*480像素总数
)
(
    // System Inputs
    input                   clk,            // 连接udp_clk
    input                   reset,          // 高电平有效复位

    // UDP Data Input
    input                   udp_data_valid,
    input      [7:0]        udp_data,
    input      [15:0]       udp_data_length, // UDP包长度

    // Interface to frame_read_write
    output reg              write_req,      // 写事务请求
    input                   write_req_ack,  // 写请求响应
    output reg              write_en,       // 单个字写使能
    output reg [31:0]       write_data      // 32位写入数据（[23:0]为RGB，[31:24]补0）
);

    // ============================================================================
    // 协议参数定义（与母板udp_cam_ctrl.v一致）
    // ============================================================================
    localparam IMG_HEADER      = 32'hFF5500AA;  // 包头标识（小端序：0xAA0055FF接收后变为0xFF5500AA）
    localparam IMG_HEADER_LEN  = 32;            // 包头长度32字节（8个32位字）
    localparam IMG_DATA_LEN    = 636;           // 每包数据长度636字节
    localparam TOTAL_PACKET_LEN = 668;          // 总包长 = 32 + 636

    // ============================================================================
    // 状态机定义
    // ============================================================================
    localparam S_IDLE        = 2'd0; // 等待新UDP包
    localparam S_SKIP_HEADER = 2'd1; // 跳过包头（32字节）
    localparam S_WAIT_ACK    = 2'd2; // 等待SDRAM写响应（仅第一个包）
    localparam S_RECV_DATA   = 2'd3; // 接收数据（636字节）

    reg [1:0] state;
    reg       frame_started;   // 标记帧是否已启动写入
    reg [5:0] skip_cnt;        // 跳过包头计数（0~31）

    // ============================================================================
    // 包头解析寄存器（按母板格式：从高位到低位）
    // ============================================================================
    reg [31:0] header_magic;    // 包头标识 0xAA0055FF
    reg [31:0] img_width;       // 图像宽度 640
    reg [31:0] img_height;      // 图像高度 480
    reg [31:0] img_total;       // 总字节数 640*480*3
    reg [31:0] img_offset;      // 当前包数据偏移量（字节）
    reg [31:0] img_picseq;      // 图片序号
    reg [31:0] img_framseq;     // 帧序号（0~1449）
    reg [31:0] img_framsize;    // 帧大小 636

    // ============================================================================
    // 内部计数器
    // ============================================================================
    reg [5:0]  header_byte_cnt;  // 包头字节计数（0~31）
    reg [9:0]  data_byte_cnt;    // 数据字节计数（0~635）
    reg [1:0]  rgb_byte_cnt;     // RGB字节计数（0:R, 1:G, 2:B）
    reg [18:0] total_pixel_cnt;  // 总像素计数（0~307199）
    reg [15:0] timeout_cnt;      // 包内超时计数器（避免状态机卡死）
    reg [23:0] frame_timeout_cnt; // 帧间超时计数器（长时间无UDP包则复位）

    // ============================================================================
    // UDP信号寄存（参考母板实现，不使用多级同步避免字节错位）
    // ============================================================================
    reg udp_data_valid_d1;
    reg [7:0] udp_data_d1;
    reg [15:0] udp_data_length_d1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            udp_data_valid_d1 <= 1'b0;
            udp_data_d1 <= 8'h00;
            udp_data_length_d1 <= 16'd0;
        end else begin
            udp_data_valid_d1 <= udp_data_valid;
            udp_data_d1 <= udp_data;
            if (udp_data_valid && udp_data_length > 0)
                udp_data_length_d1 <= udp_data_length;
        end
    end

    wire udp_packet_end = udp_data_valid_d1 && !udp_data_valid;  // UDP包结束边沿

    // ============================================================================
    // 包头字段临时缓存（用于逐字节拼接32位字段）
    // ============================================================================
    reg [31:0] header_field_buf;
    reg [1:0]  header_field_byte_cnt; // 当前字段内的字节计数（0~3）

    // ============================================================================
    // 主状态机
    // ============================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            write_req <= 1'b0;
            write_en <= 1'b0;
            skip_cnt <= 6'd0;
            data_byte_cnt <= 10'd0;
            rgb_byte_cnt <= 2'd0;
            write_data <= 32'h00000000;
            total_pixel_cnt <= 19'd0;
            frame_started <= 1'b0;
            timeout_cnt <= 16'd0;
            frame_timeout_cnt <= 24'd0;
        end else begin
            // 默认关闭写使能
            write_en <= 1'b0;

            // 包内超时检测（避免状态机卡死）
            if (state != S_IDLE) begin
                timeout_cnt <= timeout_cnt + 1'd1;
                frame_timeout_cnt <= 24'd0;  // 接收数据时清零帧间超时
                // 超时阈值：约0.16ms @ 125MHz = 20000周期
                if (timeout_cnt > 16'd20000) begin
                    // 包内超时，强制返回IDLE并复位RGB计数器
                    state <= S_IDLE;
                    write_req <= 1'b0;
                    rgb_byte_cnt <= 2'd0;  // 复位RGB计数器，避免下次错位
                    timeout_cnt <= 16'd0;
                end
            end else begin
                timeout_cnt <= 16'd0;
                // 帧间超时检测：IDLE状态下长时间无UDP包，复位帧标志
                if (frame_started) begin
                    frame_timeout_cnt <= frame_timeout_cnt + 1'd1;
                    // 约100ms @ 125MHz = 12500000周期
                    if (frame_timeout_cnt > 24'd12500000) begin
                        frame_started <= 1'b0;  // 复位帧标志
                        rgb_byte_cnt <= 2'd0;   // 复位RGB计数器，避免下次错位
                        frame_timeout_cnt <= 24'd0;
                    end
                end else begin
                    frame_timeout_cnt <= 24'd0;
                end
            end

            case (state)
                // ========================================
                // 状态0：空闲，等待新UDP包
                // ========================================
                S_IDLE: begin
                    if (udp_data_valid && udp_data_length_d1 == TOTAL_PACKET_LEN) begin
                        // 检测到UDP图像包（严格匹配668字节），开始跳过包头
                        state <= S_SKIP_HEADER;
                        skip_cnt <= 6'd0;
                        rgb_byte_cnt <= 2'd0;  // 立即复位RGB计数器，确保对齐
                    end
                end

                // ========================================
                // 状态1：跳过包头（32字节）
                // 字节计数：IDLE时第0字节，SKIP_HEADER时skip_cnt==0为第1字节
                // ========================================
                S_SKIP_HEADER: begin
                    if (udp_data_valid) begin
                        skip_cnt <= skip_cnt + 1'd1;

                        // 跳过完32字节包头（skip_cnt==30表示第31字节，下一拍进入数据接收）
                        if (skip_cnt == 6'd30) begin
                            data_byte_cnt <= 10'd0;
                            rgb_byte_cnt <= 2'd0;

                            // 检查是否需要发起write_req
                            if (!frame_started) begin
                                // 第一个包：发起write_req并标记开始
                                write_req <= 1'b1;
                                frame_started <= 1'b1;
                                total_pixel_cnt <= 19'd0;
                            end
                            state <= S_RECV_DATA;
                        end
                    end
                end

                // ========================================
                // 状态2：等待SDRAM写响应（现在不使用此状态）
                // ========================================
                S_WAIT_ACK: begin
                    // 不再使用此状态，直接进入S_RECV_DATA
                    state <= S_RECV_DATA;
                end

                // ========================================
                // 状态3：接收数据（636字节）
                // ========================================
                S_RECV_DATA: begin
                    // 收到write_req_ack后撤销write_req
                    if (write_req_ack && write_req) begin
                        write_req <= 1'b0;
                    end

                    if (udp_data_valid) begin
                        // 按RGB顺序拼接32位数据（与母板格式一致：{R,G,B,0}）
                        case (rgb_byte_cnt)
                            2'd0: begin // R分量
                                write_data[31:24] <= udp_data;
                                rgb_byte_cnt <= 2'd1;
                            end
                            2'd1: begin // G分量
                                write_data[23:16] <= udp_data;
                                rgb_byte_cnt <= 2'd2;
                            end
                            2'd2: begin // B分量
                                write_data[15:8] <= udp_data;
                                write_data[7:0] <= 8'h00; // 低位补0
                                write_en <= 1'b1; // 触发写入
                                rgb_byte_cnt <= 2'd0;
                                total_pixel_cnt <= total_pixel_cnt + 1'd1;
                            end
                        endcase

                        data_byte_cnt <= data_byte_cnt + 1'd1;

                        // 接收完636字节数据（当前包结束）
                        if (data_byte_cnt == IMG_DATA_LEN - 1) begin
                            // 检查是否已接收完整帧
                            if (total_pixel_cnt >= (PIXEL_COUNT - 1)) begin
                                // 整帧接收完成，复位状态
                                state <= S_IDLE;
                                frame_started <= 1'b0;
                                rgb_byte_cnt <= 2'd0;  // 复位RGB计数器
                            end else begin
                                // 等待下一个包
                                state <= S_IDLE;
                            end
                        end
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
