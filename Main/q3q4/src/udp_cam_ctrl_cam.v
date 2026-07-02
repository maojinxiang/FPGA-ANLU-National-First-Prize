// ============================================================================
// Module: udp_cam_ctrl (已添加Log(LUT), 缩放, 饱和�? 形态学边缘, 并修复时序和溢出)
// ============================================================================
module udp_cam_ctrl_cam(
    input clk,
    input rst_n,
    input key4, // 图像切换按键
    input key3, // 参数调节按键 (复用于缩�?亮度/饱和�?

    // ===== SDRAM 读取接口 =====
    output reg read_req,
    input read_req_ack,
    output reg read_en,
    input [31:0] read_data,

    // ===== UDP 发送接�?=====
    input udp_tx_ready,
    input app_tx_ack,
    output reg app_tx_data_request,
    output reg app_tx_data_valid,
    output reg [7:0] app_tx_data,
    output reg [15:0] udp_data_length
);

// ============================================================================
// 参数定义
// ============================================================================
localparam IMG_HEADER = 32'hAA0055FF;
localparam IMG_WIDTH = 32'd640;
localparam IMG_HEIGHT = 32'd480;
localparam IMG_TOTAL = IMG_WIDTH * IMG_HEIGHT * 3;
localparam IMG_FRAMSIZE = 32'd636;
localparam IMG_FRAMTOTAL = 32'd1450;
localparam IMG_HEADER_LEN = 256;

// ============================================================================
// 状态机定义
// ============================================================================
localparam START_UDP = 3'd0;
localparam WAIT_FIFO_RDY = 3'd1;
localparam WAIT_UDP_DATA = 3'd2;
localparam WAIT_ACK = 3'd3;
localparam SEND_UDP_HEADER = 3'd4;
localparam SEND_UDP_DATA = 3'd5;
localparam DELAY = 3'd6;

reg [2:0] STATE;

// ============================================================================
// 寄存器定�?
// ============================================================================
reg [31:0] IMG_FRAMSEQ, IMG_PICSEQ, IMG_OFFSET;
reg [8:0] app_tx_header_cnt;
reg [11:0] fifo_read_data_cnt;
reg [21:0] delay_cnt;

reg [$clog2(IMG_WIDTH)-1:0]  x_out_cnt;
reg [$clog2(IMG_HEIGHT)-1:0] y_out_cnt;

reg [1:0] x_zoom_cnt;
reg [1:0] y_zoom_cnt;

reg output_pixel_valid;

reg [7:0] selected_sat_factor;

// ============================================================================
// UDP 包头
// ============================================================================
wire [255:0] UDP_HEADER_32 = { IMG_FRAMSIZE, IMG_FRAMSEQ, IMG_PICSEQ, IMG_OFFSET, IMG_TOTAL, IMG_HEIGHT, IMG_WIDTH, IMG_HEADER };

// ============================================================================
// 像素数据与图像模式定�?
// ============================================================================
reg [31:0] read_data_buf;
reg [1:0] byte_select_cnt;
reg read_en_d1, read_en_d2;

localparam BIN_THRESHOLD = 8'd128;
localparam NUM_MODES = 11; // <<< MODIFIED: 模式总数增加�?11 (0-10)

reg [3:0] img_mode;

// --- 最终效果寄存器 ---
reg [7:0] gray_val;
reg [7:0] bin_r, bin_g, bin_b;
reg [7:0] gray_r, gray_g, gray_b;
reg [7:0] neg_r, neg_g, neg_b;
reg [7:0] sepia_r, sepia_g, sepia_b;
reg [7:0] bright_r, bright_g, bright_b;
reg [7:0] log_r, log_g, log_b;
reg [7:0] log_val_comb;
reg [7:0] sat_r, sat_g, sat_b; // 饱和度效果寄存器
reg [7:0] morph_edge_val; // <<< NEW: 形态学边缘结果

// --- 流水线临时寄存器 ---
reg process_en_s2;
reg [7:0] R_s1, G_s1, B_s1;
reg [7:0] gray_val_s1;
reg signed [9:0] temp_bright_r, temp_bright_g, temp_bright_b;
reg [16:0] temp_sepia_r, temp_sepia_g, temp_sepia_b;

// YUV 及饱和度计算临时寄存�?
reg [7:0] Y_s1;
reg signed [8:0] U_s1, V_s1;
reg [7:0] Y_s2;
reg signed [8:0] Y_s2_signed_offset;
reg signed [16:0] temp_u_mult, temp_v_mult;
reg signed [10:0] U_sat_s2, V_sat_s2;
reg signed [10:0] U_sat_s2_clamped, V_sat_s2_clamped;
reg signed [21:0] temp_sat_r, temp_sat_g, temp_sat_b;
reg signed [21:0] termY_shifted, termV_r_shifted, termU_g_shifted, termV_g_shifted, termU_b_shifted;
// <<< NEW: Morphology intermediate results >>>
reg [7:0] dilate_s1, erode_s1; // Pass morphology results from S1 module output to S2


// ============================================================================
// 亮度, 缩放, 饱和度参数定义与调节逻辑
// ============================================================================
localparam BRIGHTNESS_MAX = 255;
localparam BRIGHTNESS_MIN = -255;
localparam BRIGHTNESS_STEP = 32;
reg signed [8:0] brightness_level;

