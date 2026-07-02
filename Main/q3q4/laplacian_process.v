// ============================================================================
// Module: laplacian_process (锐化效果处理模块)
// Design: 3x3 Kernel processor, based on sobel/emboss module structure
// Kernel: [ 0, -1,  0]
//         [-1,  5, -1]
//         [ 0, -1,  0]  (Offset by +128)
// ============================================================================
module laplacian_process #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480
) (
    input clk,
    input rst_n,
    input data_en,
    input [7:0] pixel_in,
    output reg [7:0] laplacian_out
);

// 1. 坐标计数器 (与 sobel/emboss 相同)
reg [$clog2(IMG_WIDTH)-1:0] x_cnt;
reg [$clog2(IMG_HEIGHT)-1:0] y_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_cnt <= 0;
        y_cnt <= 0;
    end else if (data_en) begin
        if (x_cnt == IMG_WIDTH - 1) begin
            x_cnt <= 0;
            if (y_cnt == IMG_HEIGHT - 1) begin
                y_cnt <= 0;
            end else begin
                y_cnt <= y_cnt + 1;
            end
        end else begin
            x_cnt <= x_cnt + 1;
        end
    end
end

// 2. 行缓冲 (与 sobel/emboss 相同)
wire [7:0] line1_rd_data, line2_rd_data;

line_buffer #(.IMG_WIDTH(IMG_WIDTH)) u_line_buffer1 (
    .clk (clk),
    .wr_en (data_en),
    .wr_addr (x_cnt),
    .wr_data (pixel_in),
    .rd_addr (x_cnt),
    .rd_data (line1_rd_data)
);

line_buffer #(.IMG_WIDTH(IMG_WIDTH)) u_line_buffer2 (
    .clk (clk),
    .wr_en (data_en),
    .wr_addr (x_cnt),
    .wr_data (line1_rd_data),
    .rd_addr (x_cnt),
    .rd_data (line2_rd_data)
);

// 3. 3x3 窗口寄存器 (与 sobel/emboss 相同)
reg [7:0] p11, p12, p13;
reg [7:0] p21, p22, p23;
reg [7:0] p31, p32, p33;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p11 <= 0; p12 <= 0; p13 <= 0;
        p21 <= 0; p22 <= 0; p23 <= 0;
        p31 <= 0; p32 <= 0; p33 <= 0;
    end else if (data_en) begin
        p31 <= p32; p32 <= p33; p33 <= pixel_in;
        p21 <= p22; p22 <= p23; p23 <= line1_rd_data;
        p11 <= p12; p12 <= p13; p13 <= line2_rd_data;
    end
end

// 4. 核心计算 (Laplacian Kernel)
reg signed [11:0] laplacian_val_raw;
reg signed [11:0] temp_out;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        laplacian_val_raw <= 0;
    end else begin
        // Gx = 5*p22 - (p12 + p21 + p23 + p32)
        laplacian_val_raw <= ($signed(p22) << 2) + $signed(p22) - ($signed(p12) + $signed(p21) + $signed(p23) + $signed(p32));
    end
end

// 5. 添加偏移量 (
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        temp_out <= 0;
    end else begin
        // 将结果平移到 128 附近
        // 注意：原版锐化（5*p22 - ...）是与原图叠加，这里我们直接输出结果
        // 为了显示，我们也可以简单地加上原图 p22
        // temp_out <= $signed(p22) + laplacian_val_raw; 
        
        // 或者，为了使其成为可见的灰度图像（像Sobel一样），我们加 128
        temp_out <= laplacian_val_raw + 128;
    end
end

// 6. 输出和边界处理 (与 sobel/emboss 相同)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        laplacian_out <= 8'h80; // 输出 128 (中灰色)
    end else if ( (x_cnt < 2) || (y_cnt < 2) ) begin
        laplacian_out <= 8'h80; // 边界处理
    end else begin
        // 钳位到 0-255
        if (temp_out > 255) 
            laplacian_out <= 8'hFF;
        else if (temp_out < 0)
            laplacian_out <= 8'h00;
        else
            laplacian_out <= temp_out[7:0];
    end
end

endmodule



