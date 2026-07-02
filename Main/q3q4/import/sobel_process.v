// ============================================================================
// Module: sobel_process (V5: 采用您指定的 G=|Gx|+|Gy| 算法, 并匹配 V4 line_buffer)
// Description: G = |Gx| + |Gy|, 已流水线化以保证时序
// ============================================================================
module sobel_process #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480
) (
    input clk,
    input rst_n,
    input data_en,         // 来自 udp_cam_ctrl (process_en_s2)
    input [7:0] pixel_in,  // 来自 udp_cam_ctrl (gray_val_s1)
    output reg [7:0] sobel_out
);

    localparam H_PIXEL = IMG_WIDTH;
    localparam V_PIXEL = IMG_HEIGHT;
    localparam DATA_WIDTH = 8;

// ============================================================================
// 1. 内部 X/Y 计数器 (为 line_buffer 生成 vsync)
// ============================================================================
    reg [$clog2(H_PIXEL)-1:0] x_cnt;
    reg [$clog2(V_PIXEL)-1:0] y_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt <= 0;
            y_cnt <= 0;
        end else if (data_en) begin // 仅在 S2 使能时推进
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

// ============================================================================
// 2. 实例化 "原模块" (V4) line_buffer (3x3 窗口生成器)
// ============================================================================
    wire lb_window_valid;
    wire [DATA_WIDTH-1:0] p11, p12, p13; // (win_data_00, 01, 02)
    wire [DATA_WIDTH-1:0] p21, p22, p23; // (win_data_10, 11, 12)
    wire [DATA_WIDTH-1:0] p31, p32, p33; // (win_data_20, 21, 22)

    // 假设 "原模块" line_buffer (V4) 在工程中可用
    line_buffer #(
        .H_PIXEL        (H_PIXEL),
        .DATA_WIDTH     (DATA_WIDTH)
    ) u_bram_line_buffer (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in_valid  (data_en),
        .data_in        (pixel_in),
        .frame_vsync    (line_buffer_frame_vsync),
        .frame_href     (1'b1), // V4 模块不使用, 保持兼容
        .window_valid   (lb_window_valid),
        .win_data_00    (p11),
        .win_data_01    (p12),
        .win_data_02    (p13),
        .win_data_10    (p21),
        .win_data_11    (p22),
        .win_data_12    (p23),
        .win_data_20    (p31),
        .win_data_21    (p32),
        .win_data_22    (p33)
    );

// ============================================================================
// 3. 实现您指定的 Sobel 计算 (已流水线化以保证时序)
// Gx = (p13 - p11) + ((p23 - p21) << 1) + (p33 - p31)
// Gy = (p31 + (p32 << 1) + p33) - (p11 + (p12 << 1) + p13)
// ============================================================================

    // S1: (从 line_buffer 输出) p11..p33 和 lb_window_valid 可用
    
    // S2: 计算 Gx 和 Gy 的正负分量
    // (这在数学上等同于您的 Gx, Gy 公式, 但更利于流水线)
    reg signed [10:0] gx_pos_s2, gx_neg_s2, gy_pos_s2, gy_neg_s2;
    reg valid_s2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gx_pos_s2 <= 0; gx_neg_s2 <= 0; gy_pos_s2 <= 0; gy_neg_s2 <= 0;
            valid_s2 <= 1'b0;
        end else begin
            valid_s2 <= lb_window_valid; // 锁存 line_buffer 的 valid
            if (lb_window_valid) begin
                // Gx = (p13 + 2*p23 + p33) - (p11 + 2*p21 + p31)
                gx_pos_s2 <= $signed(p13) + ($signed(p23) << 1) + $signed(p33);
                gx_neg_s2 <= $signed(p11) + ($signed(p21) << 1) + $signed(p31);
                
                // Gy = (p31 + 2*p32 + p33) - (p11 + 2*p12 + p13)
                gy_pos_s2 <= $signed(p31) + ($signed(p32) << 1) + $signed(p33);
                gy_neg_s2 <= $signed(p11) + ($signed(p12) << 1) + $signed(p13);
            end
        end
    end

    // S3: 计算 Gx 和 Gy 的差值
    reg signed [11:0] gx_s3, gy_s3; // Max 1020 - (-1020) = 2040
    reg valid_s3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gx_s3 <= 0; gy_s3 <= 0;
            valid_s3 <= 1'b0;
        end else begin
            valid_s3 <= valid_s2;
            if (valid_s2) begin
                gx_s3 <= gx_pos_s2 - gx_neg_s2;
                gy_s3 <= gy_pos_s2 - gy_neg_s2;
            end
        end
    end

    // S4: 计算 |Gx| 和 |Gy|
    reg [11:0] abs_gx_s4, abs_gy_s4;
    reg valid_s4;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_gx_s4 <= 0; abs_gy_s4 <= 0;
            valid_s4 <= 1'b0;
        end else begin
            valid_s4 <= valid_s3;
            if (valid_s3) begin
                abs_gx_s4 <= gx_s3[11] ? -gx_s3 : gx_s3;
                abs_gy_s4 <= gy_s3[11] ? -gy_s3 : gy_s3;
            end
        end
    end
    
    // S5: 计算 G = |Gx| + |Gy| 并饱和输出
    reg [12:0] G_s5; // Max 2040 + 2040 = 4080
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            G_s5 <= 0;
            sobel_out <= 8'h00;
        end else begin
            // 仅在流水线有效时更新输出
            if (valid_s4) begin 
                G_s5 <= $unsigned(abs_gx_s4) + $unsigned(abs_gy_s4);
                
                // 饱和输出 (G_s5 > 255)
                if (G_s5[12:8] != 0) begin
                    sobel_out <= 8'hFF;
                end else begin
                    sobel_out <= G_s5[7:0];
                end
            end
            // [Note] V4 line_buffer 内部处理边界, 
            // valid_s4 会在边界处拉低, sobel_out 将保持上一拍的值 (复位后为 0x00)
            // 这取代了您代码中 (y_cnt < 2) 的异步检查
        end
    end

endmodule