`timescale 1ns / 1ps

//********************************************************************************
// Module : udp_to_sdram_writer
// Function: 接收UDP字节流，合成32位RGB数据并写入SDRAM（去除Sdr_init_done依赖）
//********************************************************************************
module udp_to_sdram_writer
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

    // Interface to frame_read_write
    output reg              write_req,      // 写事务请求
    input                   write_req_ack,  // 写请求响应
    output reg              write_en,       // 单个字写使能
    output reg [31:0]       write_data      // 32位写入数据（[23:0]为RGB，[31:24]补0）
);

    // 状态机定义（保留原有三状态，逻辑简洁）
    localparam S_IDLE        = 2'd0; // 等待新帧数据
    localparam S_WAIT_ACK    = 2'd1; // 等待SDRAM写响应
    localparam S_RECEIVING   = 2'd2; // 接收并拼接数据

    // 内部寄存器
    reg [1:0] state;                // 状态机寄存器
    reg [1:0] byte_cnt;             // 字节计数器（0:R,1:G,2:B）
    reg [18:0] pixel_cnt;           // 像素计数器（0~307199）
    reg [7:0] first_byte_cache;     // 首字节缓存（解决S_WAIT_ACK延迟错位）
    reg first_byte_cached;          // 首字节缓存完成标记
    // UDP信号同步（消除亚稳态，保留原有逻辑）
    reg [1:0] udp_data_valid_sync;  // 2级同步寄存器（valid信号）
    reg [7:0] udp_data_sync_1;      // 数据同步寄存器1
    reg [7:0] udp_data_sync_2;      // 数据同步寄存器2（最终稳定数据）

    // 1. UDP信号跨时钟域同步（不变，确保信号稳定）
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            udp_data_valid_sync <= 2'b00;
            udp_data_sync_1 <= 8'h00;
            udp_data_sync_2 <= 8'h00;
        end else begin
            // valid信号2级同步，消除亚稳态
            udp_data_valid_sync <= {udp_data_valid_sync[0], udp_data_valid};
            // 数据延迟2拍，与valid信号对齐（确保数据与valid同步）
            udp_data_sync_1 <= udp_data;
            udp_data_sync_2 <= udp_data_sync_1;
        end
    end
    // 同步后的稳定信号（后续逻辑仅用这两个信号）
    wire udp_data_valid_stable = udp_data_valid_sync[1];
    wire [7:0] udp_data_stable = udp_data_sync_2;

    // 2. 主状态机与数据处理逻辑（核心：首字节缓存+无错位拼接）
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 复位时初始化所有寄存器
            state <= S_IDLE;
            write_req <= 1'b0;
            write_en <= 1'b0;
            byte_cnt <= 2'd0;
            pixel_cnt <= 19'd0;
            write_data <= 32'h00000000;
            first_byte_cache <= 8'h00;
            first_byte_cached <= 1'b0;
        end else begin
            // 默认关闭写使能（避免误触发）
            write_en <= 1'b0;
            // 默认清除缓存标记（避免多周期误触发）
            first_byte_cached <= 1'b0;

            case (state)
                // 状态1：空闲，等待UDP首帧数据
                S_IDLE: begin
                    if (udp_data_valid_stable) begin
                        // 检测到有效数据，发起SDRAM写请求
                        write_req <= 1'b1;
                        // 跳转到等待响应状态
                        state <= S_WAIT_ACK;
                        // 复位计数器（确保新帧从0开始）
                        byte_cnt <= 2'd0;
                        pixel_cnt <= 19'd0;
                        // 关键：缓存首字节（R分量），避免S_WAIT_ACK延迟导致丢失
                        first_byte_cache <= udp_data_stable;
                        first_byte_cached <= 1'b1;
                    end
                end

                // 状态2：等待SDRAM写请求响应（可能有延迟）
                S_WAIT_ACK: begin
                    if (write_req_ack) begin
                        // 收到SDRAM响应，撤销写请求
                        write_req <= 1'b0;
                        // 跳转到数据接收状态
                        state <= S_RECEIVING;
                        // 若首字节已缓存，直接用缓存填充R通道（消除错位）
                        if (first_byte_cached) begin
                            write_data[23:16] <= first_byte_cache; // R分量写入
                            byte_cnt <= 2'd1; // 下一个字节处理G分量，无缝衔接
                        end
                    end
                    // 额外兼容：若响应延迟期间首字节变化（极端场景），更新缓存
                    else if (udp_data_valid_stable) begin
                        first_byte_cache <= udp_data_stable;
                        first_byte_cached <= 1'b1;
                    end
                end

                // 状态3：接收并拼接RGB数据（核心数据处理）
                S_RECEIVING: begin
                    if (udp_data_valid_stable) begin
                        case (byte_cnt)
                            // 处理G分量（第二个字节）
                            2'd1: begin
                                write_data[15:8] <= udp_data_stable; // G分量写入
                                byte_cnt <= 2'd2; // 下一个字节处理B分量
                            end
                            // 处理B分量（第三个字节，凑齐1个像素）
                            2'd2: begin
                                write_data[7:0] <= udp_data_stable;  // B分量写入
                                write_data[31:24] <= 8'h00;         // 高位补0（无Alpha）
                                write_en <= 1'b1;                   // 触发SDRAM写操作
                                pixel_cnt <= pixel_cnt + 19'd1;     // 像素计数+1
                                byte_cnt <= 2'd0;                   // 复位字节计数器，准备下一个像素
                                
                                // 一帧数据接收完成（307200个像素），回到空闲状态
                                if (pixel_cnt == PIXEL_COUNT - 19'd1) begin
                                    state <= S_IDLE;
                                end
                            end
                            // 处理后续像素的R分量（第一个字节）
                            2'd0: begin
                                write_data[23:16] <= udp_data_stable; // R分量写入
                                byte_cnt <= 2'd1; // 下一个字节处理G分量
                            end
                        endcase
                    end
                end
            endcase
        end
    end
endmodule