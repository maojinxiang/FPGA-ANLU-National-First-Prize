// =============================================================================
//               合并后的顶层模块：top_dual_udp
//
// 模式定义 (来自用户的两个新开关):
//   mode_select = {mode_sw_1, mode_sw_0}
//
//   2'b00 = 模式 A-TF:   TF卡 -> SDRAM -> UDP 发送
//   2'b01 = 模式 A-CAM:  摄像头 -> SDRAM -> UDP 发送
//   2'b10 = 模式 B-HDMI: UDP 接收 -> SDRAM -> HDMI/LED 显示
//   2'b11 = (保留)
// =============================================================================

module top_dual_udp(
    // --- 共享时钟与复位 ---
    input                 clk_50,        // 主时钟 (来自项目 B 的 clk_50)
    input                 rst_n,         // [!! 已保留引脚，但内部逻辑已断开 !!]
    input                 key1,          // [!! 现在是唯一的复位源 !!]

    // --- 新的模式控制开关 ---
    input                 mode_sw_0,     // 模式选择 LSB
    input                 mode_sw_1,     // 模式选择 MSB

    // --- 项目 A (top_dual_udp) 的按键 ---
    input                 key2,          // TF 卡触发键
    input                 key3,          // 摄像头图像模式键
    input                 key4,          // 摄像头参数调节键

    // --- 项目 A (top_dual_udp) 的 SD 卡接口 ---
    output                sd_ncs,
    output                sd_dclk,
    output                sd_mosi,
    input                 sd_miso,

    

    // --- 共享 RGMII 接口 (来自两个项目) ---
    input                 phy1_rgmii_rx_clk,
    input                 phy1_rgmii_rx_ctl,
    input  [3:0]          phy1_rgmii_rx_data,
    output                phy1_rgmii_tx_clk,
    output                phy1_rgmii_tx_ctl,
    output [3:0]          phy1_rgmii_tx_data,

    // --- 项目 A (top_dual_udp) 的摄像头接口 ---
    input                 cam_pclk,
    input                 cam_vsync,
    input                 cam_href,
    input  [7:0]          cam_data,
    output                cam_rst_n,
    output                cam_pwdn,
    output                cam_scl,
    inout                 cam_sda,

    // --- 共享 SDRAM 接口 (来自项目 A) ---
    // (注意：项目 B 的 SDRAM 端口在内部，这里使用项目 A 的端口)
    output                sdram_clk,

    // --- 项目 B (UDP_Example_Top) 的 HDMI 输出 ---
    output			      HDMI_CLK_P,
    output			      HDMI_D2_P,
    output			      HDMI_D1_P,
    output			      HDMI_D0_P,

    // --- 项目 B (UDP_Example_Top) 的 LED 输出 ---
    output      [3:0]   led_data,
    output      [15:0]  dled

    

);

// =============================================================================
// 1. 参数定义 (合并自两个项目)
// =============================================================================
// ... (所有参数定义保持不变) ...
// --- 共享参数 ---
parameter  DEVICE               = "EG4"; // 两个项目一致

// --- 项目 A (top_dual_udp) 的参数 ---
parameter MEM_DATA_BITS_A       = 32;
parameter ADDR_BITS_A           = 21;
parameter BUSRT_BITS_A          = 10;
parameter LOCAL_UDP_PORT_A      = 16'h1770;
parameter LOCAL_IP_ADDRESS_A    = 32'hc0a8_f001;
parameter LOCAL_MAC_ADDRESS_A   = 48'h01_23_45_67_89_ab;
parameter DST_UDP_PORT_SD       = 16'h1773;
parameter DST_UDP_PORT_CAM      = 16'h1773;
parameter DST_IP_ADDRESS_A      = 32'hc0a8_f002;
parameter V_CMOS_DISP           = 11'd480;
parameter H_CMOS_DISP           = 11'd640;
parameter TOTAL_H_PIXEL         = H_CMOS_DISP + 12'd1216;
parameter TOTAL_V_PIXEL         = V_CMOS_DISP + 12'd504;

// --- 项目 B (UDP_Example_Top) 的参数 ---
parameter  LOCAL_UDP_PORT_B     = 16'h0001;       
parameter  LOCAL_IP_ADDRESS_B   = 32'hc0a8f001;       
parameter  LOCAL_MAC_ADDRESS_B  = 48'h0123456789ab; // 与 A 相同
parameter  DST_UDP_PORT_B       = 16'h0002;       
parameter  DST_IP_ADDRESS_B     = 32'hc0a8f002;       // 与 A 相同
parameter  LED_PAYLOAD_MAX_BYTES  = 16'd3;
parameter  HDMI_PAYLOAD_MIN_BYTES = LED_PAYLOAD_MAX_BYTES + 16'd1;
parameter  [15:0] LED_REMOTE_PORT_NUM  = 16'hFFFF;
parameter  [15:0] HDMI_REMOTE_PORT_NUM = 16'hFFFF;
parameter  [15:0] FRAME_IDLE_TIMEOUT   = 16'd8192;


// =============================================================================
// 2. 模式与复位逻辑 (核心) [!! 已修改 !!]
// =============================================================================

// --- 2a. 模式选择 ---
wire [1:0] mode_select = {mode_sw_1, mode_sw_0};

