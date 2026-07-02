// ============================================================================
// Module: emboss_process (V3: 增强对比度)
// Description: Kernel = [-2 -1 0; -1 0 1; 0 1 2], 并放大结果
// ============================================================================
module emboss_process #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480
) (
    input clk,
    input rst_n,
    input data_en,
    input [7:0] pixel_in,   // 输入灰度像素
    output reg [7:0] emboss_out // 输出浮雕效果像素
);

    localparam H_PIXEL = IMG_WIDTH;
    localparam V_PIXEL = IMG_HEIGHT;
    localparam DATA_WIDTH = 8;

// ============================================================================
// 可调参数 (关键)
// ============================================================================
    // 放大位数 (0=1倍, 1=2倍, 2=4倍)。
    // 调高此值可增强浮雕的对比度。建议 1 或 2。
    localparam AMPLIFY_SHIFT = 1; 

// ============================================================================
// X/Y 计数器 与 BRAM line_buffer 实例化 (与之前相同)
// ============================================================================
    reg [$clog2(H_PIXEL)-1:0] x_cnt;
    reg [$clog2(V_PIXEL)-1:0] y_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin x_cnt <= 0; y_cnt <= 0; end
        else if (data_en) begin
            if (x_cnt == H_PIXEL - 1) begin
                x_cnt <= 0;
                if (y_cnt == V_PIXEL - 1) y_cnt <= 0;
                else y_cnt <= y_cnt + 1;
            end else x_cnt <= x_cnt + 1;
        end
    end
    wire line_buffer_frame_vsync = (y_cnt == 0);
    wire line_buffer_frame_href = (x_cnt < H_PIXEL);

    wire lb_window_valid;
    wire [DATA_WIDTH-1:0] lb_win_00, lb_win_01, lb_win_02; 
    wire [DATA_WIDTH-1:0] lb_win_10, lb_win_11, lb_win_12; 
    wire [DATA_WIDTH-1:0] lb_win_20, lb_win_21, lb_win_22; 

    line_buffer #(.H_PIXEL(H_PIXEL), .DATA_WIDTH(DATA_WIDTH))
    u_bram_line_buffer (
        .clk(clk), .rst_n(rst_n), .data_in_valid(data_en), .data_in(pixel_in),
        .frame_vsync(line_buffer_frame_vsync), .frame_href(line_buffer_frame_href),
        .window_valid(lb_window_valid),
        .win_data_00(lb_win_00), .win_data_01(lb_win_01), .win_data_02(lb_win_02),
        .win_data_10(lb_win_10), .win_data_11(lb_win_11), .win_data_12(lb_win_12),
        .win_data_20(lb_win_20), .win_data_21(lb_win_21), .win_data_22(lb_win_22)
    );

// ============================================================================
// 浮雕计算流水线 (4级)
// E = (p23 + p32 + 2*p33) - (p12 + p21 + 2*p11)
// ============================================================================
    
    // S1: 计算正负分量
    reg signed [10:0] pos_s1, neg_s1;
    reg valid_s1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin pos_s1 <= 0; neg_s1 <= 0; valid_s1 <= 1'b0; end
        else begin
            valid_s1 <= lb_window_valid;
            if (lb_window_valid) begin
                pos_s1 <= $signed(lb_win_12) + $signed(lb_win_21) + ($signed(lb_win_22) << 1);
                neg_s1 <= $signed(lb_win_01) + $signed(lb_win_10) + ($signed(lb_win_00) << 1);
            end
        end
    end

    // S2: 计算差值
    reg signed [11:0] diff_s2; // Max 1020 - (-1020) = 2040
    reg valid_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin diff_s2 <= 0; valid_s2 <= 1'b0; end
        else begin
            valid_s2 <= valid_s1;
            if (valid_s1) begin
                diff_s2 <= pos_s1 - neg_s1; 
            end
        end
    end
    
    // S3: (新) 放大
    reg signed [11+AMPLIFY_SHIFT:0] diff_amplified_s3; // e.g., 13 bits
    reg valid_s3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin diff_amplified_s3 <= 0; valid_s3 <= 1'b0; end
        else begin
            valid_s3 <= valid_s2;
            if (valid_s2) begin
                diff_amplified_s3 <= diff_s2 << AMPLIFY_SHIFT;
            end
        end
    end

    // S4: (原S3) 添加偏移 (128) 并饱和输出
    reg signed [12+AMPLIFY_SHIFT:0] temp_out_s4; // e.g., 14 bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_out_s4 <= 0;
            emboss_out <= 8'h80; // 复位到中灰色
        end else begin
            if (valid_s3) begin
                temp_out_s4 <= diff_amplified_s3 + 128;
                
                // 饱和处理
                if (temp_out_s4 > 255)
                    emboss_out <= 8'hFF;
                else if (temp_out_s4 < 0)
                    emboss_out <= 8'h00;
                else
                    emboss_out <= temp_out_s4[7:0];
            end
        end
    end
    
endmodule