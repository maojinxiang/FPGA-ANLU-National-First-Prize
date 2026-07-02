// ============================================================================
// 行缓存模块 - 使用BRAM IP核实现
// 功能：存储2行图像数据，生成3x3滑动窗口
// 修复：使用专用BRAM IP核替代寄存器数组，解决时序问题
// ============================================================================

module line_buffer #(
    parameter H_PIXEL = 640,
    parameter DATA_WIDTH = 8
)(
    input                       clk,
    input                       rst_n,

    // 输入流接口
    input                       data_in_valid,
    input   [DATA_WIDTH-1:0]    data_in,
    input                       frame_vsync,
    input                       frame_href,     // 保持兼容性

    // 输出3x3窗口
    output reg                  window_valid,
    output reg [DATA_WIDTH-1:0] win_data_00, win_data_01, win_data_02,
    output reg [DATA_WIDTH-1:0] win_data_10, win_data_11, win_data_12,
    output reg [DATA_WIDTH-1:0] win_data_20, win_data_21, win_data_22
);

// =============================================================
// 地址计数器
// =============================================================
reg [9:0] wr_addr;      // 写地址
reg [9:0] rd_addr;      // 读地址
reg [10:0] line_cnt;

reg vsync_d1;
wire frame_start = frame_vsync & ~vsync_d1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vsync_d1 <= 1'b0;
    end else begin
        vsync_d1 <= frame_vsync;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_addr <= 10'd0;
        rd_addr <= 10'd0;
        line_cnt <= 11'd0;
    end
    else if (frame_start) begin
        wr_addr <= 10'd0;
        rd_addr <= 10'd0;
        line_cnt <= 11'd0;
    end
    else if (data_in_valid) begin  // 简化：不检查反压
        if (wr_addr == H_PIXEL - 1) begin
            wr_addr <= 10'd0;
            rd_addr <= 10'd0;
            line_cnt <= line_cnt + 1'd1;
        end
        else begin
            wr_addr <= wr_addr + 1'd1;
            rd_addr <= wr_addr;  // 读地址跟随写地址
        end
    end
end

// =============================================================
// BRAM IP核实例化
// =============================================================

// 写入数据准备（延迟1周期避免冲突）
reg [DATA_WIDTH-1:0] wr_data_0, wr_data_1;
reg wr_en;
reg [9:0] wr_addr_d1;

// BRAM读取数据（用于写入轮转）
wire [DATA_WIDTH-1:0] rd_data_0;  // line_0的读出数据
wire [DATA_WIDTH-1:0] rd_data_1;  // line_1的读出数据

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_data_0 <= 8'd0;
        wr_data_1 <= 8'd0;
        wr_en <= 1'b0;
        wr_addr_d1 <= 10'd0;
    end
    else begin
        wr_en <= data_in_valid;
        wr_addr_d1 <= wr_addr;
        wr_data_0 <= rd_data_1;  // line_0存储line_1的旧数据
        wr_data_1 <= data_in;    // line_1存储当前输入
    end
end

// BRAM 0: 存储上上行
// [NOTE] 您需要确保在您的FPGA工程中
// 存在名为 "line_ram_640x8" 的 BRAM IP 核
line_ram_640x8 u_line_ram_0 (
    // Port A: 写入端口
    .clka       (clk),
    .cea        (wr_en),
    .addra      (wr_addr_d1),
    .dia        (wr_data_0),

    // Port B: 读取端口
    .clkb       (clk),
    .ceb        (data_in_valid),
    .oceb       (1'b1),
    .addrb      (rd_addr),
    .dob        (rd_data_0),
    .rstb       (~rst_n)
);

// BRAM 1: 存储上一行
// [NOTE] 您需要确保在您的FPGA工程中
// 存在名为 "line_ram_640x8_1" 的 BRAM IP 核
line_ram_640x8_1 u_line_ram_1 (
    // Port A: 写入端口
    .clka       (clk),
    .cea        (wr_en),
    .addra      (wr_addr_d1),
    .dia        (wr_data_1),

    // Port B: 读取端口
    .clkb       (clk),
    .ceb        (data_in_valid),
    .oceb       (1'b1),
    .addrb      (rd_addr),
    .dob        (rd_data_1),
    .rstb       (~rst_n)
);

// =============================================================
// 处理BRAM读延迟（1周期）+ 构建3x3窗口
// =============================================================

// 延迟链：匹配BRAM OUTREG模式的1周期延迟
reg [DATA_WIDTH-1:0] curr_pix_d0, curr_pix_d1, curr_pix_d2;
reg valid_d0, valid_d1, valid_d2;
reg [10:0] line_cnt_d1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        curr_pix_d0 <= 8'd0;
        curr_pix_d1 <= 8'd0;
        curr_pix_d2 <= 8'd0;
        valid_d0 <= 1'b0;
        valid_d1 <= 1'b0;
        valid_d2 <= 1'b0;
        line_cnt_d1 <= 11'd0;
    end
    else begin
        curr_pix_d0 <= data_in;
        curr_pix_d1 <= curr_pix_d0;
        curr_pix_d2 <= curr_pix_d1;

        valid_d0 <= data_in_valid;
        valid_d1 <= valid_d0;
        valid_d2 <= valid_d1;

        line_cnt_d1 <= line_cnt;
    end
end

// 移位寄存器构建窗口
reg [DATA_WIDTH-1:0] row0 [0:2];
reg [DATA_WIDTH-1:0] row1 [0:2];
reg [DATA_WIDTH-1:0] row2 [0:2];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        row0[0] <= 8'd0; row0[1] <= 8'd0; row0[2] <= 8'd0;
        row1[0] <= 8'd0; row1[1] <= 8'd0; row1[2] <= 8'd0;
        row2[0] <= 8'd0; row2[1] <= 8'd0; row2[2] <= 8'd0;
    end
    else if (valid_d1) begin  // BRAM读出后1周期
        // 行0（上上行，从BRAM 0读取，BRAM已有1周期延迟）
        row0[0] <= row0[1];
        row0[1] <= row0[2];
        if (line_cnt_d1 >= 2)
            row0[2] <= rd_data_0;  // 从BRAM读取
        else
            row0[2] <= curr_pix_d1;  // 边界复制

        // 行1（上一行，从BRAM 1读取）
        row1[0] <= row1[1];
        row1[1] <= row1[2];
        if (line_cnt_d1 >= 1)
            row1[2] <= rd_data_1;  // 从BRAM读取
        else
            row1[2] <= curr_pix_d1;  // 边界复制

        // 行2（当前行，从移位寄存器）
        row2[0] <= row2[1];
        row2[1] <= row2[2];
        row2[2] <= curr_pix_d1;
    end
end

// =============================================================
// 输出窗口（再延迟1周期对齐）
// =============================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        window_valid <= 1'b0;
        win_data_00 <= 8'd0; win_data_01 <= 8'd0; win_data_02 <= 8'd0;
        win_data_10 <= 8'd0; win_data_11 <= 8'd0; win_data_12 <= 8'd0;
        win_data_20 <= 8'd0; win_data_21 <= 8'd0; win_data_22 <= 8'd0;
    end
    else begin
        // 关键修复：window_valid始终跟随有效数据
        window_valid <= valid_d2;

        // 输出3x3窗口
        win_data_00 <= row0[0];
        win_data_01 <= row0[1];
        win_data_02 <= row0[2];
        win_data_10 <= row1[0];
        win_data_11 <= row1[1];
        win_data_12 <= row1[2];
        win_data_20 <= row2[0];
        win_data_21 <= row2[1];
        win_data_22 <= row2[2];
    end
end

endmodule