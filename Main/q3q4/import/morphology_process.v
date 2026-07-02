// ============================================================================
// Module: morphology_process (已修复)
// Description: 使用 BRAM line_buffer 计算 3x3 灰阶膨胀 (Max) 和 腐蚀 (Min)
// ============================================================================
module morphology_process #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480
) (
    input clk,
    input rst_n,
    input data_en,         // 输入像素有效信号 (来自 udp_cam_ctrl)
    input [7:0] pixel_in,  // 输入灰阶像素 (来自 gray_val_s1)
    output reg [7:0] dilate_out, // 膨胀 (Max)
    output reg [7:0] erode_out   // 腐蚀 (Min)
);

    localparam H_PIXEL = IMG_WIDTH;
    localparam V_PIXEL = IMG_HEIGHT;
    localparam DATA_WIDTH = 8;

// ============================================================================
// 内部 X/Y 计数器 (用于为 line_buffer 生成同步信号)
// ============================================================================
    reg [$clog2(H_PIXEL)-1:0] x_cnt;
    reg [$clog2(V_PIXEL)-1:0] y_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt <= 0;
            y_cnt <= 0;
        end else if (data_en) begin
            if (x_cnt == H_PIXEL - 1) begin
                x_cnt <= 0;
                if (y_cnt == V_PIXEL - 1) begin
                    y_cnt <= 0;
                end else begin
                    y_cnt <= y_cnt + 1;
                end
            end else begin
                x_cnt <= x_cnt + 1;
            end
        end
    end

    // 为 line_buffer 提供帧同步信号 (vsync 为高表示在第一行)
    wire line_buffer_frame_vsync = (y_cnt == 0);
    wire line_buffer_frame_href = (x_cnt < H_PIXEL); // (兼容性)

// ============================================================================
// 实例化 BRAM line_buffer (您提供的 Block 3)
// ============================================================================
    wire lb_window_valid;
    wire [DATA_WIDTH-1:0] lb_win_00, lb_win_01, lb_win_02;
    wire [DATA_WIDTH-1:0] lb_win_10, lb_win_11, lb_win_12;
    wire [DATA_WIDTH-1:0] lb_win_20, lb_win_21, lb_win_22;

    line_buffer #(
        .H_PIXEL        (H_PIXEL),
        .DATA_WIDTH     (DATA_WIDTH)
    ) u_bram_line_buffer (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in_valid  (data_en),
        .data_in        (pixel_in),
        .frame_vsync    (line_buffer_frame_vsync),
        .frame_href     (line_buffer_frame_href),
        .window_valid   (lb_window_valid),
        .win_data_00    (lb_win_00),
        .win_data_01    (lb_win_01),
        .win_data_02    (lb_win_02),
        .win_data_10    (lb_win_10),
        .win_data_11    (lb_win_11),
        .win_data_12    (lb_win_12),
        .win_data_20    (lb_win_20),
        .win_data_21    (lb_win_21),
        .win_data_22    (lb_win_22)
    );

// ============================================================================
// Dilation (Max Filter) and Erosion (Min Filter) Calculation
// ============================================================================
    
    // 比较函数
    function [DATA_WIDTH-1:0] max2 (input [DATA_WIDTH-1:0] a, input [DATA_WIDTH-1:0] b);
        max2 = (a > b) ? a : b;
    endfunction

    function [DATA_WIDTH-1:0] min2 (input [DATA_WIDTH-1:0] a, input [DATA_WIDTH-1:0] b);
        min2 = (a < b) ? a : b;
    endfunction

    // 中间寄存器 (流水线)
    reg [DATA_WIDTH-1:0] r1_max, r2_max, r3_max;
    reg [DATA_WIDTH-1:0] r1_min, r2_min, r3_min;
    reg lb_window_valid_d1;

    // 流水线第一级：计算每行的 Min/Max
    always @(posedge clk or negedge rst_n) begin
         if (!rst_n) begin
             r1_max <= 0; r2_max <= 0; r3_max <= 0;
             r1_min <= 255; r2_min <= 255; r3_min <= 255;
             lb_window_valid_d1 <= 1'b0;
         end else begin
            lb_window_valid_d1 <= lb_window_valid; // 延迟 valid 信号
            if (lb_window_valid) begin
                // Max (膨胀)
                r1_max <= max2(lb_win_00, max2(lb_win_01, lb_win_02));
                r2_max <= max2(lb_win_10, max2(lb_win_11, lb_win_12));
                r3_max <= max2(lb_win_20, max2(lb_win_21, lb_win_22));
                
                // Min (腐蚀)
                r1_min <= min2(lb_win_00, min2(lb_win_01, lb_win_02));
                r2_min <= min2(lb_win_10, min2(lb_win_11, lb_win_12));
                r3_min <= min2(lb_win_20, min2(lb_win_21, lb_win_22));
            end
         end
    end

    // 流水线第二级：计算最终的 Min/Max 并输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dilate_out <= 0;
            erode_out <= 255;
        end else if (lb_window_valid_d1) begin // S1 完成
            dilate_out <= max2(r1_max, max2(r2_max, r3_max));
            erode_out  <= min2(r1_min, min2(r2_min, r3_min));
        end
        // [NOTE] line_buffer 模块 (Block 3) 已经内置了边界处理
        // (在行计数器 < 2 时复制像素)，因此此处无需额外的边界判断。
    end

endmodule