reg [1:0] zoom_mode_reg; // 0=1x, 1=1.5x, 2=2x

reg [1:0] saturation_mode_reg; // 0=�?0.5x), 1=正常(1.0x), 2=�?1.5x)
localparam SAT_FACTOR_LOW    = 8'd64;  // 0.5 * 128
localparam SAT_FACTOR_NORMAL = 8'd128; // 1.0 * 128
localparam SAT_FACTOR_HIGH   = 8'd192; // 1.5 * 128

// key3 复用逻辑
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        brightness_level <= BRIGHTNESS_MIN;
        zoom_mode_reg <= 2'd0;
        saturation_mode_reg <= 2'd1;
    end else if (key3_pressed_pulse) begin
        if (img_mode == 4'd7) begin // 模式 7: 调亮�?
            if (brightness_level >= BRIGHTNESS_MAX) brightness_level <= BRIGHTNESS_MIN;
            else brightness_level <= brightness_level + BRIGHTNESS_STEP;
        end
        else if (img_mode == 4'd9) begin // 模式 9: 调饱和度
            if (saturation_mode_reg == 2'd2) saturation_mode_reg <= 2'd0;
            else saturation_mode_reg <= saturation_mode_reg + 1;
        end
        // <<< MODIFIED: Include mode 10 in zoom control >>>
        else begin // 其他模式 (包括 0-6, 8, 10): 调缩�?
            if (zoom_mode_reg == 2'd2) zoom_mode_reg <= 2'd0;
            else zoom_mode_reg <= zoom_mode_reg + 1;
        end
    end
end

// ============================================================================
// 按键消抖
// ============================================================================
wire key4_pressed_pulse, key3_pressed_pulse;

debounce #(.CLK_FREQ(125_000_000))
key4_debounce_unit (.clk(clk), .rst_n(rst_n), .button_in(key4), .button_pulse(key4_pressed_pulse));

debounce #(.CLK_FREQ(125_000_000))
key3_debounce_unit (.clk(clk), .rst_n(rst_n), .button_in(key3), .button_pulse(key3_pressed_pulse));

// ============================================================================
// 实例化图像处理模�?
// ============================================================================
wire [7:0] sobel_result_val, emboss_result_val;
wire [7:0] dilate_val, erode_val; // <<< NEW: Morphology outputs wire

sobel_process #(.IMG_WIDTH(IMG_WIDTH))
u_sobel_process (
    .clk(clk),
    .rst_n(rst_n),
    .data_en(output_pixel_valid), // Uses continuous pixel valid signal
    .pixel_in(gray_val_s1),
    .sobel_out(sobel_result_val)
);

emboss_process #(.IMG_WIDTH(IMG_WIDTH))
u_emboss_process (
    .clk(clk),
    .rst_n(rst_n),
    .data_en(output_pixel_valid), // Uses continuous pixel valid signal
    .pixel_in(gray_val_s1),
    .emboss_out(emboss_result_val)
);

// <<< NEW: Instantiate morphology_process >>>
morphology_process #(.IMG_WIDTH(IMG_WIDTH))
u_morphology_process (
    .clk(clk),
    .rst_n(rst_n),
    .data_en(output_pixel_valid), // Uses continuous pixel valid signal
    .pixel_in(gray_val_s1),       // Input grayscale value from S1
    .dilate_out(dilate_val),      // Connect to wire
    .erode_out(erode_val)         // Connect to wire
);


// ============================================================================
// 图像模式切换逻辑
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img_mode <= 4'd0;
    end else if (key4_pressed_pulse) begin
        if (img_mode == NUM_MODES - 1) img_mode <= 0;
        else img_mode <= img_mode + 1;
    end
end

// ============================================================================
// Log 变换查找�?(LUT) - 恢复为可综合版本
// ============================================================================
always @(*) begin
    case (gray_val_s1)
        8'd0: log_val_comb = 8'd0;
        8'd1: log_val_comb = 8'd32;
        8'd2: log_val_comb = 8'd51;
        8'd3: log_val_comb = 8'd64;
        8'd4: log_val_comb = 8'd74;
        8'd5: log_val_comb = 8'd82;
        8'd6: log_val_comb = 8'd90;
        8'd7: log_val_comb = 8'd96;
        8'd8: log_val_comb = 8'd101;
        8'd9: log_val_comb = 8'd106;
        8'd10: log_val_comb = 8'd110;
        8'd11: log_val_comb = 8'd114;
        8'd12: log_val_comb = 8'd118;
        8'd13: log_val_comb = 8'd121;
        8'd14: log_val_comb = 8'd125;
        8'd15: log_val_comb = 8'd128;
        8'd16: log_val_comb = 8'd130;
        8'd17: log_val_comb = 8'd133;
        8'd18: log_val_comb = 8'd136;
        8'd19: log_val_comb = 8'd138;
        8'd20: log_val_comb = 8'd140;
        8'd21: log_val_comb = 8'd143;
        8'd22: log_val_comb = 8'd145;
        8'd23: log_val_comb = 8'd147;
        8'd24: log_val_comb = 8'd149;
        8'd25: log_val_comb = 8'd151;
        8'd26: log_val_comb = 8'd153;
        8'd27: log_val_comb = 8'd155;
        8'd28: log_val_comb = 8'd157;
        8'd29: log_val_comb = 8'd158;
        8'd30: log_val_comb = 8'd160;
        8'd31: log_val_comb = 8'd162;
        8'd32: log_val_comb = 8'd163;
        8'd33: log_val_comb = 8'd165;
        8'd34: log_val_comb = 8'd166;
        8'd35: log_val_comb = 8'd168;
        8'd36: log_val_comb = 8'd169;
        8'd37: log_val_comb = 8'd171;
        8'd38: log_val_comb = 8'd172;
        8'd39: log_val_comb = 8'd174;
        8'd40: log_val_comb = 8'd175;
        8'd41: log_val_comb = 8'd176;
        8'd42: log_val_comb = 8'd178;
        8'd43: log_val_comb = 8'd179;
        8'd44: log_val_comb = 8'd180;
        8'd45: log_val_comb = 8'd182;
        8'd46: log_val_comb = 8'd183;
        8'd47: log_val_comb = 8'd184;
        8'd48: log_val_comb = 8'd185;
        8'd49: log_val_comb = 8'd187;
        8'd50: log_val_comb = 8'd188;
        8'd51: log_val_comb = 8'd189;
        8'd52: log_val_comb = 8'd190;
        8'd53: log_val_comb = 8'd191;
        8'd54: log_val_comb = 8'd192;
        8'd55: log_val_comb = 8'd194;
        8'd56: log_val_comb = 8'd195;
        8'd57: log_val_comb = 8'd196;
        8'd58: log_val_comb = 8'd197;
        8'd59: log_val_comb = 8'd198;
        8'd60: log_val_comb = 8'd199;
        8'd61: log_val_comb = 8'd200;
        8'd62: log_val_comb = 8'd201;
        8'd63: log_val_comb = 8'd202;
        8'd64: log_val_comb = 8'd203;
        8'd65: log_val_comb = 8'd204;
        8'd66: log_val_comb = 8'd205;
        8'd67: log_val_comb = 8'd206;
        8'd68: log_val_comb = 8'd207;
        8'd69: log_val_comb = 8'd208;
        8'd70: log_val_comb = 8'd209;
        8'd71: log_val_comb = 8'd210;
        8'd72: log_val_comb = 8'd211;
        8'd73: log_val_comb = 8'd212;
        8'd74: log_val_comb = 8'd213;
        8'd75: log_val_comb = 8'd214;
        8'd76: log_val_comb = 8'd215;
        8'd77: log_val_comb = 8'd215;
        8'd78: log_val_comb = 8'd216;
        8'd79: log_val_comb = 8'd217;
        8'd80: log_val_comb = 8'd218;
        8'd81: log_val_comb = 8'd219;
        8'd82: log_val_comb = 8'd220;
        8'd83: log_val_comb = 8'd220;
        8'd84: log_val_comb = 8'd221;
        8'd85: log_val_comb = 8'd222;
        8'd86: log_val_comb = 8'd223;
        8'd87: log_val_comb = 8'd224;
        8'd88: log_val_comb = 8'd224;
        8'd89: log_val_comb = 8'd225;
        8'd90: log_val_comb = 8'd226;
        8'd91: log_val_comb = 8'd227;
        8'd92: log_val_comb = 8'd227;
        8'd93: log_val_comb = 8'd228;
        8'd94: log_val_comb = 8'd229;
        8'd95: log_val_comb = 8'd230;
        8'd96: log_val_comb = 8'd230;
        8'd97: log_val_comb = 8'd231;
        8'd98: log_val_comb = 8'd232;
        8'd99: log_val_comb = 8'd232;
        8'd100: log_val_comb = 8'd233;
        8'd101: log_val_comb = 8'd234;
        8'd102: log_val_comb = 8'd234;
        8'd103: log_val_comb = 8'd235;
        8'd104: log_val_comb = 8'd236;
        8'd105: log_val_comb = 8'd236;
        8'd106: log_val_comb = 8'd237;
        8'd107: log_val_comb = 8'd238;
        8'd108: log_val_comb = 8'd238;
        8'd109: log_val_comb = 8'd239;
        8'd110: log_val_comb = 8'd239;
        8'd111: log_val_comb = 8'd240;
        8'd112: log_val_comb = 8'd241;
        8'd113: log_val_comb = 8'd241;
        8'd114: log_val_comb = 8'd242;
        8'd115: log_val_comb = 8'd242;
        8'd116: log_val_comb = 8'd243;
        8'd117: log_val_comb = 8'd244;
        8'd118: log_val_comb = 8'd244;
        8'd119: log_val_comb = 8'd245;
        8'd120: log_val_comb = 8'd245;
        8'd121: log_val_comb = 8'd246;
        8'd122: log_val_comb = 8'd246;
        8'd123: log_val_comb = 8'd247;
        8'd124: log_val_comb = 8'd247;
        8'd125: log_val_comb = 8'd248;
        8'd126: log_val_comb = 8'd248;
        8'd127: log_val_comb = 8'd249;
        8'd128: log_val_comb = 8'd249;
        8'd129: log_val_comb = 8'd250;
        8'd130: log_val_comb = 8'd250;
        8'd131: log_val_comb = 8'd251;
        8'd132: log_val_comb = 8'd251;
        8'd133: log_val_comb = 8'd252;
        8'd134: log_val_comb = 8'd252;
        8'd135: log_val_comb = 8'd253;
        8'd136: log_val_comb = 8'd253;
        8'd137: log_val_comb = 8'd254;
        8'd138: log_val_comb = 8'd254;
        8'd139: log_val_comb = 8'd255;
        default: log_val_comb = 8'd255;
    endcase
end

// ============================================================================
// Combinatorial block for selected_sat_factor
// ============================================================================
always @(*) begin
    case (saturation_mode_reg)
        2'd0: selected_sat_factor = SAT_FACTOR_LOW;
        2'd1: selected_sat_factor = SAT_FACTOR_NORMAL;
        2'd2: selected_sat_factor = SAT_FACTOR_HIGH;
        default: selected_sat_factor = SAT_FACTOR_NORMAL;
    endcase
end

// ============================================================================
// 缩放核心逻辑 - 纯组合逻辑�?
// ============================================================================
reg advance_pipeline; // 决定是否读取 SDRAM

always @(*) begin
    advance_pipeline = 1'b0;
    if (STATE == SEND_UDP_DATA) begin
        case (zoom_mode_reg)
            2'd0: begin // 1x
                advance_pipeline = 1'b1;
            end
            2'd1: begin // 1.5x
                if (y_zoom_cnt == 2 || x_zoom_cnt == 2)
                    advance_pipeline = 1'b0;
                else
                    advance_pipeline = 1'b1;
            end
            2'd2: begin // 2x
                if (y_out_cnt[0] == 1'b0 && x_out_cnt[0] == 1'b0)
                    advance_pipeline = 1'b1;
                else
                    advance_pipeline = 1'b0;
            end
            default: advance_pipeline = 1'b1;
        endcase
    end
end


// ============================================================================
// 主状态机与图像处理流水线
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // 复位所有状态和信号
        STATE <= START_UDP; app_tx_data_request <= 1'b0; app_tx_data_valid <= 1'b0; app_tx_data <= 8'd0;
        udp_data_length <= 16'd668; IMG_FRAMSEQ <= 32'd0; IMG_PICSEQ <= 32'd0; IMG_OFFSET <= 32'd0;
        app_tx_header_cnt <= 9'd0; fifo_read_data_cnt <= 12'd0; delay_cnt <= 22'd0; read_req <= 1'b0;
        read_en <= 1'b0; read_en_d1 <= 1'b0; read_en_d2 <= 1'b0; byte_select_cnt <= 2'd0; read_data_buf <= 32'd0;
        process_en_s2 <= 1'b0;

        x_out_cnt <= 0;
        y_out_cnt <= 0;
        x_zoom_cnt <= 0;
        y_zoom_cnt <= 0;
        output_pixel_valid <= 1'b0;

        // 复位 YUV 和效果寄存器
        Y_s1 <= 0; U_s1 <= 0; V_s1 <= 0; Y_s2 <= 0;
        Y_s2_signed_offset <= 0;
        temp_u_mult <= 0; temp_v_mult <= 0;
        U_sat_s2 <= 0; V_sat_s2 <= 0;
        U_sat_s2_clamped <= 0; V_sat_s2_clamped <= 0;
        temp_sat_r <= 0; temp_sat_g <= 0; temp_sat_b <= 0;
        sat_r <= 0; sat_g <= 0; sat_b <= 0;
        termY_shifted <= 0; termV_r_shifted <= 0; termU_g_shifted <= 0;
        termV_g_shifted <= 0; termU_b_shifted <= 0;
        dilate_s1 <= 0; erode_s1 <= 0; // <<< NEW Reset
        morph_edge_val <= 0; // <<< NEW Reset
    end
    else begin
        // 图像处理流水�?
        read_en_d2 <= read_en_d1;
        read_en_d1 <= read_en;
        // <<< MODIFIED: S2 enable logic needs care >>>
        // process_en_s2 should be delayed version of output_pixel_valid
        // Let's use read_en_d2 for now as it aligns with when S1 inputs are valid for S2 processing
        // but ideally, S2 processing should align DIRECTLY with output_pixel_valid if possible
        // Let's stick with read_en_d2 for now, as S2 calcs use S1 results (R_s1 etc.)
        process_en_s2 <= read_en_d2; // Keep S2 trigger tied to S1 input valid

        output_pixel_valid <= 1'b0; // Default to low

        // 跟踪输出像素坐标 & generate output_pixel_valid
        if (STATE == SEND_UDP_DATA && app_tx_data_valid && (fifo_read_data_cnt < (IMG_FRAMSIZE - 1))) begin
            if (byte_select_cnt == 2'd2) begin // 刚发送完一个像素的 3 个字�?
                output_pixel_valid <= 1'b1; // Pulse high for one cycle per output pixel
                // --- X 计数�?---
                if (x_out_cnt == IMG_WIDTH - 1) begin
                    x_out_cnt <= 0; x_zoom_cnt <= 0;
                end else begin
                    x_out_cnt <= x_out_cnt + 1;
                    if (x_zoom_cnt == 2) x_zoom_cnt <= 0; else x_zoom_cnt <= x_zoom_cnt + 1;
                end
                // --- Y 计数�?---
                if (x_out_cnt == IMG_WIDTH - 1) begin
                    if (y_out_cnt == IMG_HEIGHT - 1) begin
                        y_out_cnt <= 0; y_zoom_cnt <= 0;
                    end else begin
                        y_out_cnt <= y_out_cnt + 1;
                        if (y_zoom_cnt == 2) y_zoom_cnt <= 0; else y_zoom_cnt <= y_zoom_cnt + 1;
                    end
                end
            end
        end


        // 流水线第一�?(S1) - Input side
        if (read_en_d2) begin // When new data is valid from SDRAM read
            read_data_buf <= read_data;
            R_s1 <= read_data[31:24];
            G_s1 <= read_data[23:16];
            B_s1 <= read_data[15:8];

            gray_val_s1 <= ( (77 * R_s1 + 150 * G_s1 + 29 * B_s1) ) >> 8;
            Y_s1 <= ( ( 66 * R_s1 + 129 * G_s1 + 25 * B_s1 + 128) >> 8) + 16;
            U_s1 <= ( (-38 * R_s1 -  74 * G_s1 + 112 * B_s1 + 128) >> 8) + 128;
            V_s1 <= ( ( 112 * R_s1 -  94 * G_s1 - 18 * B_s1 + 128) >> 8) + 128;
        end

         // <<< MODIFIED: Latch morphology results triggered by read_en_d2 as well >>>
         // Since morphology module takes gray_val_s1 (from S1 stage), its output is valid
         // when the corresponding S1 stage registers are valid (i.e. process_en_s2 is high).
        if (process_en_s2) begin // Latch when S1 outputs are valid for S2 use
            dilate_s1 <= dilate_val;
            erode_s1 <= erode_val;
        end

        // 流水线第二级 (S2) - Output side
        if (process_en_s2) begin // Process when S1 results are stable
            Y_s2 <= Y_s1; // Pass Y

            // 模式 1: 二值化 ... (no change)
            if (gray_val_s1 >= BIN_THRESHOLD) {bin_r, bin_g, bin_b} <= {8'hFF, 8'hFF, 8'hFF}; else {bin_r, bin_g, bin_b} <= {8'h00, 8'h00, 8'h00};
            // 模式 2: 灰度 ... (no change)
            {gray_r, gray_g, gray_b} <= {gray_val_s1, gray_val_s1, gray_val_s1};
            // 模式 4: 反相 ... (no change)
            {neg_r, neg_g, neg_b} <= {~R_s1, ~G_s1, ~B_s1};
            // 模式 5: 复古 (Sepia) ... (no change)
            temp_sepia_r <= (R_s1 * 101) + (G_s1 * 197) + (B_s1 * 48); temp_sepia_g <= (R_s1 * 89) + (G_s1 * 176) + (B_s1 * 43); temp_sepia_b <= (R_s1 * 70) + (G_s1 * 137) + (B_s1 * 34);
            sepia_r <= (temp_sepia_r > 17'd65280) ? 8'hFF : temp_sepia_r[15:8]; sepia_g <= (temp_sepia_g > 17'd65280) ? 8'hFF : temp_sepia_g[15:8]; sepia_b <= (temp_sepia_b > 17'd65280) ? 8'hFF : temp_sepia_b[15:8];
            // 模式 7: 亮度 ... (no change)
            temp_bright_r <= $signed({1'b0, R_s1}) + brightness_level; temp_bright_g <= $signed({1'b0, G_s1}) + brightness_level; temp_bright_b <= $signed({1'b0, B_s1}) + brightness_level;
            bright_r <= (temp_bright_r > 255) ? 8'hFF : (temp_bright_r < 0) ? 8'h00 : temp_bright_r[7:0]; bright_g <= (temp_bright_g > 255) ? 8'hFF : (temp_bright_g < 0) ? 8'h00 : temp_bright_g[7:0]; bright_b <= (temp_bright_b > 255) ? 8'hFF : (temp_bright_b < 0) ? 8'h00 : temp_bright_b[7:0];
            // 模式 8: Log ... (no change)
            {log_r, log_g, log_b} <= {log_val_comb, log_val_comb, log_val_comb};

            // 模式 9: 饱和�?... (no change)
            temp_u_mult <= $signed(U_s1 - 128) * selected_sat_factor; temp_v_mult <= $signed(V_s1 - 128) * selected_sat_factor;
            U_sat_s2 <= temp_u_mult >>> 7; V_sat_s2 <= temp_v_mult >>> 7;
            U_sat_s2_clamped <= (U_sat_s2 > 127) ? 127 : (U_sat_s2 < -128) ? -128 : U_sat_s2; V_sat_s2_clamped <= (V_sat_s2 > 127) ? 127 : (V_sat_s2 < -128) ? -128 : V_sat_s2;
            Y_s2_signed_offset <= $signed({1'b0, Y_s2}) - 16; termY_shifted <= 298 * Y_s2_signed_offset; termV_r_shifted <= 409 * $signed(V_sat_s2_clamped); termU_g_shifted <= -100 * $signed(U_sat_s2_clamped); termV_g_shifted <= -208 * $signed(V_sat_s2_clamped); termU_b_shifted <= 516 * $signed(U_sat_s2_clamped);
            temp_sat_r <= ( termY_shifted + termV_r_shifted + 128 ) >>> 8; temp_sat_g <= ( termY_shifted + termU_g_shifted + termV_g_shifted + 128 ) >>> 8; temp_sat_b <= ( termY_shifted + termU_b_shifted + 128 ) >>> 8;
            sat_r <= (temp_sat_r > 255) ? 8'hFF : (temp_sat_r < 0) ? 8'h00 : temp_sat_r[7:0]; sat_g <= (temp_sat_g > 255) ? 8'hFF : (temp_sat_g < 0) ? 8'h00 : temp_sat_g[7:0]; sat_b <= (temp_sat_b > 255) ? 8'hFF : (temp_sat_b < 0) ? 8'h00 : temp_sat_b[7:0];

            // <<< NEW: 模式 10: 形态学边缘 >>>
            // Calculate gradient using latched dilate/erode values from S1 stage output
            morph_edge_val <= dilate_s1 - erode_s1;

        end

        case(STATE)
            START_UDP: begin
                app_tx_data_request <= 1'b0; app_tx_data_valid <= 1'b0; fifo_read_data_cnt <= 12'd0; IMG_FRAMSEQ <= 32'd0;
                IMG_OFFSET <= 32'd0; read_req <= 1'b0; read_en <= 1'b0; IMG_PICSEQ <= IMG_PICSEQ + 1'd1; delay_cnt <= 22'd0;
                byte_select_cnt <= 2'd0; STATE <= WAIT_FIFO_RDY;
                x_out_cnt <= 0; y_out_cnt <= 0; x_zoom_cnt <= 0; y_zoom_cnt <= 0;
            end
            WAIT_FIFO_RDY: begin // ... (no change)
                if(delay_cnt >= 2000) begin delay_cnt <= 22'd0; STATE <= WAIT_UDP_DATA;
                end else begin delay_cnt <= delay_cnt + 1'd1; STATE <= WAIT_FIFO_RDY; end
                if(delay_cnt == 10) read_req <= 1'b1; else if(read_req_ack) read_req <= 1'b0;
            end
            WAIT_UDP_DATA: begin // ... (no change)
                if(udp_tx_ready) begin app_tx_data_request <= 1'b1; STATE <= WAIT_ACK;
                end else begin app_tx_data_request <= 1'b0; STATE <= WAIT_UDP_DATA; end
            end
            WAIT_ACK: begin // ... (no change)
                if(app_tx_ack) begin
                    app_tx_data_request <= 1'b0; app_tx_header_cnt <= 9'd8; app_tx_data_valid <= 1'b1;
                    app_tx_data <= UDP_HEADER_32[7:0]; STATE <= SEND_UDP_HEADER;
                end else begin app_tx_data_request <= 1'b1; STATE <= WAIT_ACK; end
            end
            SEND_UDP_HEADER: begin // ... (no change)
                // This logic seems potentially problematic: read_en might be asserted too early or late relative to header sending
                if(app_tx_header_cnt == 9'd232) begin read_en <= 1'b1; // Start reading data slightly before finishing header?
                end else if(app_tx_header_cnt == 9'd240) begin read_en <= 1'b0;
                end else if(app_tx_header_cnt == 9'd248) begin end // NOP
                
                if(app_tx_header_cnt >= IMG_HEADER_LEN) begin // When header count reaches limit
                    STATE <= SEND_UDP_DATA; 
                    app_tx_data_valid <= 1'b1; // Keep data valid high
                    // Send the LAST byte of the header here? Or first byte of image data?
                    app_tx_data <= UDP_HEADER_32[app_tx_header_cnt +: 8]; // This seems wrong, accessing beyond header length?
                    app_tx_header_cnt <= 9'd0; 
                    fifo_read_data_cnt <= 12'd0; 
                    byte_select_cnt <= 2'd0;
                end else begin // Still sending header bytes
                    STATE <= SEND_UDP_HEADER; 
                    app_tx_data_valid <= 1'b1; 
                    app_tx_data <= UDP_HEADER_32[app_tx_header_cnt +: 8]; // Send next header byte
                    app_tx_header_cnt <= app_tx_header_cnt + 8; // Increment by 8 bits (1 byte)
                end
            end

            SEND_UDP_DATA: begin
                if(byte_select_cnt == 2'd2) begin read_en <= advance_pipeline; end
                else begin read_en <= 1'b0; end

                // 图像模式选择 - Use S2 results where available, S1 for original
                case(img_mode)
                    4'd0: case(byte_select_cnt) 2'd0: app_tx_data <= G_s1; 2'd1: app_tx_data <= R_s1; 2'd2: app_tx_data <= B_s1; default: app_tx_data <= 8'h00; endcase
                    4'd1: case(byte_select_cnt) 2'd0: app_tx_data <= bin_g; 2'd1: app_tx_data <= bin_r; 2'd2: app_tx_data <= bin_b; default: app_tx_data <= 8'h00; endcase
                    4'd2: case(byte_select_cnt) 2'd0: app_tx_data <= gray_g; 2'd1: app_tx_data <= gray_r; 2'd2: app_tx_data <= gray_b; default: app_tx_data <= 8'h00; endcase
                    4'd3: case(byte_select_cnt) default: app_tx_data <= sobel_result_val; endcase
                    4'd4: case(byte_select_cnt) 2'd0: app_tx_data <= neg_g; 2'd1: app_tx_data <= neg_r; 2'd2: app_tx_data <= neg_b; default: app_tx_data <= 8'h00; endcase
                    4'd5: case(byte_select_cnt) 2'd0: app_tx_data <= sepia_g; 2'd1: app_tx_data <= sepia_r; 2'd2: app_tx_data <= sepia_b; default: app_tx_data <= 8'h00; endcase
                    4'd6: case(byte_select_cnt) default: app_tx_data <= emboss_result_val; endcase
                    4'd7: case(byte_select_cnt) 2'd0: app_tx_data <= bright_g; 2'd1: app_tx_data <= bright_r; 2'd2: app_tx_data <= bright_b; default: app_tx_data <= 8'h00; endcase
                    4'd8: case(byte_select_cnt) 2'd0: app_tx_data <= log_g; 2'd1: app_tx_data <= log_r; 2'd2: app_tx_data <= log_b; default: app_tx_data <= 8'h00; endcase
                    4'd9: case(byte_select_cnt) 2'd0: app_tx_data <= sat_g; 2'd1: app_tx_data <= sat_r; 2'd2: app_tx_data <= sat_b; default: app_tx_data <= 8'h00; endcase
                    // <<< NEW: 模式 10: 形态学边缘 >>>
                    4'd10: case(byte_select_cnt) default: app_tx_data <= morph_edge_val; endcase // Output gradient as grayscale
                    default: case(byte_select_cnt) 2'd0: app_tx_data <= G_s1; 2'd1: app_tx_data <= R_s1; 2'd2: app_tx_data <= B_s1; default: app_tx_data <= 8'h00; endcase // Default to original
                endcase

                // State transition logic (no change)
                if(fifo_read_data_cnt >= (IMG_FRAMSIZE - 1)) begin
                    fifo_read_data_cnt <= 12'd0; app_tx_data_valid <= 1'b0; read_en <= 1'b0;
                    STATE <= DELAY;
                end else begin
                    fifo_read_data_cnt <= fifo_read_data_cnt + 1'd1; app_tx_data_valid <= 1'b1; STATE <= SEND_UDP_DATA;
                    if(byte_select_cnt >= 2'd2) byte_select_cnt <= 2'd0; else byte_select_cnt <= byte_select_cnt + 1;
                end
            end

            DELAY: begin // ... (no change)
                if(delay_cnt >= 1500) begin
                    delay_cnt <= 22'd0; IMG_FRAMSEQ <= IMG_FRAMSEQ + 1'd1; IMG_OFFSET <= IMG_OFFSET + IMG_FRAMSIZE;
                    if(IMG_FRAMSEQ >= (IMG_FRAMTOTAL - 1)) STATE <= START_UDP; else STATE <= WAIT_UDP_DATA;
                end else begin delay_cnt <= delay_cnt + 1'd1; STATE <= DELAY; end
            end

            default: STATE <= START_UDP;
        endcase
    end
end
endmodule


// ============================================================================
// Module: debounce (通用按键消抖模块)
// ============================================================================
module debounce #(
parameter CLK_FREQ = 50_000_000,
parameter DEBOUNCE_TIME_MS = 20
)(
input clk,
input rst_n,
input button_in,
output reg button_pulse
);
localparam COUNT_MAX = CLK_FREQ / 1000 * DEBOUNCE_TIME_MS;
reg [$clog2(COUNT_MAX)-1:0] count;
reg btn_sync1, btn_sync2, btn_state;
always @(posedge clk or negedge rst_n) begin
if(!rst_n) begin btn_sync1 <= 1'b1; btn_sync2 <= 1'b1; btn_state <= 1'b1; count <= 0; button_pulse <= 1'b0; end
else begin btn_sync1 <= button_in; btn_sync2 <= btn_sync1; button_pulse <= 1'b0; if(btn_sync2 != btn_state) begin count <= count + 1; if(count == COUNT_MAX - 1) begin btn_state <= ~btn_state; if(btn_state == 1'b1) begin button_pulse <= 1'b1; end end end else begin count <= 0; end end
end endmodule

// ============================================================================
// Module: sobel_process (依赖模块)
// ============================================================================
module sobel_process #( parameter IMG_WIDTH = 640, parameter IMG_HEIGHT = 480 ) ( input clk, input rst_n, input data_en, input [7:0] pixel_in, output reg [7:0] sobel_out );
reg [$clog2(IMG_WIDTH)-1:0] x_cnt; reg [$clog2(IMG_HEIGHT)-1:0] y_cnt; always @(posedge clk or negedge rst_n) begin if (!rst_n) begin x_cnt <= 0; y_cnt <= 0; end else if (data_en) begin if (x_cnt == IMG_WIDTH - 1) begin x_cnt <= 0; if (y_cnt == IMG_HEIGHT - 1) begin y_cnt <= 0; end else begin y_cnt <= y_cnt + 1; end end else begin x_cnt <= x_cnt + 1; end end end
wire [7:0] line1_rd_data, line2_rd_data;
line_buffer #(.IMG_WIDTH(IMG_WIDTH)) u_line_buffer1 ( .clk (clk), .wr_en (data_en), .wr_addr (x_cnt), .wr_data (pixel_in), .rd_addr (x_cnt), .rd_data (line1_rd_data) );
line_buffer #(.IMG_WIDTH(IMG_WIDTH)) u_line_buffer2 ( .clk (clk), .wr_en (data_en), .wr_addr (x_cnt), .wr_data (line1_rd_data), .rd_addr (x_cnt), .rd_data (line2_rd_data) );
reg [7:0] p11, p12, p13; reg [7:0] p21, p22, p23; reg [7:0] p31, p32, p33;
always @(posedge clk or negedge rst_n) begin if (!rst_n) begin p11 <= 0; p12 <= 0; p13 <= 0; p21 <= 0; p22 <= 0; p23 <= 0; p31 <= 0; p32 <= 0; p33 <= 0; end else if (data_en) begin p31 <= p32; p32 <= p33; p33 <= pixel_in; p21 <= p22; p22 <= p23; p23 <= line1_rd_data; p11 <= p12; p12 <= p13; p13 <= line2_rd_data; end end
reg signed [10:0] Gx, Gy; reg [11:0] G; always @(posedge clk or negedge rst_n) begin if (!rst_n) begin Gx <= 0; Gy <= 0; G <= 0; end else begin Gx <= (p13 - p11) + ((p23 - p21) << 1) + (p33 - p31); Gy <= (p31 + (p32 << 1) + p33) - (p11 + (p12 << 1) + p13); G <= (Gx[10] ? -Gx : Gx) + (Gy[10] ? -Gy : Gy); end end
always @(posedge clk or negedge rst_n) begin if (!rst_n) begin sobel_out <= 8'h00; end else if ( (x_cnt < 2) || (y_cnt < 2) ) begin sobel_out <= 8'h00; end else begin sobel_out <= (G > 255) ? 8'hFF : G[7:0]; end end
endmodule

// ============================================================================
// Module: emboss_process (浮雕效果处理模块)
// ============================================================================
module emboss_process #( parameter IMG_WIDTH = 640, parameter IMG_HEIGHT = 480 ) ( input clk, input rst_n, input data_en, input [7:0] pixel_in, output reg [7:0] emboss_out );
reg [$clog2(IMG_WIDTH)-1:0] x_cnt; reg [$clog2(IMG_HEIGHT)-1:0] y_cnt; always @(posedge clk or negedge rst_n) begin if (!rst_n) begin x_cnt <= 0; y_cnt <= 0; end else if (data_en) begin if (x_cnt == IMG_WIDTH - 1) begin x_cnt <= 0; if (y_cnt == IMG_HEIGHT - 1) begin y_cnt <= 0; end else begin y_cnt <= y_cnt + 1; end end else begin x_cnt <= x_cnt + 1; end end end
wire [7:0] line1_rd_data, line2_rd_data;
line_buffer #(.IMG_WIDTH(IMG_WIDTH)) u_line_buffer1 ( .clk (clk), .wr_en (data_en), .wr_addr (x_cnt), .wr_data (pixel_in), .rd_addr (x_cnt), .rd_data (line1_rd_data) );
line_buffer #(.IMG_WIDTH(IMG_WIDTH)) u_line_buffer2 ( .clk (clk), .wr_en (data_en), .wr_addr (x_cnt), .wr_data (line1_rd_data), .rd_addr (x_cnt), .rd_data (line2_rd_data) );
reg [7:0] p11, p12, p13; reg [7:0] p21, p22, p23; reg [7:0] p31, p32, p33;
always @(posedge clk or negedge rst_n) begin if (!rst_n) begin p11 <= 0; p12 <= 0; p13 <= 0; p21 <= 0; p22 <= 0; p23 <= 0; p31 <= 0; p32 <= 0; p33 <= 0; end else if (data_en) begin p31 <= p32; p32 <= p33; p33 <= pixel_in; p21 <= p22; p22 <= p23; p23 <= line1_rd_data; p11 <= p12; p12 <= p13; p13 <= line2_rd_data; end end
reg signed [9:0]  emboss_val_raw; reg signed [11:0] emboss_val_amplified; reg signed [11:0] temp_out;
always @(posedge clk or negedge rst_n) begin if (!rst_n) begin emboss_val_raw <= 0; end else begin emboss_val_raw <= $signed(p33) - $signed(p22); end end
always @(posedge clk or negedge rst_n) begin if (!rst_n) begin emboss_val_amplified <= 0; end else begin emboss_val_amplified <= emboss_val_raw << 2; end end
always @(posedge clk or negedge rst_n) begin if(!rst_n) begin temp_out <= 0; end else begin temp_out <= emboss_val_amplified + 128; end end
always @(posedge clk or negedge rst_n) begin if (!rst_n) begin emboss_out <= 8'h80; end else if ( (x_cnt < 2) || (y_cnt < 2) ) begin emboss_out <= 8'h80; end else begin if (temp_out > 255) emboss_out <= 8'hFF; else if (temp_out < 0) emboss_out <= 8'h00; else emboss_out <= temp_out[7:0]; end end
endmodule

// ============================================================================
// Module: line_buffer
// ============================================================================
module line_buffer #( parameter DATA_WIDTH = 8, parameter IMG_WIDTH = 640 ) ( input clk, input wr_en, input [$clog2(IMG_WIDTH)-1:0] wr_addr, input [DATA_WIDTH-1:0] wr_data, input [$clog2(IMG_WIDTH)-1:0] rd_addr, output [DATA_WIDTH-1:0] rd_data );
reg [DATA_WIDTH-1:0] ram_mem [0:IMG_WIDTH-1]; always @(posedge clk) begin if (wr_en) begin ram_mem[wr_addr] <= wr_data; end end
assign rd_data = ram_mem[rd_addr];
endmodule

