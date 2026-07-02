dummy
`timescale 1ns / 1ps
// =============================================================================
// top_merged_udp
// 三合一顶层：LED/HDMI UDP 接收 + OV5640 摄像头 UDP 上传 + TF 卡图片 UDP 上传
// 模式选择：mode_sw[1:0]
//   2'b00 -> LED/HDMI 显示（PC 发送数据包，根据包长区分 LED 与 HDMI）
//   2'b01 -> 摄像头实时图像上传
//   2'b10 -> TF 卡图片上传
//   2'b11 -> 备用（默认回落为 LED/HDMI）
// 按键：key1 全局复位；key2/3/4 沿用原摄像头/TF 工程定义
// 乒乓拨码开关高电平为 1，低电平为 0，未做消抖
// =============================================================================
module top_merged_udp(
    input        clk_50,
    input        key1,
    input  [1:0] mode_sw,
    input        key2,
    input        key3,
    input        key4,

    // ===== SD 卡 =====
    output       sd_ncs,
    output       sd_dclk,
    output       sd_mosi,
    input        sd_miso,

    // ===== 七段数码管 =====
    output [5:0] seg_sel,
    output [7:0] seg_data,

    // ===== 以太网 RGMII =====
    input        phy1_rgmii_rx_clk,
    input        phy1_rgmii_rx_ctl,
    input  [3:0] phy1_rgmii_rx_data,
    output       phy1_rgmii_tx_clk,
    output       phy1_rgmii_tx_ctl,
    output [3:0] phy1_rgmii_tx_data,

    // ===== 摄像头接口 =====
    input        cam_pclk,
    input        cam_vsync,
    input        cam_href,
    input  [7:0] cam_data,
    output       cam_rst_n,
    output       cam_pwdn,
    output       cam_scl,
    inout        cam_sda,

    // ===== HDMI & LED =====
    output       HDMI_CLK_P,
    output       HDMI_D2_P,
    output       HDMI_D1_P,
    output       HDMI_D0_P,
    output [3:0] led_data,
    output [15:0] dled,

    // ===== SDRAM =====
    output       sdram_clk
);

// ----------------------------------------------------------------------
// 全局常量
// ----------------------------------------------------------------------
localparam MEM_DATA_BITS      = 32;
localparam ADDR_BITS          = 21;
localparam BURST_BITS         = 10;

localparam DEVICE             = "EG4";
localparam LOCAL_UDP_PORT_NUM = 16'h1770;
localparam LOCAL_IP_ADDRESS   = 32'hc0a8_f001;
localparam LOCAL_MAC_ADDRESS  = 48'h01_23_45_67_89_ab;
localparam DST_UDP_PORT_SD    = 16'h1773;
localparam DST_UDP_PORT_CAM   = 16'h1773;
localparam DST_IP_ADDRESS     = 32'hc0a8_f002;

// CMOS 分辨率
localparam V_CMOS_DISP        = 11'd480;
localparam H_CMOS_DISP        = 11'd640;
localparam TOTAL_H_PIXEL      = H_CMOS_DISP + 12'd1216;
localparam TOTAL_V_PIXEL      = V_CMOS_DISP + 12'd504;

// 模式编码
localparam MODE_LED    = 2'b00;
localparam MODE_CAMERA = 2'b01;
localparam MODE_TF     = 2'b10;

// LED/HDMI UDP 分类参数
localparam LED_PAYLOAD_MAX_BYTES  = 16'd3;
localparam HDMI_PAYLOAD_MIN_BYTES = LED_PAYLOAD_MAX_BYTES + 16'd1;
localparam [15:0] LED_REMOTE_PORT_NUM  = 16'hFFFF;
localparam [15:0] HDMI_REMOTE_PORT_NUM = 16'hFFFF;
localparam [15:0] FRAME_IDLE_TIMEOUT   = 16'd8192;

// 模式切换后各时钟域等待的刷新周期
localparam MODE_RST_CYCLES = 12'd2048;

// ----------------------------------------------------------------------
// 模式解码
// ----------------------------------------------------------------------
wire rst_n = key1;               // 板载 KEY1 松开=1，按下=0
wire [1:0] mode_sel = (mode_sw == 2'b11) ? MODE_LED : mode_sw;
wire mode_led_sel    = (mode_sel == MODE_LED);
wire mode_camera_sel = (mode_sel == MODE_CAMERA);
wire mode_tf_sel     = (mode_sel == MODE_TF);

// ----------------------------------------------------------------------
// 时钟/复位网络
// ----------------------------------------------------------------------
wire sd_card_clk;
wire ext_mem_clk;
wire ext_mem_clk_sft;

sys_pll u_sys_pll (
    .refclk (clk_50),
    .reset  (~rst_n),
    .clk0_out(sd_card_clk),
    .clk1_out(ext_mem_clk),
    .clk2_out(ext_mem_clk_sft)
);

assign sdram_clk = ext_mem_clk;

wire temac_clk;
wire clk_125_out;
wire temac_clk90;
wire clk_12_5_out;
wire clk_1_25_out;
wire clk_25_out;
wire reset_reg;

clk_gen_rst_gen #(
    .DEVICE (DEVICE)
) u_clk_gen (
    .reset        (~rst_n),
    .clk_in       (clk_50),
    .rst_out      (reset_reg),
    .clk_125_out0 (temac_clk),
    .clk_125_out1 (clk_125_out),
    .clk_125_out2 (temac_clk90),
    .clk_12_5_out (clk_12_5_out),
    .clk_1_25_out (clk_1_25_out),
    .clk_25_out   (clk_25_out)
);

wire udp_clk;
wire [1:0] TRI_speed = 2'b10; // 2'b10 = 千兆
udp_clk_gen #(
    .DEVICE (DEVICE)
) u_udp_clk_gen (
    .reset      (~rst_n),
    .tri_speed  (TRI_speed),
    .clk_125_in (clk_125_out),
    .clk_12_5_in(clk_12_5_out),
    .clk_1_25_in(clk_1_25_out),
    .udp_clk_out(udp_clk)
);

wire phy1_rgmii_rx_clk_0;
wire phy1_rgmii_rx_clk_90;
rx_pll u_rx_pll (
    .refclk   (phy1_rgmii_rx_clk),
    .reset    (1'b0),
    .clk0_out (phy1_rgmii_rx_clk_0),
    .clk1_out (phy1_rgmii_rx_clk_90),
    .clk2_out (/* open */)
);

wire video_pll_lock;
wire video_pll_clk0_unused;
wire video_pll_clk1_unused;
wire video_clk;
wire video_clk_5x;
video_pll u_video_pll (
    .refclk  (clk_50),
    .reset   (~rst_n),
    .extlock (video_pll_lock),
    .clk0_out(video_pll_clk0_unused),
    .clk1_out(video_pll_clk1_unused),
    .clk2_out(video_clk),
    .clk3_out(video_clk_5x)
);

wire reset = ~rst_n || reset_reg;

// ----------------------------------------------------------------------
// 模式变化同步到 ext_mem_clk 与 udp_clk
// ----------------------------------------------------------------------
reg [1:0] mode_mem_ff0, mode_mem_ff1;
reg [11:0] mode_mem_rst_cnt;
always @(posedge ext_mem_clk or negedge rst_n) begin
    if(!rst_n) begin
        mode_mem_ff0      <= MODE_LED;
        mode_mem_ff1      <= MODE_LED;
        mode_mem_rst_cnt  <= MODE_RST_CYCLES;
    end else begin
        mode_mem_ff0 <= mode_sel;
        mode_mem_ff1 <= mode_mem_ff0;
        if(mode_mem_ff0 != mode_mem_ff1)
            mode_mem_rst_cnt <= MODE_RST_CYCLES;
        else if(mode_mem_rst_cnt != 12'd0)
            mode_mem_rst_cnt <= mode_mem_rst_cnt - 12'd1;
    end
end
wire mode_recfg_mem = (mode_mem_rst_cnt != 12'd0);
wire mem_mode_led    = (mode_mem_ff1 == MODE_LED);
wire mem_mode_camera = (mode_mem_ff1 == MODE_CAMERA);
wire mem_mode_tf     = (mode_mem_ff1 == MODE_TF);

reg [1:0] mode_udp_ff0, mode_udp_ff1;
reg [11:0] mode_udp_rst_cnt;
always @(posedge udp_clk or negedge rst_n) begin
    if(!rst_n) begin
        mode_udp_ff0      <= MODE_LED;
        mode_udp_ff1      <= MODE_LED;
        mode_udp_rst_cnt  <= MODE_RST_CYCLES;
    end else begin
        mode_udp_ff0 <= mode_sel;
        mode_udp_ff1 <= mode_udp_ff0;
        if(mode_udp_ff0 != mode_udp_ff1)
            mode_udp_rst_cnt <= MODE_RST_CYCLES;
        else if(mode_udp_rst_cnt != 12'd0)
            mode_udp_rst_cnt <= mode_udp_rst_cnt - 12'd1;
    end
end
wire mode_recfg_udp = (mode_udp_rst_cnt != 12'd0);
wire udp_mode_led    = (mode_udp_ff1 == MODE_LED);
wire udp_mode_camera = (mode_udp_ff1 == MODE_CAMERA);
wire udp_mode_tf     = (mode_udp_ff1 == MODE_TF);

// ----------------------------------------------------------------------
// SDRAM 接口公共信号
// ----------------------------------------------------------------------
wire                    Sdr_init_done;
wire                    Sdr_init_ref_vld;
wire                    Sdr_busy;
wire                    App_wr_en_mux;
wire [ADDR_BITS-1:0]    App_wr_addr_mux;
wire [MEM_DATA_BITS-1:0]App_wr_din_mux;
wire [3:0]              App_wr_dm_mux;
wire                    App_rd_en_mux;
wire [ADDR_BITS-1:0]    App_rd_addr_mux;
wire                    Sdr_rd_en;
wire [MEM_DATA_BITS-1:0]Sdr_rd_dout;

// ----------------------------------------------------------------------
// LED/HDMI UDP RX 分类逻辑
// ----------------------------------------------------------------------
wire app_rx_data_valid;
wire [7:0]  app_rx_data;
wire [15:0] app_rx_data_length;
wire [15:0] app_rx_port_num;

localparam [1:0] FRAME_MODE_DROP = 2'b00;
localparam [1:0] FRAME_MODE_LED  = 2'b01;
localparam [1:0] FRAME_MODE_HDMI = 2'b10;

reg        frame_active;
reg [1:0]  frame_mode;
reg [15:0] bytes_remaining;
reg [15:0] frame_idle_cnt;

wire led_port_match  = (LED_REMOTE_PORT_NUM  == 16'hFFFF) ? 1'b1 : (app_rx_port_num == LED_REMOTE_PORT_NUM);
wire hdmi_port_match = (HDMI_REMOTE_PORT_NUM == 16'hFFFF) ? 1'b1 : (app_rx_port_num == HDMI_REMOTE_PORT_NUM);
wire led_length_ok   = (app_rx_data_length != 16'd0) && (app_rx_data_length <= LED_PAYLOAD_MAX_BYTES);
wire hdmi_length_ok  = (app_rx_data_length >= HDMI_PAYLOAD_MIN_BYTES);
wire led_candidate   = led_port_match  && led_length_ok;
wire hdmi_candidate  = hdmi_port_match && hdmi_length_ok;

wire [1:0] frame_mode_next = led_candidate  ? FRAME_MODE_LED  :
                             hdmi_candidate ? FRAME_MODE_HDMI :
                                              FRAME_MODE_DROP;
wire frame_start = udp_mode_led && app_rx_data_valid && !frame_active;

wire processing_led  = udp_mode_led && app_rx_data_valid &&
                       (frame_active ? (frame_mode == FRAME_MODE_LED) :
                                       (frame_start && frame_mode_next == FRAME_MODE_LED));
wire processing_hdmi = udp_mode_led && app_rx_data_valid &&
                       (frame_active ? (frame_mode == FRAME_MODE_HDMI) :
                                       (frame_start && frame_mode_next == FRAME_MODE_HDMI));

always @(posedge udp_clk or negedge rst_n) begin
    if(!rst_n) begin
        frame_active      <= 1'b0;
        frame_mode        <= FRAME_MODE_DROP;
        bytes_remaining   <= 16'd0;
        frame_idle_cnt    <= 16'd0;
    end else if(!udp_mode_led || mode_recfg_udp) begin
        frame_active      <= 1'b0;
        frame_mode        <= FRAME_MODE_DROP;
        bytes_remaining   <= 16'd0;
        frame_idle_cnt    <= 16'd0;
    end else begin
        if(frame_start) begin
            frame_mode      <= frame_mode_next;
            frame_idle_cnt  <= 16'd0;
            if(app_rx_data_length <= 16'd1) begin
                frame_active    <= 1'b0;
                bytes_remaining <= 16'd0;
            end else begin
                frame_active    <= 1'b1;
                bytes_remaining <= app_rx_data_length - 16'd1;
            end
        end else if(frame_active) begin
            if(app_rx_data_valid) begin
                frame_idle_cnt <= 16'd0;
                if(bytes_remaining <= 16'd1) begin
                    frame_active    <= 1'b0;
                    bytes_remaining <= 16'd0;
                end else begin
                    bytes_remaining <= bytes_remaining - 16'd1;
                end
            end else if(frame_idle_cnt >= FRAME_IDLE_TIMEOUT) begin
                frame_active   <= 1'b0;
                frame_idle_cnt <= 16'd0;
            end else begin
                frame_idle_cnt <= frame_idle_cnt + 16'd1;
            end
        end else begin
            if(frame_idle_cnt != 16'd0)
                frame_idle_cnt <= frame_idle_cnt - 16'd1;
        end
    end
end

wire app_rx_data_valid_led  = processing_led;
wire app_rx_data_valid_hdmi = processing_hdmi;

// ----------------------------------------------------------------------
// LED 模块
// ----------------------------------------------------------------------
wire led_reset_n = rst_n & udp_mode_led & ~mode_recfg_udp;
wire [3:0]  led_data_raw;
wire [15:0] dled_raw;

led u_led (
    .app_rx_data_valid(app_rx_data_valid_led),
    .app_rx_data      (app_rx_data),
    .app_rx_data_length(app_rx_data_length),
    .udp_rx_clk       (udp_clk),
    .reset            (led_reset_n),
    .led              (),
    .led_data_1       (led_data_raw),
    .dled             (dled_raw)
);

assign led_data = udp_mode_led ? led_data_raw : 4'h0;
assign dled     = udp_mode_led ? dled_raw     : 16'h0000;

// ----------------------------------------------------------------------
// HDMI 子系统（app 模块）
// ----------------------------------------------------------------------
wire app_led_reset = (~rst_n) | mode_recfg_mem | mode_recfg_udp | (~udp_mode_led);
wire app_wr_en_led;
wire [ADDR_BITS-1:0] app_wr_addr_led;
wire [MEM_DATA_BITS-1:0] app_wr_din_led;
wire [3:0] app_wr_dm_led;
wire app_rd_en_led;
wire [ADDR_BITS-1:0] app_rd_addr_led;

app u_app_hdmi (
    .udp_clk           (udp_clk),
    .mem_clk           (ext_mem_clk),
    .mem_clk_sft       (ext_mem_clk_sft),
    .video_clk         (video_clk),
    .video_clk_5x      (video_clk_5x),
    .reset             (app_led_reset),
    .app_rx_data_valid (app_rx_data_valid_hdmi),
    .app_rx_data       (app_rx_data),
    .Sdr_init_done     (Sdr_init_done),
    .App_wr_en         (app_wr_en_led),
    .App_wr_addr       (app_wr_addr_led),
    .App_wr_din        (app_wr_din_led),
    .App_wr_dm         (app_wr_dm_led),
    .App_rd_en         (app_rd_en_led),
    .App_rd_addr       (app_rd_addr_led),
    .Sdr_rd_en         (Sdr_rd_en),
    .Sdr_rd_dout       (Sdr_rd_dout),
    .HDMI_CLK_P        (HDMI_CLK_P),
    .HDMI_D2_P         (HDMI_D2_P),
    .HDMI_D1_P         (HDMI_D1_P),
    .HDMI_D0_P         (HDMI_D0_P)
);

// ----------------------------------------------------------------------
// 摄像头采集 & 写 SDRAM
// ----------------------------------------------------------------------
wire cam_rst_gate = rst_n & mem_mode_camera & ~mode_recfg_mem;
wire cam_rst_n_int;
wire cam_pwdn_int;
wire cam_scl_int;
wire cam_init_done;

wire        cam_write_req;
wire        cam_write_req_ack;
wire        cam_write_en;
wire [31:0] cam_write_data;

wire        cam_read_req;
wire        cam_read_req_ack;
wire        cam_read_en;

ov5640_dri u_ov5640_dri(
    .clk                (clk_50),
    .rst_n              (cam_rst_gate),
    .cam_pclk           (cam_pclk),
    .cam_vsync          (cam_vsync),
    .cam_href           (cam_href),
    .cam_data           (cam_data),
    .cam_rst_n          (cam_rst_n_int),
    .cam_pwdn           (cam_pwdn_int),
    .cam_scl            (cam_scl_int),
    .cam_sda            (cam_sda),
    .cmos_h_pixel       (H_CMOS_DISP),
    .cmos_v_pixel       (V_CMOS_DISP),
    .capture_start      (Sdr_init_done),
    .cmos_frame_vsync   (),
    .cmos_frame_href    (),
    .cmos_frame_valid   (),
    .cmos_wr_data       ()
);

wire cmos_frame_vsync;
wire cmos_frame_href;
wire cmos_frame_valid;
wire [15:0] cmos_wr_data;

ov5640_delay u_ov5640_delay(
    .clk                (cam_pclk),
    .rst_n              (cam_rst_gate),
    .cmos_frame_vsync   (cmos_frame_vsync),
    .cmos_frame_href    (cmos_frame_href),
    .cmos_frame_valid   (cmos_frame_valid),
    .cmos_wr_data       (cmos_wr_data),
    .cam_write_en       (cam_write_en),
    .cam_write_data     (cam_write_data),
    .cam_write_req      (cam_write_req),
    .cam_write_req_ack  (cam_write_req_ack)
);

assign cam_rst_n = cam_rst_gate ? cam_rst_n_int : 1'b0;
assign cam_pwdn  = cam_rst_gate ? cam_pwdn_int  : 1'b1;
assign cam_scl   = cam_rst_gate ? cam_scl_int   : 1'b1;

// ----------------------------------------------------------------------
// TF 卡读取 & 写 SDRAM
// ----------------------------------------------------------------------
wire [3:0]  sd_state_code;
wire [6:0]  seg_code_tf;
wire        sd_write_req;
wire        sd_write_req_ack;
wire        sd_write_en;
wire [31:0] sd_write_data;

wire sd_rst = (~rst_n) | mode_recfg_mem | (~mem_mode_tf);

sd_card_bmp u_sd_card_bmp(
    .clk            (sd_card_clk),
    .rst            (sd_rst),
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

seg_decoder u_seg_decoder(
    .bin_data (sd_state_code),
    .seg_data (seg_code_tf)
);

// ----------------------------------------------------------------------
// 摄像头/TF 从 SDRAM 读出，经 UDP 发送
// ----------------------------------------------------------------------
wire udp_tx_ready;
wire app_tx_ack;
wire app_tx_data_request_cam;
wire app_tx_data_valid_cam;
wire [7:0] app_tx_data_cam;
wire [15:0] udp_data_length_cam;

wire app_tx_data_request_tf;
wire app_tx_data_valid_tf;
wire [7:0] app_tx_data_tf;
wire [15:0] udp_data_length_tf;

wire cam_read_en_int;
wire [31:0] frame_read_data;

udp_cam_ctrl_cam u_udp_cam_ctrl_cam(
    .clk                 (udp_clk),
    .rst_n               (rst_n & Sdr_init_done & udp_mode_camera & ~mode_recfg_udp),
    .key4                (key4 & udp_mode_camera),
    .key3                (key3 & udp_mode_camera),
    .read_req            (cam_read_req),
    .read_req_ack        (cam_read_req_ack),
    .read_en             (cam_read_en),
    .read_data           (frame_read_data),
    .udp_tx_ready        (udp_tx_ready),
    .app_tx_ack          (app_tx_ack),
    .app_tx_data_request (app_tx_data_request_cam),
    .app_tx_data_valid   (app_tx_data_valid_cam),
    .app_tx_data         (app_tx_data_cam),
    .udp_data_length     (udp_data_length_cam)
);

udp_cam_ctrl_tf u_udp_cam_ctrl_tf(
    .clk                 (udp_clk),
    .rst_n               (rst_n & Sdr_init_done & udp_mode_tf & ~mode_recfg_udp),
    .read_req            (tf_read_req),
    .read_req_ack        (tf_read_req_ack),
    .read_en             (tf_read_en),
    .read_data           (frame_read_data),
    .udp_tx_ready        (udp_tx_ready),
    .app_tx_ack          (app_tx_ack),
    .app_tx_data_request (app_tx_data_request_tf),
    .app_tx_data_valid   (app_tx_data_valid_tf),
    .app_tx_data         (app_tx_data_tf),
    .udp_data_length     (udp_data_length_tf)
);

wire app_tx_data_request = udp_mode_camera ? app_tx_data_request_cam :
                           udp_mode_tf     ? app_tx_data_request_tf  :
                                              1'b0;
wire app_tx_data_valid   = udp_mode_camera ? app_tx_data_valid_cam   :
                           udp_mode_tf     ? app_tx_data_valid_tf    :
                                              1'b0;
wire [7:0] app_tx_data   = udp_mode_camera ? app_tx_data_cam :
                           udp_mode_tf     ? app_tx_data_tf  :
                                             8'h00;
wire [15:0] udp_data_length = udp_mode_camera ? udp_data_length_cam :
                              udp_mode_tf     ? udp_data_length_tf  :
                                                16'd0;

// ----------------------------------------------------------------------
// frame_read_write：摄像头/TF 写入 + UDP 读取
// ----------------------------------------------------------------------
wire write_req_sel = mem_mode_camera ? cam_write_req :
                     mem_mode_tf     ? sd_write_req  : 1'b0;
wire write_en_sel  = mem_mode_camera ? cam_write_en :
                     mem_mode_tf     ? sd_write_en  : 1'b0;
wire [31:0] write_data_sel = mem_mode_camera ? cam_write_data :
                             mem_mode_tf     ? sd_write_data : 32'd0;
wire write_clk_sel = mem_mode_camera ? cam_pclk :
                     mem_mode_tf     ? sd_card_clk :
                     cam_pclk;

wire frame_write_req_ack;
assign cam_write_req_ack = mem_mode_camera ? frame_write_req_ack : 1'b0;
assign sd_write_req_ack  = mem_mode_tf     ? frame_write_req_ack : 1'b0;

wire video_read_req;
wire video_read_req_ack;
wire video_read_en;

assign video_read_req = udp_mode_camera ? cam_read_req :
                        udp_mode_tf     ? tf_read_req  : 1'b0;
assign video_read_en  = udp_mode_camera ? cam_read_en  :
                        udp_mode_tf     ? tf_read_en   : 1'b0;
assign cam_read_req_ack = udp_mode_camera ? video_read_req_ack : 1'b0;
assign tf_read_req_ack  = udp_mode_tf     ? video_read_req_ack : 1'b0;

wire frame_rw_rst = (~rst_n) | mode_recfg_mem | mem_mode_led;

frame_read_write #(
    .MEM_DATA_BITS  (MEM_DATA_BITS),
    .READ_DATA_BITS (MEM_DATA_BITS),
    .WRITE_DATA_BITS(MEM_DATA_BITS),
    .ADDR_BITS      (ADDR_BITS),
    .BURST_BITS     (BURST_BITS)
) u_frame_read_write (
    .rst              (frame_rw_rst),
    .mem_clk          (ext_mem_clk),
    .Sdr_init_done    (Sdr_init_done),
    .Sdr_init_ref_vld (Sdr_init_ref_vld),
    .Sdr_busy         (Sdr_busy),
    .App_rd_en        (app_rd_en_camtf),
    .App_rd_addr      (app_rd_addr_camtf),
    .Sdr_rd_en        (Sdr_rd_en),
    .Sdr_rd_dout      (Sdr_rd_dout),
    .read_clk         (udp_clk),
    .read_req         (video_read_req),
    .read_req_ack     (video_read_req_ack),
    .read_finish      (),
    .read_addr_0      (21'd0),
    .read_addr_1      (21'd0),
    .read_addr_2      (21'd0),
    .read_addr_3      (21'd0),
    .read_addr_index  (2'd0),
    .read_len         (21'd307200),
    .read_en          (video_read_en),
    .read_data        (frame_read_data),
    .App_wr_en        (app_wr_en_camtf),
    .App_wr_addr      (app_wr_addr_camtf),
    .App_wr_din       (app_wr_din_camtf),
    .App_wr_dm        (app_wr_dm_camtf),
    .write_clk        (write_clk_sel),
    .write_req        (write_req_sel),
    .write_req_ack    (frame_write_req_ack),
    .write_finish     (),
    .write_addr_0     (21'd0),
    .write_addr_1     (21'd0),
    .write_addr_2     (21'd0),
    .write_addr_3     (21'd0),
    .write_addr_index (2'd0),
    .write_len        (21'd307200),
    .write_en         (write_en_sel),
    .write_data       (write_data_sel)
);

// ----------------------------------------------------------------------
// SDRAM 实例（LED/HDMI 与摄像头/TF 多路复用）
// ----------------------------------------------------------------------
wire                    app_wr_en_camtf;
wire [ADDR_BITS-1:0]    app_wr_addr_camtf;
wire [MEM_DATA_BITS-1:0]app_wr_din_camtf;
wire [3:0]              app_wr_dm_camtf;
wire                    app_rd_en_camtf;
wire [ADDR_BITS-1:0]    app_rd_addr_camtf;

wire                    App_wr_en_mux = mem_mode_led ? app_wr_en_led  : app_wr_en_camtf;
wire [ADDR_BITS-1:0]    App_wr_addr_mux = mem_mode_led ? app_wr_addr_led : app_wr_addr_camtf;
wire [MEM_DATA_BITS-1:0]App_wr_din_mux  = mem_mode_led ? app_wr_din_led  : app_wr_din_camtf;
wire [3:0]              App_wr_dm_mux   = mem_mode_led ? app_wr_dm_led   : app_wr_dm_camtf;
wire                    App_rd_en_mux   = mem_mode_led ? app_rd_en_led   : app_rd_en_camtf;
wire [ADDR_BITS-1:0]    App_rd_addr_mux = mem_mode_led ? app_rd_addr_led : app_rd_addr_camtf;

sdram u_sdram (
    .Clk            (ext_mem_clk),
    .Clk_sft        (ext_mem_clk_sft),
    .Rst            (reset | mode_recfg_mem),
    .Sdr_init_done  (Sdr_init_done),
    .Sdr_init_ref_vld(Sdr_init_ref_vld),
    .Sdr_busy       (Sdr_busy),
    .App_wr_en      (App_wr_en_mux),
    .App_wr_addr    (App_wr_addr_mux),
    .App_wr_dm      (App_wr_dm_mux),
    .App_wr_din     (App_wr_din_mux),
    .App_rd_en      (App_rd_en_mux),
    .App_rd_addr    (App_rd_addr_mux),
    .Sdr_rd_en      (Sdr_rd_en),
    .Sdr_rd_dout    (Sdr_rd_dout)
);

// ----------------------------------------------------------------------
// 七段数码管显示
// ----------------------------------------------------------------------
wire [7:0] seg_digit0_led = 8'b1100_1111; // 显示 L
wire [7:0] seg_digit0_cam = 8'hff;        // 全灭
wire [7:0] seg_digit0_tf  = {1'b1, seg_code_tf};

wire [7:0] seg_digit0 = mem_mode_tf     ? seg_digit0_tf  :
                        mem_mode_camera ? seg_digit0_cam :
                        mem_mode_led    ? seg_digit0_led :
                        8'hff;

seg_scan u_seg_scan (
    .clk        (clk_50),
    .rst_n      (rst_n),
    .seg_sel    (seg_sel),
    .seg_data   (seg_data),
    .seg_data_0 (seg_digit0),
    .seg_data_1 (8'hff),
    .seg_data_2 (8'hff),
    .seg_data_3 (8'hff),
    .seg_data_4 (8'hff),
    .seg_data_5 (8'hff)
);

// ----------------------------------------------------------------------
// UDP/IP 协议栈 & TEMAC
// ----------------------------------------------------------------------
wire temac_tx_ready;
wire temac_tx_valid;
wire [7:0] temac_tx_data;
wire temac_tx_sof;
wire temac_tx_eof;

wire temac_rx_ready;
wire temac_rx_valid;
wire [7:0] temac_rx_data;
wire temac_rx_sof;
wire temac_rx_eof;

wire rx_clk_int;
wire rx_clk_en_int;
wire tx_clk_int;
wire tx_clk_en_int;
wire [7:0] rx_data;
wire rx_valid;
wire [7:0] tx_data;
wire tx_valid;
wire tx_rdy;
wire tx_collision;
wire tx_retransmit;
wire rx_correct_frame;
wire rx_error_frame;
wire tx_stop = 1'b0;
wire [7:0] tx_ifg_val = 8'h00;
wire pause_req = 1'b0;
wire [15:0] pause_val = 16'h0000;
wire [47:0] pause_source_addr = 48'h5af1_f2f3_f4f5;
wire [47:0] unicast_address = {
    LOCAL_MAC_ADDRESS[7:0],
    LOCAL_MAC_ADDRESS[15:8],
    LOCAL_MAC_ADDRESS[23:16],
    LOCAL_MAC_ADDRESS[31:24],
    LOCAL_MAC_ADDRESS[39:32],
    LOCAL_MAC_ADDRESS[47:40]
};
wire [19:0] mac_cfg_vector = {1'b0, 2'b00, TRI_speed, 8'b0000_0010, 7'b000_0010};

wire [15:0] dst_udp_port = udp_mode_camera ? DST_UDP_PORT_CAM : DST_UDP_PORT_SD;

udp_ip_protocol_stack #(
    .DEVICE             (DEVICE),
    .LOCAL_UDP_PORT_NUM (LOCAL_UDP_PORT_NUM),
    .LOCAL_IP_ADDRESS   (LOCAL_IP_ADDRESS),
    .LOCAL_MAC_ADDRESS  (LOCAL_MAC_ADDRESS)
) u_udp_stack (
    .udp_rx_clk                 (udp_clk),
    .udp_tx_clk                 (udp_clk),
    .reset                      (reset),
    .udp2app_tx_ready           (udp_tx_ready),
    .udp2app_tx_ack             (app_tx_ack),
    .app_tx_request             (app_tx_data_request),
    .app_tx_data_valid          (app_tx_data_valid),
    .app_tx_data                (app_tx_data),
    .app_tx_data_length         (udp_data_length),
    .app_tx_dst_port            (dst_udp_port),
    .ip_tx_dst_address          (DST_IP_ADDRESS),
    .input_local_udp_port_num   (LOCAL_UDP_PORT_NUM),
    .input_local_udp_port_num_valid(1'b0),
    .input_local_ip_address     (LOCAL_IP_ADDRESS),
    .input_local_ip_address_valid(1'b0),
    .app_rx_data_valid          (app_rx_data_valid),
    .app_rx_data                (app_rx_data),
    .app_rx_data_length         (app_rx_data_length),
    .app_rx_port_num            (app_rx_port_num),
    .temac_rx_ready             (temac_rx_ready),
    .temac_rx_valid             (!temac_rx_valid),
    .temac_rx_data              (temac_rx_data),
    .temac_rx_sof               (temac_rx_sof),
    .temac_rx_eof               (temac_rx_eof),
    .temac_tx_ready             (temac_tx_ready),
    .temac_tx_valid             (temac_tx_valid),
    .temac_tx_data              (temac_tx_data),
    .temac_tx_sof               (temac_tx_sof),
    .temac_tx_eof               (temac_tx_eof),
    .ip_rx_error                (),
    .arp_request_no_reply_error ()
);

temac_block #(
    .DEVICE (DEVICE)
) u_temac (
    .reset              (reset),
    .gtx_clk            (clk_125_out),
    .gtx_clk_90         (temac_clk90),
    .rx_clk             (rx_clk_int),
    .rx_clk_en          (rx_clk_en_int),
    .rx_data            (rx_data),
    .rx_data_valid      (rx_valid),
    .rx_correct_frame   (rx_correct_frame),
    .rx_error_frame     (rx_error_frame),
    .rx_status_vector   (),
    .rx_status_vld      (),
    .tx_clk             (tx_clk_int),
    .tx_clk_en          (tx_clk_en_int),
    .tx_data            (tx_data),
    .tx_data_en         (tx_valid),
    .tx_rdy             (tx_rdy),
    .tx_stop            (tx_stop),
    .tx_collision       (tx_collision),
    .tx_retransmit      (tx_retransmit),
    .tx_ifg_val         (tx_ifg_val),
    .tx_status_vector   (),
    .tx_status_vld      (),
    .pause_req          (pause_req),
    .pause_val          (pause_val),
    .pause_source_addr  (pause_source_addr),
    .unicast_address    (unicast_address),
    .mac_cfg_vector     (mac_cfg_vector),
    .rgmii_txd          (phy1_rgmii_tx_data),
    .rgmii_tx_ctl       (phy1_rgmii_tx_ctl),
    .rgmii_txc          (phy1_rgmii_tx_clk),
    .rgmii_rxd          (phy1_rgmii_rx_data),
    .rgmii_rx_ctl       (phy1_rgmii_rx_ctl),
    .rgmii_rxc          (phy1_rgmii_rx_clk_90),
    .inband_link_status (),
    .inband_clock_speed (),
    .inband_duplex_status()
);

tx_client_fifo #(
    .DEVICE (DEVICE)
) u_tx_fifo (
    .rd_clk        (tx_clk_int),
    .rd_sreset     (reset),
    .rd_enable     (tx_clk_en_int),
    .tx_data       (tx_data),
    .tx_data_valid (tx_valid),
    .tx_ack        (tx_rdy),
    .tx_collision  (tx_collision),
    .tx_retransmit (tx_retransmit),
    .overflow      (),
    .wr_clk        (udp_clk),
    .wr_sreset     (reset),
    .wr_data       (temac_tx_data),
    .wr_sof_n      (temac_tx_sof),
    .wr_eof_n      (temac_tx_eof),
    .wr_src_rdy_n  (temac_tx_valid),
    .wr_dst_rdy_n  (temac_tx_ready),
    .wr_fifo_status()
);

rx_client_fifo #(
    .DEVICE (DEVICE)
) u_rx_fifo (
    .wr_clk        (rx_clk_int),
    .wr_enable     (rx_clk_en_int),
    .wr_sreset     (reset),
    .rx_data       (rx_data),
    .rx_data_valid (rx_valid),
    .rx_good_frame (rx_correct_frame),
    .rx_bad_frame  (rx_error_frame),
    .overflow      (),
    .rd_clk        (udp_clk),
    .rd_sreset     (reset),
    .rd_data_out   (temac_rx_data),
    .rd_sof_n      (temac_rx_sof),
    .rd_eof_n      (temac_rx_eof),
    .rd_src_rdy_n  (temac_rx_valid),
    .rd_dst_rdy_n  (temac_rx_ready),
    .rx_fifo_status()
);

endmodule