wire mode_is_tf_udp   = (mode_select == 2'b00);
wire mode_is_cam_udp  = (mode_select == 2'b01);
wire mode_is_udp_hdmi = (mode_select == 2'b10);
wire mode_is_idle     = (mode_select == 2'b11);

// --- 2b. [!! 新增 !!] 实例化 POR 发生器 ---
wire por_reset_n_internal; // 来自 POR 计数器的稳定信号 (低有效)
por_generator u_por_gen (
    .clk_50      (clk_50),
    .por_reset_n (por_reset_n_internal)
);

// --- 2c. [!! 新增 !!] 创建主复位信号 (Master Reset) ---
// master_reset_n 是系统的主 "低有效" 复位。
// 它在 (POR 正在计数) 或 (用户按下了 key1) 时变为低电平。
// (key1 是低有效按键)
wire master_reset_n = por_reset_n_internal & key1; 

// master_reset 是对应的 "高有效" 复位。
wire master_reset   = ~master_reset_n;


// --- 2d. 项目 B 的时钟复位逻辑 (来自 u_clk_gen) ---
wire        reset_reg; // 这是来自 u_clk_gen 的 "PLL 锁定后" 的复位信号
wire        clk_25_out;
// [!! 已删除 !!] phy_reset_cnt 逻辑
// [!! 修改 !!] soft_reset_cnt 现在由 master_reset 复位
reg [7:0]   soft_reset_cnt=8'hff;
always @(posedge udp_clk or posedge master_reset) begin // [!! 修改 !!]
    if(master_reset) // [!! 修改 !!]
        soft_reset_cnt<=8'hff;
    else if(soft_reset_cnt > 0)
        soft_reset_cnt<= soft_reset_cnt-1;
    else
        soft_reset_cnt<=soft_reset_cnt;
end

// --- 2e. [!! 新增 !!] 创建应用复位 (App Reset) ---
// 这是用于所有 "非 PLL" 逻辑的复位信号。
// 假设 reset_reg 在复位期间为高，锁定后为低。
wire app_reset_high = reset_reg | (soft_reset_cnt != 'd0);
wire app_reset_low  = ~app_reset_high;


// --- 2f. 项目 A 的模式切换复位逻辑 (用于 SDRAM 和 UDP 刷新) ---
localparam MODE_RST_CYCLES = 12'd2048;
wire ext_mem_clk; // 来自下面的 `video_pll`
wire udp_clk;     // 来自下面的 `udp_clk_gen`

// mem_clk 域同步
reg  mode_mem_d0, mode_mem_d1;
reg [11:0] mode_mem_rst_cnt;
// [!! 已修改 !!] 异步复位源从 rst_n/key1 改为 master_reset
always @(posedge ext_mem_clk or posedge master_reset) begin // [!! 修改 !!]
    if(master_reset) begin // [!! 修改 !!]
        mode_mem_d0     <= 1'b0;
        mode_mem_d1     <= 1'b0;
        mode_mem_rst_cnt<= MODE_RST_CYCLES;
    end else begin
        // [修改] 仅在项目 A 的两个模式间切换时触发此复位
        mode_mem_d0 <= mode_is_cam_udp; 
        mode_mem_d1 <= mode_mem_d0;
        if(mode_mem_d0 ^ mode_mem_d1) begin
            mode_mem_rst_cnt <= MODE_RST_CYCLES;
        end else if(mode_mem_rst_cnt != 12'd0) begin
            mode_mem_rst_cnt <= mode_mem_rst_cnt - 12'd1;
        end
    end
end
wire mode_recfg_mem = (mode_mem_rst_cnt != 12'd0); // 项目 A 内部切换复位

// udp_clk 域同步
reg  mode_udp_d0, mode_udp_d1;
reg [11:0] mode_udp_rst_cnt;
// [!! 已修改 !!] 异步复位源从 rst_n/key1 改为 master_reset
always @(posedge udp_clk or posedge master_reset) begin // [!! 修改 !!]
    if(master_reset) begin // [!! 修改 !!]
        mode_udp_d0      <= 1'b0;
        mode_udp_d1      <= 1'b0;
        mode_udp_rst_cnt <= MODE_RST_CYCLES;
    end else begin
        // [修改] 仅在项目 A 的两个模式间切换时触发此复位
        mode_udp_d0 <= mode_is_cam_udp; 
        mode_udp_d1 <= mode_udp_d0;
        if(mode_udp_d0 ^ mode_udp_d1) begin
            mode_udp_rst_cnt <= MODE_RST_CYCLES;
        end else if(mode_udp_rst_cnt != 12'd0) begin
            mode_udp_rst_cnt <= mode_udp_rst_cnt - 12'd1;
        end
    end
end
wire mode_recfg_udp = (mode_udp_rst_cnt != 12'd0); // 项目 A 内部切换复位


// --- 2g. 域复位 (使用新的 App Reset) ---
// 域 A (TF/CAM) 复位：当 (全局 App 复位) 或 (切换到 B 模式)
wire rst_A_domain = app_reset_high | mode_is_udp_hdmi;
wire rst_n_A_domain = ~rst_A_domain; // (注：这是 rst_A_domain 的反相)

// 域 B (HDMI) 复位：当 (全局 App 复位) 或 (未切换到 B 模式)
wire rst_B_domain = app_reset_high | ~mode_is_udp_hdmi;
wire rst_n_B_domain = ~rst_B_domain;

// SDRAM IP 复位：当 (全局 Master 复位) 或 (项目 A 内部切换)
wire sdram_ip_reset = master_reset | mode_recfg_mem;


// =============================================================================
// 3. 时钟生成 (合并) [!! 已修改 !!]
// =============================================================================

// --- 3a. 项目 B 的 UDP/TEMAC 时钟 ---
wire        temac_clk;
wire        clk_125_out;
wire        temac_clk90;
wire        clk_12_5_out;
wire        clk_1_25_out;
wire [1:0]  TRI_speed = 2'b10; // 千兆

clk_gen_rst_gen#(
    .DEVICE         (DEVICE     )
) u_clk_gen(
    .reset          (master_reset), // [!! 修改 !!]
    .clk_in         (clk_50     ),
    .rst_out        (reset_reg  ),  // -> 这是我们的 App Reset 来源之一
    .clk_125_out0   (temac_clk  ),
    .clk_125_out1   (clk_125_out),
    .clk_125_out2   (temac_clk90),
    .clk_12_5_out   (clk_12_5_out),
    .clk_1_25_out   (clk_1_25_out),
    .clk_25_out     (clk_25_out )
);

udp_clk_gen#(
    .DEVICE               (DEVICE                   )
)  u_udp_clk_gen(           
    .reset                (master_reset), // [!! 修改 !!]
    .tri_speed            (TRI_speed                ),
    .clk_125_in           (clk_125_out              ),
    .clk_12_5_in          (clk_12_5_out             ),
    .clk_1_25_in          (clk_1_25_out             ),
    .udp_clk_out          (udp_clk                  ) // -> udp_clk
);

// --- 3b. 项目 B 的 SDRAM/HDMI 时钟 ---
wire        mem_clk_sft;
wire        video_clk;
wire        video_clk_5x;

video_pll u_video_mem_pll (
    .refclk         (clk_50),
    .reset          (master_reset), // [!! 修改 !!]
    .clk0_out       (ext_mem_clk),      // -> ext_mem_clk (项目 A+B 共享)
    .clk1_out       (mem_clk_sft),  
    .clk2_out       (video_clk),    
    .clk3_out       (video_clk_5x)  
);

// --- 3c. 项目 A 的 SD 卡时钟 ---
wire sd_card_clk;
sys_pll sys_pll_m0(
    .refclk     (clk_50),
    .clk0_out   (sd_card_clk),    // -> sd_card_clk
    .clk1_out   (),               
    .clk2_out   (),               
    .reset      (master_reset)    // [!! 关键修改 !!]
);

// --- 3d. 项目 A 的 RGMII RX 时钟 ---
wire phy1_rgmii_rx_clk_0;
wire phy1_rgmii_rx_clk_90;
rx_pll u_rx_pll (
    .refclk     (phy1_rgmii_rx_clk),
    .reset      (master_reset), // [!! 关键修改 !!]
    .clk0_out   (phy1_rgmii_rx_clk_0),
    .clk1_out   (phy1_rgmii_rx_clk_90)
);

// --- 3e. 顶层 SDRAM 时钟输出 ---
assign sdram_clk = ext_mem_clk;

// =============================================================================
// 4. 共享资源线网定义
// =============================================================================
// ... (所有线网定义保持不变) ...
// --- 4a. 共享 SDRAM IP 接口线网 (连接到 Mux) ---
wire        Sdr_init_done;
wire        Sdr_busy; // (来自 A)
wire        App_wr_en_Mux;
wire [20:0] App_wr_addr_Mux; // (使用 B 的 21-bit)
wire [31:0] App_wr_din_Mux;
wire [3:0]  App_wr_dm_Mux;
wire        App_rd_en_Mux;
wire [20:0] App_rd_addr_Mux; // (使用 B 的 21-bit)
wire        Sdr_rd_en_Demux;
wire [31:0] Sdr_rd_dout_Demux;

// --- 4b. 共享 UDP 协议栈接口线网 (连接到 Mux/Demux) ---
// TX (Muxed Inputs to Stack)
wire         stack_tx_request;
wire         stack_tx_data_valid;
wire [7:0]   stack_tx_data;
wire [15:0]  stack_tx_data_length;
wire [15:0]  stack_tx_dst_port;
wire [31:0]  stack_tx_dst_ip;
// TX (Outputs from Stack)
wire         udp_tx_ready_Demux; // (广播)
wire         app_tx_ack_Demux;   // (广播)

// RX (Outputs from Stack -> To Classifier)
wire         stack_rx_data_valid; 
wire [7:0]   stack_rx_data;       
wire [15:0]  stack_rx_data_length;
wire [15:0]  stack_rx_port_num;

// --- 4c. 共享 TEMAC 接口线网 (连接 Stack 和 FIFOs) ---
wire        temac_tx_ready;
wire        temac_tx_valid;
wire [7:0]  temac_tx_data; 
wire        temac_tx_sof;
wire        temac_tx_eof;
wire        temac_rx_ready;
wire        temac_rx_valid;
wire [7:0]  temac_rx_data; 
wire        temac_rx_sof;
wire        temac_rx_eof;
wire        rx_correct_frame;
wire        rx_error_frame;
wire        rx_clk_int; 
wire        rx_clk_en_int;
wire        tx_clk_int; 
wire        tx_clk_en_int;
wire        rx_valid;
wire [7:0]  rx_data;   
wire [7:0]  tx_data;    
wire        tx_valid;   
wire        tx_rdy;         
wire        tx_collision;   
wire        tx_retransmit;
wire        tx_stop;
wire [7:0]  tx_ifg_val;
wire        pause_req;
wire [15:0] pause_val;
wire [47:0] pause_source_addr;
wire [47:0] unicast_address;
wire [19:0] mac_cfg_vector;  


// =============================================================================
// 5. 例化项目 A (TF/CAM -> UDP) 的模块 [!! 已修改 !!]
// =============================================================================

// --- 5a. SD 卡模块 ---
wire [3:0]  sd_state_code;
wire        sd_write_req;
wire        sd_write_req_ack;
wire        sd_write_en;
wire [31:0] sd_write_data;
// [!! 已修改 !!] sd_rst 现在由 app_reset_high (来自 key1 和 POR) 控制
wire        sd_rst = app_reset_high | ~mode_is_tf_udp; // 仅在 00 模式工作

sd_card_bmp sd_card_bmp_m0(
    .clk            (sd_card_clk),
    .rst            (sd_rst), // [!! 修改 !!]
    .key            (key2),
    .state_code     (sd_state_code),
    .bmp_width      (16'd640),
    .write_req      (sd_write_req),
    .write_req_ack  (sd_write_req_ack),
    .write_en       (sd_write_en),
    .write_data     (sd_write_data),
    .SD_nCS         (sd_ncs),
    .SD_DCLK        (sd_dclk),
    .SD_MOSI        (sd_mosi),
    .SD_MISO        (sd_miso)
);

// --- 5c. 摄像头模块 ---
wire        cam_write_req;
wire        cam_write_req_ack;
wire        cam_write_en;
wire [31:0] cam_write_data;
wire        cam_rst_n_int;
wire        cam_pwdn_int;
wire        cam_scl_int;
wire        cam_init_done;
wire        cmos_frame_vsync;
wire        cmos_frame_href;
wire        cmos_frame_valid;
wire [15:0] cmos_wr_data;
// [!! 已修改 !!] 摄像头使能/复位逻辑现在由 app_reset_low (低有效) 控制
wire        cam_rst_n_gate = app_reset_low & mode_is_cam_udp; // 仅在 01 模式工作

ov5640_dri u_ov5640_dri(
    .clk                (clk_50),
    .rst_n              (cam_rst_n_gate), // [!! 修改 !!]
    .cam_pclk           (cam_pclk),
    .cam_vsync          (cam_vsync),
    .cam_href           (cam_href),
    .cam_data           (cam_data),
    .cam_rst_n          (cam_rst_n_int),
    .cam_pwdn           (cam_pwdn_int),
    .cam_scl            (cam_scl_int),
    .cam_sda            (cam_sda),
    .capture_start      (Sdr_init_done),
    .cmos_h_pixel       (H_CMOS_DISP),
    .cmos_v_pixel       (V_CMOS_DISP),
    .total_h_pixel      (TOTAL_H_PIXEL),
    .total_v_pixel      (TOTAL_V_PIXEL),
    .cam_init_done      (cam_init_done),
    .cmos_frame_vsync (cmos_frame_vsync),
    .cmos_frame_href  (cmos_frame_href),
    .cmos_frame_valid (cmos_frame_valid),
    .cmos_frame_data  (cmos_wr_data)
);

ov5640_delay u_ov5640_delay(
    .clk                (cam_pclk),
    .rst_n              (cam_rst_n_gate), // [!! 修改 !!]
    .cmos_frame_vsync   (cmos_frame_vsync),
    .cmos_frame_href    (cmos_frame_href),
    .cmos_frame_valid   (cmos_frame_valid),
    .cmos_wr_data       (cmos_wr_data),
    .cam_write_en       (cam_write_en),
    .cam_write_data     (cam_write_data),
    .cam_write_req      (cam_write_req),
    .cam_write_req_ack  (cam_write_req_ack)
);

assign cam_rst_n = cam_rst_n_gate ? cam_rst_n_int : 1'b0;
assign cam_pwdn  = cam_rst_n_gate ? cam_pwdn_int  : 1'b1;
assign cam_scl   = cam_rst_n_gate ? cam_scl_int   : 1'b1;

// --- 5d. 项目 A 的 Mux (TF/CAM 数据源选择) ---
wire write_req_A    = mode_is_cam_udp ? cam_write_req    : sd_write_req;
wire write_en_A     = mode_is_cam_udp ? cam_write_en     : sd_write_en;
wire [31:0] write_data_A = mode_is_cam_udp ? cam_write_data : sd_write_data;
wire write_clk_A    = mode_is_cam_udp ? cam_pclk         : sd_card_clk;

wire frame_write_req_ack_A;
assign cam_write_req_ack = mode_is_cam_udp ? frame_write_req_ack_A : 1'b0;
assign sd_write_req_ack  = mode_is_tf_udp  ? frame_write_req_ack_A : 1'b0;

// --- 5e. 项目 A 的 SDRAM 读写控制器 (连接到仲裁器) ---
wire        video_read_req_A;
wire        video_read_req_ack_A;
wire        video_read_en_A;
wire [31:0] video_read_data_A;
wire        App_wr_en_A;
wire [20:0] App_wr_addr_A;
wire [31:0] App_wr_din_A;
wire [3:0]  App_wr_dm_A;
wire        App_rd_en_A;
wire [20:0] App_rd_addr_A;

frame_read_write #(
    .ADDR_BITS(21) // [修改] 强制使用 21-bit 地址以匹配项目 B
)
frame_read_write_m0(
    .mem_clk                (ext_mem_clk), // [修改] 使用共享的 mem_clk
    .rst                    (rst_A_domain | mode_recfg_mem), // [!! 修改 !!] rst_A_domain 源自 app_reset
    .Sdr_init_done          (Sdr_init_done),
    .Sdr_init_ref_vld       (1'b1), // (假设)
    .Sdr_busy               (Sdr_busy),
    .App_rd_en              (App_rd_en_A),       // -> 输出到 Mux
    .App_rd_addr            (App_rd_addr_A),     // -> 输出到 Mux
    .Sdr_rd_en              (Sdr_rd_en_Demux),   // <- 来自 Demux
    .Sdr_rd_dout            (Sdr_rd_dout_Demux), // <- 来自 Demux
    .read_clk               (udp_clk),
    .read_req               (video_read_req_A),
    .read_req_ack           (video_read_req_ack_A),
    .read_finish            (),
    .read_addr_0            (24'd0),
    .read_addr_1            (24'd0),
    .read_addr_2            (24'd0),
    .read_addr_3            (24'd0),
    .read_addr_index        (2'd0),
    .read_len               (24'd307200),
    .read_en                (video_read_en_A),
    .read_data              (video_read_data_A),
    .App_wr_en              (App_wr_en_A),       // -> 输出到 Mux
    .App_wr_addr            (App_wr_addr_A[20:0]), // -> 输出到 Mux
    .App_wr_din             (App_wr_din_A),      // -> 输出到 Mux
    .App_wr_dm              (App_wr_dm_A),       // -> 输出到 Mux
    .write_clk              (write_clk_A),       // (来自 5d 的 Mux)
    .write_req              (write_req_A),       // (来自 5d 的 Mux)
    .write_req_ack          (frame_write_req_ack_A),
    .write_finish           (),
    .write_addr_0           (24'd0),
    .write_addr_1           (24'd0),
    .write_addr_2           (24'd0),
    .write_addr_3           (24'd0),
    .write_addr_index       (2'd0),
    .write_len              (24'd307200),
    .write_en               (write_en_A),        // (来自 5d 的 Mux)
    .write_data             (write_data_A)       // (来自 5d 的 Mux)
);



// =============================================================================
// 5f. [!! 已修正 !!] 项目 A 的 UDP 控制器 (TF/CAM)
// =============================================================================
wire        cam_read_req;
wire        cam_read_en;
wire        cam_app_tx_data_request;
wire        cam_app_tx_data_valid;
wire [7:0]  cam_app_tx_data;
wire [15:0] cam_udp_data_length;
wire        tf_read_req;
wire        tf_read_en;
wire        tf_app_tx_data_request;
wire        tf_app_tx_data_valid;
wire [7:0]  tf_app_tx_data;
wire [15:0] tf_udp_data_length;

// ... (删除的 assign 语句保持删除) ...


udp_cam_ctrl u_udp_cam_ctrl_cam(
    .clk                    (udp_clk),
    // [!! 已修改 !!] rst_n (低有效使能) 信号源改为 app_reset_low
    .rst_n                  (app_reset_low & Sdr_init_done & mode_is_cam_udp & ~mode_recfg_udp), // [!! 修改 !!]
    .key4                   (key4), // (按键保持连接)
    .key3                   (key3), // (按键保持连接)
    .read_req               (cam_read_req),
    .read_req_ack           (video_read_req_ack_A), // [!! 已修正 !!] 
    .read_en                (cam_read_en),
    .read_data              (video_read_data_A),
    .udp_tx_ready           (udp_tx_ready_Demux),   
    .app_tx_ack             (app_tx_ack_Demux),
    .app_tx_data_request    (cam_app_tx_data_request), // -> 输出到 TX Mux
    .app_tx_data_valid      (cam_app_tx_data_valid),   // -> 输出到 TX Mux
    .app_tx_data            (cam_app_tx_data),         // -> 输出到 TX Mux
    .udp_data_length        (cam_udp_data_length)    // -> 输出到 TX Mux
);

udp_cam_ctrl_tf u_udp_cam_ctrl_tf(
    .clk                    (udp_clk),
    // [!! 已修改 !!] rst_n (低有效使能) 信号源改为 app_reset_low
    .rst_n                  (app_reset_low & Sdr_init_done & mode_is_tf_udp & ~mode_recfg_udp), // [!! 修改 !!]
    .read_req               (tf_read_req),
    .read_req_ack           (video_read_req_ack_A), // [!! 已修正 !!]
    .read_en                (tf_read_en),
    .read_data              (video_read_data_A),
    .udp_tx_ready           (udp_tx_ready_Demux),   
    .app_tx_ack             (app_tx_ack_Demux),
    .app_tx_data_request    (tf_app_tx_data_request), // -> 输出到 TX Mux
    .app_tx_data_valid      (tf_app_tx_data_valid),   // -> 输出到 TX Mux
    .app_tx_data            (tf_app_tx_data),         // -> 输出到 TX Mux
    .udp_data_length        (tf_udp_data_length)    // -> 输出到 TX Mux
);

assign video_read_req_A = mode_is_cam_udp ? cam_read_req : tf_read_req;
assign video_read_en_A  = mode_is_cam_udp ? cam_read_en  : tf_read_en;

// =============================================================================
// 6. 例化项目 B (UDP -> HDMI/LED) 的模块 [!! 已修改 !!]
// =============================================================================

// --- 6a. 项目 B 的 UDP 接收分类逻辑 (核心) ---
localparam [1:0] FRAME_MODE_DROP = 2'b00;
localparam [1:0] FRAME_MODE_LED  = 2'b01;
localparam [1:0] FRAME_MODE_HDMI = 2'b10;

reg        frame_active;
reg [1:0]  frame_mode;
reg [15:0] bytes_remaining;
reg [15:0] frame_idle_cnt;
// [!! LED 修复: 已删除 latched_rx_data_length 寄存器 !!]

wire led_port_match  = (LED_REMOTE_PORT_NUM  == 16'hFFFF) ? 1'b1 : (stack_rx_port_num == LED_REMOTE_PORT_NUM);
wire hdmi_port_match = (HDMI_REMOTE_PORT_NUM == 16'hFFFF) ? 1'b1 : (stack_rx_port_num == HDMI_REMOTE_PORT_NUM);
wire led_length_ok   = (stack_rx_data_length != 16'd0) && (stack_rx_data_length <= LED_PAYLOAD_MAX_BYTES);
wire hdmi_length_ok  = (stack_rx_data_length >= HDMI_PAYLOAD_MIN_BYTES);
wire led_candidate   = led_port_match  && led_length_ok;
wire hdmi_candidate  = hdmi_port_match && hdmi_length_ok;
wire [1:0] frame_mode_next = led_candidate  ? FRAME_MODE_LED  :
                             hdmi_candidate ? FRAME_MODE_HDMI :
                                              FRAME_MODE_DROP;
wire frame_start = stack_rx_data_valid && !frame_active;

wire processing_led  = stack_rx_data_valid && (frame_active ? (frame_mode == FRAME_MODE_LED)  :
                                           (frame_start ? (frame_mode_next == FRAME_MODE_LED)  : 1'b0));
wire processing_hdmi = stack_rx_data_valid && (frame_active ? (frame_mode == FRAME_MODE_HDMI) :
                                           (frame_start ? (frame_mode_next == FRAME_MODE_HDMI) : 1'b0));

// [!! 已修改 !!] 这里的复位源改为 app_reset_high
always @(posedge udp_clk or posedge app_reset_high) begin // [!! 修改 !!]
    if (app_reset_high) begin // [!! 修改 !!]
        frame_active    <= 1'b0;
        frame_mode      <= FRAME_MODE_DROP;
        bytes_remaining <= 16'd0;
        frame_idle_cnt  <= 16'd0;
        // [!! LED 修复: 已删除对 latched_rx_data_length 的赋值 !!]
    end else begin
        if (frame_start) begin
            frame_mode      <= frame_mode_next;
            frame_idle_cnt  <= 16'd0;
            // [!! LED 修复: 已删除对 latched_rx_data_length 的赋值 !!]

            if (stack_rx_data_length <= 16'd1) begin
                frame_active    <= 1'b0;
                frame_mode      <= FRAME_MODE_DROP;
                bytes_remaining <= 16'd0;
            end else begin
                frame_active    <= 1'b1;
                bytes_remaining <= stack_rx_data_length - 16'd1;
            end
        end else if (frame_active) begin
            if (stack_rx_data_valid) begin
                frame_idle_cnt <= 16'd0;
                if (bytes_remaining <= 16'd1) begin
                    frame_active    <= 1'b0;
                    frame_mode      <= FRAME_MODE_DROP;
                    bytes_remaining <= 16'd0;
                end else begin
                    bytes_remaining <= bytes_remaining - 16'd1;
                end
            end else if (frame_idle_cnt >= FRAME_IDLE_TIMEOUT) begin
                frame_active    <= 1'b0;
                bytes_remaining <= 16'd0;
                frame_mode      <= FRAME_MODE_DROP;
                frame_idle_cnt  <= 16'd0;
            end else begin
                frame_idle_cnt <= frame_idle_cnt + 16'd1;
            end
        end else begin
            frame_idle_cnt <= 16'd0;
        end
    end
end

// 为子模块生成最终的 'valid' 信号，并受模式开关控制
wire app_rx_data_valid_led  = processing_led  & mode_is_udp_hdmi;
wire app_rx_data_valid_hdmi = processing_hdmi & mode_is_udp_hdmi;

// --- 6b. 项目 B 的 LED 控制模块 ---
led u0_led(
       .udp_rx_clk                 (udp_clk),
       .reset                      (app_reset_low), // [!! 修改 !!] 假设 led 模块是低有效复位 (原为 key1)
       .app_rx_data_valid          (app_rx_data_valid_led), 
       .app_rx_data                (stack_rx_data), // (来自堆栈的原始数据)
       .app_rx_data_length         (stack_rx_data_length), // [!! LED 修复: 恢复连接到原始信号 !!]
       .dled                       (dled),
       .led_data_1                 (led_data)
 );

// --- 6c. 项目 B 的视频子系统 (app) ---
wire        App_wr_en_B;
wire [20:0] App_wr_addr_B;
wire [31:0] App_wr_din_B;
wire [3:0]  App_wr_dm_B;
wire        App_rd_en_B;
wire [20:0] App_rd_addr_B;

app u_video_subsystem (
    .udp_clk           (udp_clk),
    .mem_clk           (ext_mem_clk), // [修改] 使用共享的 mem_clk
    .video_clk         (video_clk),
    .video_clk_5x      (video_clk_5x),
    .reset             (rst_B_domain), // [!! 修改 !!] 使用源自 app_reset 的域复位
    .app_rx_data_valid (app_rx_data_valid_hdmi), 
    .app_rx_data       (stack_rx_data),
    .Sdr_init_done     (Sdr_init_done),
    .Sdr_rd_en         (Sdr_rd_en_Demux),   // <- 来自 Demux
    .Sdr_rd_dout       (Sdr_rd_dout_Demux), // <- 来自 Demux
    .App_wr_en         (App_wr_en_B),       // -> 输出到 Mux
    .App_wr_addr       (App_wr_addr_B),     // -> 输出到 Mux
    .App_wr_din        (App_wr_din_B),      // -> 输出到 Mux
    .App_wr_dm         (App_wr_dm_B),       // -> 输出到 Mux
    .App_rd_en         (App_rd_en_B),       // -> 输出到 Mux
    .App_rd_addr       (App_rd_addr_B),     // -> 输出到 Mux
    .HDMI_CLK_P        (HDMI_CLK_P),
    .HDMI_D2_P         (HDMI_D2_P),
    .HDMI_D1_P         (HDMI_D1_P),
    .HDMI_D0_P         (HDMI_D0_P)
);

// --- 6d. 项目 B 的 UDP 回环模块 ---
wire         loop_app_tx_data_request;
wire         loop_app_tx_data_valid; 
wire [7:0]   loop_app_tx_data;       
wire  [15:0] loop_udp_data_length;

udp_loopback#(
    .DEVICE(DEVICE)
)
 u2_udp_loopback
 (
    .app_rx_clk                 (udp_clk),
    .app_tx_clk                 (udp_clk),
    .reset                      (rst_B_domain), // [!! 修改 !!] 使用源自 app_reset 的域复位
    
    // (仅在 B 模式下回环)
    .app_rx_data                (stack_rx_data),
    .app_rx_data_valid          (stack_rx_data_valid & mode_is_udp_hdmi), 
    .app_rx_data_length         (stack_rx_data_length),
    
    .udp_tx_ready               (udp_tx_ready_Demux),
    .app_tx_ack                 (app_tx_ack_Demux),
    .app_tx_data                (loop_app_tx_data),        // -> 输出到 TX Mux
    .app_tx_data_request        (loop_app_tx_data_request),// -> 输出到 TX Mux
    .app_tx_data_valid          (loop_app_tx_data_valid),  // -> 输出到 TX Mux
    .udp_data_length            (loop_udp_data_length)   // -> 输出到 TX Mux
);


// =============================================================================
// 7. 共享资源例化 (SDRAM, UDP, TEMAC) [!! 已修改 !!]
// =============================================================================

// --- 7a. 共享 SDRAM IP (来自项目 B) ---
sdram u_sdram_ip (
    .Clk            (ext_mem_clk),   // [修改] 共享时钟
    .Clk_sft        (mem_clk_sft),
    .Rst            (sdram_ip_reset),// [!! 修改 !!] 共享复位 (源自 master_reset)
    .Sdr_init_done  (Sdr_init_done),
    .Sdr_init_ref_vld(),
    .Sdr_busy       (Sdr_busy),
    .App_wr_en      (App_wr_en_Mux),       // <- 来自 Mux
    .App_wr_addr    (App_wr_addr_Mux),     // <- 来自 Mux
    .App_wr_dm      (App_wr_dm_Mux),       // <- 来自 Mux
    .App_wr_din     (App_wr_din_Mux),      // <- 来自 Mux
    .App_rd_en      (App_rd_en_Mux),       // <- 来自 Mux
    .App_rd_addr    (App_rd_addr_Mux),     // <- 来自 Mux
    .Sdr_rd_en      (Sdr_rd_en_Demux),     // -> 输出到 Demux
    .Sdr_rd_dout    (Sdr_rd_dout_Demux)  // -> 输出到 Demux
);

// --- 7b. 共享 UDP/IP 协议栈 (来自项目 B) ---
udp_ip_protocol_stack #
(
    .DEVICE                     (DEVICE),
    .LOCAL_UDP_PORT_NUM         (LOCAL_UDP_PORT_B),     // [修改] 使用 B 的
    .LOCAL_IP_ADDRESS           (LOCAL_IP_ADDRESS_B),   // [修改] 使用 B 的
    .LOCAL_MAC_ADDRESS          (LOCAL_MAC_ADDRESS_B)   // [修改] 使用 B 的
)   
u3_udp_ip_protocol_stack    
(   
    .udp_rx_clk                 (udp_clk),
    .udp_tx_clk                 (udp_clk),
    .reset                      (app_reset_high), // [!! 修改 !!] 全局应用复位
    
    // TX (Outputs to App)
    .udp2app_tx_ready           (udp_tx_ready_Demux), // -> 输出到 Demux
    .udp2app_tx_ack             (app_tx_ack_Demux),   // -> 输出到 Demux
    
    // TX (Inputs from App Mux)
    .app_tx_request             (stack_tx_request),       // <- 来自 Mux
    .app_tx_data_valid          (stack_tx_data_valid),    // <- 来自 Mux
    .app_tx_data                (stack_tx_data),          // <- 来自 Mux
    .app_tx_data_length         (stack_tx_data_length),   // <- 来自 Mux
    .app_tx_dst_port            (stack_tx_dst_port),      // <- 来自 Mux
    .ip_tx_dst_address          (stack_tx_dst_ip),        // <- 来自 Mux
    
    .input_local_udp_port_num      (LOCAL_UDP_PORT_B),
    .input_local_udp_port_num_valid(1'b1),
    .input_local_ip_address     (LOCAL_IP_ADDRESS_B),
    .input_local_ip_address_valid(1'b1),
    
    // RX (Outputs to Classifier)
    .app_rx_data_valid          (stack_rx_data_valid), 
    .app_rx_data                (stack_rx_data), 
    .app_rx_data_length         (stack_rx_data_length), // [!! 这是原始长度信号 !!]
    .app_rx_port_num            (stack_rx_port_num), 
    
    // TEMAC Interface
    .temac_rx_ready             (temac_rx_ready),
    .temac_rx_valid             (!temac_rx_valid),
    .temac_rx_data              (temac_rx_data),
    .temac_rx_sof               (temac_rx_sof),
    .temac_rx_eof               (temac_rx_eof),
    .temac_tx_ready             (temac_tx_ready),
    .temac_tx_valid             (temac_tx_valid),
    .temac_tx_data              (temac_tx_data),
    .temac_tx_sof               (temac_tx_sof),
    .temac_tx_eof               (temac_tx_eof)

);

// --- 7c. 共享 TEMAC/RGMII 模块 (来自项目 B) ---
// (TEMAC 配置)
assign  tx_stop    = 1'b0;
assign  tx_ifg_val = 8'h00;
assign  pause_req  = 1'b0;
assign  pause_val  = 16'h0;
assign  pause_source_addr = 48'h5af1f2f3f4f5;
assign  unicast_address   = { LOCAL_MAC_ADDRESS_B[7:0],  LOCAL_MAC_ADDRESS_B[15:8],
                              LOCAL_MAC_ADDRESS_B[23:16], LOCAL_MAC_ADDRESS_B[31:24],
                              LOCAL_MAC_ADDRESS_B[39:32], LOCAL_MAC_ADDRESS_B[47:40] };
assign  mac_cfg_vector    = {1'b0,2'b00,TRI_speed,8'b00000010,7'b0000010};

temac_block#(
    .DEVICE               (DEVICE                   )
) u4_trimac_block
(
    .reset                (app_reset_high), // [!! 修改 !!]
    .gtx_clk              (temac_clk),
    .gtx_clk_90           (temac_clk90),
    .rx_clk               (rx_clk_int),
    .rx_clk_en            (rx_clk_en_int),
    .rx_data              (rx_data),
    .rx_data_valid        (rx_valid),
    .rx_correct_frame     (rx_correct_frame),
    .rx_error_frame       (rx_error_frame),
    .rx_status_vector     (), .rx_status_vld (),
    .tx_clk               (tx_clk_int),
    .tx_clk_en            (tx_clk_en_int),
    .tx_data              (tx_data),
    .tx_data_en           (tx_valid),
    .tx_rdy               (tx_rdy),
    .tx_stop              (tx_stop),
    .tx_collision         (tx_collision),
    .tx_retransmit        (tx_retransmit),
    .tx_ifg_val           (tx_ifg_val),
    .tx_status_vector     (), .tx_status_vld (),
    .pause_req            (pause_req),
    .pause_val            (pause_val),
    .pause_source_addr    (pause_source_addr),
    .unicast_address      (unicast_address),
    .mac_cfg_vector       (mac_cfg_vector),
    .rgmii_txd            (phy1_rgmii_tx_data),
    .rgmii_tx_ctl         (phy1_rgmii_tx_ctl),
    .rgmii_txc            (phy1_rgmii_tx_clk),
    .rgmii_rxd            (phy1_rgmii_rx_data),
    .rgmii_rx_ctl         (phy1_rgmii_rx_ctl),
    .rgmii_rxc            (phy1_rgmii_rx_clk_90), // [修改] 使用 A 的 PLL 输出
    .inband_link_status   (), .inband_clock_speed (), .inband_duplex_status ()
);

// --- 7d. 共享 TEMAC FIFOs (来自项目 B) ---
tx_client_fifo#( .DEVICE(DEVICE) )
u6_tx_fifo
(
    .rd_clk               (tx_clk_int),
    .rd_sreset            (app_reset_high), // [!! 修改 !!]
    .rd_enable            (tx_clk_en_int),
    .tx_data              (tx_data),
    .tx_data_valid        (tx_valid),
    .tx_ack               (tx_rdy),
    .tx_collision         (tx_collision),
    .tx_retransmit        (tx_retransmit),
    .overflow             (),
    .wr_clk               (udp_clk),
    .wr_sreset            (app_reset_high), // [!! 修改 !!]
    .wr_data              (temac_tx_data),
    .wr_sof_n             (temac_tx_sof),
    .wr_eof_n             (temac_tx_eof),
    .wr_src_rdy_n         (temac_tx_valid),
    .wr_dst_rdy_n         (temac_tx_ready),
    .wr_fifo_status       ()
);

rx_client_fifo#( .DEVICE(DEVICE) )
u7_rx_fifo                  
(                           
    .wr_clk               (rx_clk_int),
    .wr_enable            (rx_clk_en_int),
    .wr_sreset            (app_reset_high), // [!! 修改 !!]
    .rx_data              (rx_data),
    .rx_data_valid        (rx_valid),
    .rx_good_frame        (rx_correct_frame),
    .rx_bad_frame         (rx_error_frame),
    .overflow             (),
    .rd_clk               (udp_clk),
    .rd_sreset            (app_reset_high), // [!! 修改 !!]
    .rd_data_out          (temac_rx_data),
    .rd_sof_n             (temac_rx_sof),
    .rd_eof_n             (temac_rx_eof),
    .rd_src_rdy_n         (temac_rx_valid),
    .rd_dst_rdy_n         (temac_rx_ready),
    .rx_fifo_status       ()
);

// =============================================================================
// 8. 仲裁逻辑 (MUX) (核心)
// =============================================================================
// ... (此部分保持不变) ...
// --- 8a. SDRAM 仲裁器 ---
// (模式 B 优先，否则连接模式 A)
assign App_wr_en_Mux   = mode_is_udp_hdmi ? App_wr_en_B   : App_wr_en_A;
assign App_wr_addr_Mux = mode_is_udp_hdmi ? App_wr_addr_B : App_wr_addr_A;
assign App_wr_din_Mux  = mode_is_udp_hdmi ? App_wr_din_B  : App_wr_din_A;
assign App_wr_dm_Mux   = mode_is_udp_hdmi ? App_wr_dm_B   : App_wr_dm_A;

assign App_rd_en_Mux   = mode_is_udp_hdmi ? App_rd_en_B   : App_rd_en_A;
assign App_rd_addr_Mux = mode_is_udp_hdmi ? App_rd_addr_B : App_rd_addr_A;
// (读数据和使能信号被广播到两个模块，见 7a)


// --- 8b. UDP TX 仲裁器 ---
// (根据模式选择哪个模块可以向 UDP 堆栈发送数据)
assign stack_tx_request = mode_is_tf_udp   ? tf_app_tx_data_request :
                          mode_is_cam_udp  ? cam_app_tx_data_request :
                          mode_is_udp_hdmi ? loop_app_tx_data_request :
                          1'b0; // 默认关闭

assign stack_tx_data_valid = mode_is_tf_udp   ? tf_app_tx_data_valid :
                             mode_is_cam_udp  ? cam_app_tx_data_valid :
                             mode_is_udp_hdmi ? loop_app_tx_data_valid :
                             1'b0; // 默认关闭

assign stack_tx_data = mode_is_tf_udp   ? tf_app_tx_data :
                       mode_is_cam_udp  ? cam_app_tx_data :
                       mode_is_udp_hdmi ? loop_app_tx_data :
                       8'h00; // 默认关闭

assign stack_tx_data_length = mode_is_tf_udp   ? tf_udp_data_length :
                              mode_is_cam_udp  ? cam_udp_data_length :
                              mode_is_udp_hdmi ? loop_udp_data_length :
                              16'h00; // 默认关闭

// (选择目标 IP 和端口)
assign stack_tx_dst_port = mode_is_tf_udp   ? DST_UDP_PORT_SD :
                           mode_is_cam_udp  ? DST_UDP_PORT_CAM :
                           mode_is_udp_hdmi ? DST_UDP_PORT_B :
                           16'h0;

assign stack_tx_dst_ip = mode_is_tf_udp   ? DST_IP_ADDRESS_A :
                         mode_is_cam_udp  ? DST_IP_ADDRESS_A :
                         mode_is_udp_hdmi ? DST_IP_ADDRESS_B :
                         32'h0;



endmodule