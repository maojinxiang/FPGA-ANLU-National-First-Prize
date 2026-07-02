// ============================================================================
// Module: udp_cam_ctrl (已应用所有修正 + 演示顺序调整)
// ============================================================================
module udp_cam_ctrl(
    input clk,
    input rst_n,
    input key4, // 图像切换按键
    input key3, // 参数调节按键 (仅用于 亮度/饱和度)

    // ===== SDRAM 读取接口 =====
    output reg read_req,
    input read_req_ack,
    output reg read_en,
    input [31:0] read_data,

    // ===== UDP 发送接口 =====
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
// 寄存器定义
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
// 像素数据与图像模式定义
// ============================================================================
reg [31:0] read_data_buf;
reg [1:0] byte_select_cnt;
reg read_en_d1, read_en_d2;

localparam BIN_THRESHOLD = 8'd128;
localparam NUM_MODES = 16; 
reg [3:0] img_mode;

// --- 最终效果寄存器 ---
reg [7:0] gray_val;
reg [7:0] bin_r, bin_g, bin_b;
reg [7:0] gray_r, gray_g, gray_b;
reg [7:0] neg_r, neg_g, neg_b;
reg [7:0] sepia_r, sepia_g, sepia_b;
reg [7:0] bright_r, bright_g, bright_b;
reg [7:0] sat_r, sat_g, sat_b;
reg [7:0] morph_edge_val; 
reg [7:0] red_r, red_g, red_b;
reg [7:0] post_r, post_g, post_b;
reg [7:0] heat_r, heat_g, heat_b;

// --- 流水线临时寄存器 ---
reg process_en_s2;
reg [7:0] R_s1, G_s1, B_s1;
reg [7:0] gray_val_s1;
reg signed [9:0] temp_bright_r, temp_bright_g, temp_bright_b;
reg [16:0] temp_sepia_r, temp_sepia_g, temp_sepia_b;

// YUV 及饱和度计算临时寄存器
reg [7:0] Y_s1;
reg signed [8:0] U_s1, V_s1;
reg [7:0] Y_s2;
reg signed [8:0] Y_s2_signed_offset;
reg signed [16:0] temp_u_mult, temp_v_mult;
reg signed [10:0] U_sat_s2, V_sat_s2;
reg signed [10:0] U_sat_s2_clamped, V_sat_s2_clamped;
reg signed [21:0] temp_sat_r, temp_sat_g, temp_sat_b;
reg signed [21:0] termY_shifted, termV_r_shifted, termU_g_shifted, termV_g_shifted, termU_b_shifted;
reg [7:0] dilate_s1, erode_s1; // 形态学中间结果

// <<< 修正: 为 Sobel 和 Emboss 添加 S1 锁存寄存器 >>>
reg [7:0] sobel_s1;
reg [7:0] emboss_s1;

// ============================================================================
// 亮度, 缩放, 饱和度参数定义与调节逻辑
// ============================================================================
localparam BRIGHTNESS_MAX = 255;
localparam BRIGHTNESS_MIN = -255;
localparam BRIGHTNESS_STEP = 32;
reg signed [8:0] brightness_level;

reg [1:0] zoom_mode_reg;
reg [1:0] saturation_mode_reg; 
localparam SAT_FACTOR_LOW    = 8'd64;
localparam SAT_FACTOR_NORMAL = 8'd128;
localparam SAT_FACTOR_HIGH   = 8'd192;

// (注意: 此处逻辑完美匹配新的演示顺序: 4'd7=亮度, 4'd8=饱和度)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        brightness_level <= BRIGHTNESS_MIN;
        zoom_mode_reg <= 2'd0;
        saturation_mode_reg <= 2'd1;
    end else if (key3_pressed_pulse) begin
        if (img_mode == 4'd7) begin // 模式 8. 亮度调节
            if (brightness_level >= BRIGHTNESS_MAX) brightness_level <= BRIGHTNESS_MIN;
            else brightness_level <= brightness_level + BRIGHTNESS_STEP;
        end
        else if (img_mode == 4'd8) begin // 模式 9. 饱和度调节
            if (saturation_mode_reg == 2'd2) saturation_mode_reg <= 2'd0;
            else saturation_mode_reg <= saturation_mode_reg + 1;
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
// 实例化图像处理模块
// ============================================================================
wire [7:0] sobel_result_val, emboss_result_val;
wire [7:0] dilate_val, erode_val; 

sobel_process #(
    .IMG_WIDTH(IMG_WIDTH), 
    .IMG_HEIGHT(IMG_HEIGHT) // <<< 修正: 添加 IMG_HEIGHT
)
u_sobel_process (
    .clk(clk),
    .rst_n(rst_n),
    .data_en(process_en_s2), // <<< 修正: 使用 S2 使能信号 (read_en_d2)
    .pixel_in(gray_val_s1),
    .sobel_out(sobel_result_val)
);

emboss_process #(
    .IMG_WIDTH(IMG_WIDTH), 
    .IMG_HEIGHT(IMG_HEIGHT) // <<< 修正: 添加 IMG_HEIGHT
)
u_emboss_process (
    .clk(clk),
    .rst_n(rst_n),
    .data_en(process_en_s2), // <<< 修正: 使用 S2 使能信号 (read_en_d2)
    .pixel_in(gray_val_s1),
    .emboss_out(emboss_result_val)
);

morphology_process #(
    .IMG_WIDTH(IMG_WIDTH),
    .IMG_HEIGHT(IMG_HEIGHT) 
)
u_morphology_process (
    .clk(clk),
    .rst_n(rst_n),
    .data_en(process_en_s2), // <<< 修正: 使用 S2 使能信号 (read_en_d2)
    .pixel_in(gray_val_s1),
    .dilate_out(dilate_val),
    .erode_out(erode_val)
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
// 缩放核心逻辑
// ============================================================================
reg advance_pipeline;

always @(*) begin
    advance_pipeline = 1'b0;
    if (STATE == SEND_UDP_DATA) begin
        case (zoom_mode_reg) // (缩放功能已固定为 1x)
            2'd0: begin advance_pipeline = 1'b1; end
            2'd1: begin if (y_zoom_cnt == 2 || x_zoom_cnt == 2) advance_pipeline = 1'b0; else advance_pipeline = 1'b1; end
            2'd2: begin if (y_out_cnt[0] == 1'b0 && x_out_cnt[0] == 1'b0) advance_pipeline = 1'b1; else advance_pipeline = 1'b0; end
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
        dilate_s1 <= 0; erode_s1 <= 0; 
        morph_edge_val <= 0; 
        sobel_s1 <= 0; emboss_s1 <= 0; // <<< 修正: 复位新寄存器

        red_r <= 0; red_g <= 0; red_b <= 0;
        post_r <= 0; post_g <= 0; post_b <= 0;
        heat_r <= 0; heat_g <= 0; heat_b <= 0;
    end
    else begin
        // 图像处理流水线
        read_en_d2 <= read_en_d1;
        read_en_d1 <= read_en;
        process_en_s2 <= read_en_d2; 
        output_pixel_valid <= 1'b0; // 默认为低

        // 跟踪输出像素坐标 & generate output_pixel_valid
        if (STATE == SEND_UDP_DATA && app_tx_data_valid && (fifo_read_data_cnt < (IMG_FRAMSIZE - 1))) begin
            if (byte_select_cnt == 2'd2) begin
                output_pixel_valid <= 1'b1; 
                if (x_out_cnt == IMG_WIDTH - 1) begin
                    x_out_cnt <= 0; x_zoom_cnt <= 0;
                end else begin
                    x_out_cnt <= x_out_cnt + 1;
                    if (x_zoom_cnt == 2) x_zoom_cnt <= 0; else x_zoom_cnt <= x_zoom_cnt + 1;
                end
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


        // 流水线第一级 (S1) - Input side
        if (read_en_d2) begin 
            read_data_buf <= read_data;
            R_s1 <= read_data[31:24];
            G_s1 <= read_data[23:16];
            B_s1 <= read_data[15:8];

            gray_val_s1 <= ( (77 * R_s1 + 150 * G_s1 + 29 * B_s1) ) >> 8;
            Y_s1 <= ( ( 66 * R_s1 + 129 * G_s1 + 25 * B_s1 + 128) >> 8) + 16;
            U_s1 <= ( (-38 * R_s1 -  74 * G_s1 + 112 * B_s1 + 128) >> 8) + 128;
            V_s1 <= ( ( 112 * R_s1 -  94 * G_s1 - 18 * B_s1 + 128) >> 8) + 128;
        end

         // <<< 修正: 在 S2 计算开始前，锁存所有滤波器模块的输出 >>>
         // (这些滤波器模块在内部处理自己的流水线延迟)
        if (process_en_s2) begin 
            dilate_s1 <= dilate_val;
            erode_s1  <= erode_val;
            sobel_s1  <= sobel_result_val;  // <<< 修正
            emboss_s1 <= emboss_result_val; // <<< 修正
        end

        // 流水线第二级 (S2) - Output side
        if (process_en_s2) begin 
            Y_s2 <= Y_s1; 

            // 模式 1: 二值化 (新 4'd2)
            if (gray_val_s1 >= BIN_THRESHOLD) {bin_r, bin_g, bin_b} <= {8'hFF, 8'hFF, 8'hFF}; else {bin_r, bin_g, bin_b} <= {8'h00, 8'h00, 8'h00};
            // 模式 2: 灰度 (新 4'd1)
            {gray_r, gray_g, gray_b} <= {gray_val_s1, gray_val_s1, gray_val_s1};
            // 模式 4: 反相 (新 4'd3)
            {neg_r, neg_g, neg_b} <= {~R_s1, ~G_s1, ~B_s1};
            // 模式 5: 复古 (Sepia) (新 4'd6)
            temp_sepia_r <= (R_s1 * 101) + (G_s1 * 197) + (B_s1 * 48); temp_sepia_g <= (R_s1 * 89) + (G_s1 * 176) + (B_s1 * 43); temp_sepia_b <= (R_s1 * 70) + (G_s1 * 137) + (B_s1 * 34);
            sepia_r <= (temp_sepia_r > 17'd65280) ? 8'hFF : temp_sepia_r[15:8]; sepia_g <= (temp_sepia_g > 17'd65280) ? 8'hFF : temp_sepia_g[15:8]; sepia_b <= (temp_sepia_b > 17'd65280) ? 8'hFF : temp_sepia_b[15:8];
            // 模式 7: 亮度 (新 4'd7)
            temp_bright_r <= $signed({1'b0, R_s1}) + brightness_level; temp_bright_g <= $signed({1'b0, G_s1}) + brightness_level; temp_bright_b <= $signed({1'b0, B_s1}) + brightness_level;
            bright_r <= (temp_bright_r > 255) ? 8'hFF : (temp_bright_r < 0) ? 8'h00 : temp_bright_r[7:0]; bright_g <= (temp_bright_g > 255) ? 8'hFF : (temp_bright_g < 0) ? 8'h00 : temp_bright_g[7:0]; bright_b <= (temp_bright_b > 255) ? 8'hFF : (temp_bright_b < 0) ? 8'h00 : temp_bright_b[7:0];
            
            // 模式 8: 饱和度 (新 4'd8)
            temp_u_mult <= $signed(U_s1 - 128) * selected_sat_factor; temp_v_mult <= $signed(V_s1 - 128) * selected_sat_factor;
            U_sat_s2 <= temp_u_mult >>> 7; V_sat_s2 <= temp_v_mult >>> 7;
            U_sat_s2_clamped <= (U_sat_s2 > 127) ? 127 : (U_sat_s2 < -128) ? -128 : U_sat_s2; V_sat_s2_clamped <= (V_sat_s2 > 127) ? 127 : (V_sat_s2 < -128) ? -128 : V_sat_s2;
            Y_s2_signed_offset <= $signed({1'b0, Y_s2}) - 16; termY_shifted <= 298 * Y_s2_signed_offset; termV_r_shifted <= 409 * $signed(V_sat_s2_clamped); termU_g_shifted <= -100 * $signed(U_sat_s2_clamped); termV_g_shifted <= -208 * $signed(V_sat_s2_clamped); termU_b_shifted <= 516 * $signed(U_sat_s2_clamped);
            temp_sat_r <= ( termY_shifted + termV_r_shifted + 128 ) >>> 8; temp_sat_g <= ( termY_shifted + termU_g_shifted + termV_g_shifted + 128 ) >>> 8; temp_sat_b <= ( termY_shifted + termU_b_shifted + 128 ) >>> 8;
            sat_r <= (temp_sat_r > 255) ? 8'hFF : (temp_sat_r < 0) ? 8'h00 : temp_sat_r[7:0]; sat_g <= (temp_sat_g > 255) ? 8'hFF : (temp_sat_g < 0) ? 8'h00 : temp_sat_g[7:0]; sat_b <= (temp_sat_b > 255) ? 8'hFF : (temp_sat_b < 0) ? 8'h00 : temp_sat_b[7:0];
            
            // 模式 9: 形态学边缘 (新 4'd15)
            morph_edge_val <= dilate_s1 - erode_s1;
            
            // 模式 10: 红色通道 (新 4'd4)
            {red_r, red_g, red_b} <= {R_s1, 8'h00, 8'h00};

            // 模式 11: 色彩量化 (Posterize) (新 4'd5)
            {post_r, post_g, post_b} <= {R_s1 & 8'hE0, G_s1 & 8'hE0, B_s1 & 8'hE0};

            // 模式 12: 热力图 (Heatmap) (新 4'd12)
            if (gray_val_s1 < 64) begin heat_r <= 0; heat_g <= gray_val_s1 << 2; heat_b <= 255; end
            else if (gray_val_s1 < 128) begin heat_r <= 0; heat_g <= 255; heat_b <= 255 - ((gray_val_s1 - 64) << 2); end
            else if (gray_val_s1 < 192) begin heat_r <= (gray_val_s1 - 128) << 2; heat_g <= 255; heat_b <= 0; end
            else begin heat_r <= 255; heat_g <= 255 - ((gray_val_s1 - 192) << 2); heat_b <= 0; end
        end

        case(STATE)
            START_UDP: begin
                app_tx_data_request <= 1'b0; app_tx_data_valid <= 1'b0; fifo_read_data_cnt <= 12'd0; IMG_FRAMSEQ <= 32'd0;
                IMG_OFFSET <= 32'd0; read_req <= 1'b0; read_en <= 1'b0; IMG_PICSEQ <= IMG_PICSEQ + 1'd1; delay_cnt <= 22'd0;
                byte_select_cnt <= 2'd0; STATE <= WAIT_FIFO_RDY;
                x_out_cnt <= 0; y_out_cnt <= 0; x_zoom_cnt <= 0; y_zoom_cnt <= 0;
            end
            WAIT_FIFO_RDY: begin
                if(delay_cnt >= 2000) begin delay_cnt <= 22'd0; STATE <= WAIT_UDP_DATA;
                end else begin delay_cnt <= delay_cnt + 1'd1; STATE <= WAIT_FIFO_RDY; end
                if(delay_cnt == 10) read_req <= 1'b1; else if(read_req_ack) read_req <= 1'b0;
            end
            WAIT_UDP_DATA: begin
                if(udp_tx_ready) begin app_tx_data_request <= 1'b1; STATE <= WAIT_ACK;
                end else begin app_tx_data_request <= 1'b0; STATE <= WAIT_UDP_DATA; end
            end
            WAIT_ACK: begin
                if(app_tx_ack) begin
                    app_tx_data_request <= 1'b0; app_tx_header_cnt <= 9'd8; app_tx_data_valid <= 1'b1;
                    app_tx_data <= UDP_HEADER_32[7:0]; STATE <= SEND_UDP_HEADER;
                end else begin app_tx_data_request <= 1'b1; STATE <= WAIT_ACK; end
            end
            SEND_UDP_HEADER: begin
                if(app_tx_header_cnt == 9'd232) begin read_en <= 1'b1; 
                end else if(app_tx_header_cnt == 9'd240) begin read_en <= 1'b0;
                end else if(app_tx_header_cnt == 9'd248) begin end 
                
                if(app_tx_header_cnt >= IMG_HEADER_LEN) begin 
                    STATE <= SEND_UDP_DATA; 
                    app_tx_data_valid <= 1'b1; 
                    app_tx_data <= UDP_HEADER_32[app_tx_header_cnt +: 8]; 
                    app_tx_header_cnt <= 9'd0; 
                    fifo_read_data_cnt <= 12'd0; 
                    byte_select_cnt <= 2'd0;
                end else begin 
                    STATE <= SEND_UDP_HEADER; 
                    app_tx_data_valid <= 1'b1; 
                    app_tx_data <= UDP_HEADER_32[app_tx_header_cnt +: 8]; 
                    app_tx_header_cnt <= app_tx_header_cnt + 8; 
                end
            end

            SEND_UDP_DATA: begin
                if(byte_select_cnt == 2'd2) begin read_en <= advance_pipeline; end
                else begin read_en <= 1'b0; end

                // <<< 核心修改: 按照 5 阶段演示顺序重新排序 case 语句 >>>
                case(img_mode)
                    // --- 阶段 1：基础与基准 ---
                    4'd0: // 1. 原始图像 (Original RGB)
                        case(byte_select_cnt) 2'd0: app_tx_data <= G_s1; 2'd1: app_tx_data <= R_s1; 2'd2: app_tx_data <= B_s1; default: app_tx_data <= 8'h00; endcase
                    4'd1: // 2. 灰度图 (Grayscale)
                        case(byte_select_cnt) 2'd0: app_tx_data <= gray_g; 2'd1: app_tx_data <= gray_r; 2'd2: app_tx_data <= gray_b; default: app_tx_data <= 8'h00; endcase
                    4'd2: // 3. 二值化 (Binarization)
                        case(byte_select_cnt) 2'd0: app_tx_data <= bin_g; 2'd1: app_tx_data <= bin_r; 2'd2: app_tx_data <= bin_b; default: app_tx_data <= 8'h00; endcase

                    // --- 阶段 2：逐像素色彩与色调变换 ---
                    4'd3: // 4. 反相 (Negative)
                        case(byte_select_cnt) 2'd0: app_tx_data <= neg_g; 2'd1: app_tx_data <= neg_r; 2'd2: app_tx_data <= neg_b; default: app_tx_data <= 8'h00; endcase
                    4'd4: // 5. 红色通道 (Red Channel)
                        case(byte_select_cnt) 2'd0: app_tx_data <= red_g; 2'd1: app_tx_data <= red_r; 2'd2: app_tx_data <= red_b; default: app_tx_data <= 8'h00; endcase
                    4'd5: // 6. 色彩量化 (Posterize)
                        case(byte_select_cnt) 2'd0: app_tx_data <= post_g; 2'd1: app_tx_data <= post_r; 2'd2: app_tx_data <= post_b; default: app_tx_data <= 8'h00; endcase
                    4'd6: // 7. 复古/棕褐色 (Sepia)
                        case(byte_select_cnt) 2'd0: app_tx_data <= sepia_g; 2'd1: app_tx_data <= sepia_r; 2'd2: app_tx_data <= sepia_b; default: app_tx_data <= 8'h00; endcase

                    // --- 阶段 3：实时交互式处理 ---
                    4'd7: // 8. 亮度调节 (Brightness) - (key3 调节)
                        case(byte_select_cnt) 2'd0: app_tx_data <= bright_g; 2'd1: app_tx_data <= bright_r; 2'd2: app_tx_data <= bright_b; default: app_tx_data <= 8'h00; endcase
                    4'd8: // 9. 饱和度调节 (Saturation) - (key3 调节)
                        case(byte_select_cnt) 2'd0: app_tx_data <= sat_g; 2'd1: app_tx_data <= sat_r; 2'd2: app_tx_data <= sat_b; default: app_tx_data <= 8'h00; endcase

                    // --- 阶段 4：空间滤波与边缘检测 ---
                    4'd9: // 10. Sobel 边缘检测
                        case(byte_select_cnt) default: app_tx_data <= sobel_s1; endcase
                    4'd10: // 11. Sobel 反相
                        case(byte_select_cnt) default: app_tx_data <= ~sobel_s1; endcase
                    4'd11: // 12. 浮雕 (Emboss)
                        case(byte_select_cnt) default: app_tx_data <= emboss_s1; endcase
                    4'd12: // 13. 热力图 (Heatmap)
                        case(byte_select_cnt) 2'd0: app_tx_data <= heat_g; 2'd1: app_tx_data <= heat_r; 2'd2: app_tx_data <= heat_b; default: app_tx_data <= 8'h00; endcase

                    // --- 阶段 5：高级形态学处理 ---
                    4'd13: // 14. 腐蚀 (Erode)
                        case(byte_select_cnt) default: app_tx_data <= erode_s1; endcase
                    4'd14: // 15. 膨胀 (Dilate)
                        case(byte_select_cnt) default: app_tx_data <= dilate_s1; endcase
                    4'd15: // 16. 形态学边缘 (Morph Edge)
                        case(byte_select_cnt) default: app_tx_data <= morph_edge_val; endcase

                    // --- 默认 ---
                    default: 
                        case(byte_select_cnt) 2'd0: app_tx_data <= G_s1; 2'd1: app_tx_data <= R_s1; 2'd2: app_tx_data <= B_s1; default: app_tx_data <= 8'h00; endcase
                endcase
                // <<< 核心修改结束 >>>


                if(fifo_read_data_cnt >= (IMG_FRAMSIZE - 1)) begin
                    fifo_read_data_cnt <= 12'd0; app_tx_data_valid <= 1'b0; read_en <= 1'b0;
                    STATE <= DELAY;
                end else begin
                    fifo_read_data_cnt <= fifo_read_data_cnt + 1'd1; app_tx_data_valid <= 1'b1; STATE <= SEND_UDP_DATA;
                    if(byte_select_cnt >= 2'd2) byte_select_cnt <= 2'd0; else byte_select_cnt <= byte_select_cnt + 1;
                end
            end

            DELAY: begin
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