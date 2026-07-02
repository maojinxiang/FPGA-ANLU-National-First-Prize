`timescale 1ns / 1ps
//**********************************************************************
// 模块名称: UDP_Example_Top (子板工程 - 集成图片发送功能)
// 功能描述:
//   1. 通过以太网主动发送LED/数码管控制指令（key2）
//   2. 从SD卡读取图片并通过以太网发送（key3）
//
// 工作原理:
//   - key2: 切换LED/数码管模式并自动发送（原有功能）
//   - key3: 切换到图片发送模式，从SD卡读取图片并发送
//   - 网络配置：FPGA(192.168.240.1) → 母板(192.168.240.2)
//
// 修改记录:
//   - 添加key3按键和模式控制
//   - 添加SD卡读取模块
//   - 添加SDRAM缓存模块
//   - 添加图片UDP发送模块
//   - 添加UDP发送仲裁模块
//***********************************************************************

module UDP_Example_Top(
        input               key1,           // 系统复位（低电平有效）
        input               key2,           // LED/数码管模式切换+发送按键
        input               key3,           // 图片发送模式按键（新增）
        input               key4,           // 母板模式切换按键（新增）
        input               clk_50,         // 50MHz输入时钟

        // SD卡接口（新增）
        output              sd_ncs,
        output              sd_dclk,
        output              sd_mosi,
        input               sd_miso,

        // HDMI接口（新增，完全照抄母板）
        output              HDMI_CLK_P,
        output              HDMI_D2_P,
        output              HDMI_D1_P,
        output              HDMI_D0_P,

        // 以太网RGMII接口
        input               phy1_rgmii_rx_clk,
        input               phy1_rgmii_rx_ctl,
        input [3:0]         phy1_rgmii_rx_data,
        output wire         phy1_rgmii_tx_clk,
        output wire         phy1_rgmii_tx_ctl,
        output wire [3:0]   phy1_rgmii_tx_data
);
parameter  DEVICE             = "EG4";           // FPGA型号

// 以太网参数
parameter LOCAL_UDP_PORT_NUM   = 16'h1773;
parameter LOCAL_IP_ADDRESS     = 32'hc0a8f002;  // 192.168.240.2
parameter LOCAL_MAC_ADDRESS    = 48'h0123456789ab;
parameter DST_UDP_PORT_NUM     = 16'h1773;
parameter DST_IP_ADDRESS       = 32'hc0a8f001;  // 192.168.240.1

// SDRAM参数（新增）
parameter MEM_DATA_BITS        = 32;
parameter ADDR_BITS            = 21;
parameter BURST_BITS           = 10;

// ========================================================================
// 时钟和复位信号
// ========================================================================
wire        sd_card_clk;        // SD卡时钟（新增）
wire        mem_clk;            // SDRAM时钟（新增）
wire        mem_clk_sft;        // SDRAM时钟移相（新增）
wire        video_clk;          // 视频像素时钟 (25MHz)
wire        video_clk_5x;       // 视频5倍时钟 (125MHz)

assign mem_clk     = temac_clk;      // 复用125MHz时钟
assign mem_clk_sft = temac_clk90;    // 复用125MHz 90度时钟

// ========================================================================
// UDP应用层接口
// ========================================================================
wire         app_rx_data_valid;
wire [7:0]   app_rx_data;
wire [15:0]  app_rx_data_length;
wire [15:0]  app_rx_port_num;

wire         udp_tx_ready;
wire         app_tx_ack;
wire         app_tx_data_request;
wire         app_tx_data_valid;
wire [7:0]   app_tx_data;
wire  [15:0] udp_data_length;

// LED/数码管模式的UDP发送接口
wire         led_app_tx_data_request;
wire         led_app_tx_data_valid;
wire [7:0]   led_app_tx_data;
wire [15:0]  led_udp_data_length;

// 图片模式的UDP发送接口
wire         img_app_tx_data_request;
wire         img_app_tx_data_valid;
wire [7:0]   img_app_tx_data;
wire [15:0]  img_udp_data_length;

// 模式切换命令的UDP发送接口
wire         mode_app_tx_data_request;
wire         mode_app_tx_data_valid;
wire [7:0]   mode_app_tx_data;
wire [15:0]  mode_udp_data_length;

// ========================================================================
// 模式控制信号
// ========================================================================
wire         img_mode;          // 图片发送模式标志
wire         sd_trigger;        // SD卡读取触发
wire         img_send_start;    // 图片发送启动

// ========================================================================
// SDRAM控制信号
// ========================================================================
wire         Sdr_init_done;
wire         Sdr_init_ref_vld;
wire         Sdr_busy;

// SDRAM读写接口
wire        App_rd_en;
wire [ADDR_BITS-1:0] App_rd_addr;
wire        App_wr_en;
wire [ADDR_BITS-1:0] App_wr_addr;
wire [MEM_DATA_BITS-1:0] App_wr_din;
wire [3:0]  App_wr_dm;
wire        Sdr_rd_en;
wire [MEM_DATA_BITS-1:0] Sdr_rd_dout;

// ========================================================================
// SD卡和图片数据信号
// ========================================================================
wire        sd_write_req;
wire        sd_write_en;
wire [31:0] sd_write_data;

// ========================================================================
// HDMI显示部分信号（完全照抄母板）
// ========================================================================
// UDP数据写入SDRAM（接收母板图像）
wire        hdmi_write_req;
wire        hdmi_write_en;
wire [31:0] hdmi_write_data;

// HDMI视频读取请求（从video_timing_data出来）
wire        hdmi_video_read_req;

// 视频时序和数据
wire        hdmi_hs, hdmi_vs, hdmi_de;
wire        hdmi_hs_r, hdmi_vs_r, hdmi_de_r;
wire [23:0] hdmi_vout_data;

// SD卡图片发送请求（从udp_simple_send出来）
wire        img_read_req;
wire        img_read_en_from_udp;        // udp_simple_send输出的read_en
wire        hdmi_read_en_from_video;     // video_delay输出的read_en

// 以下信号通过mux根据img_mode动态分配（在后面用assign定义）
wire        sd_write_req_ack;
wire        hdmi_write_req_ack;
wire        img_read_req_ack;
wire [31:0] img_read_data;
wire        hdmi_video_read_req_ack;
wire [31:0] hdmi_video_read_data;

//temac signals
wire        tx_stop;
wire [7:0]  tx_ifg_val;
wire        pause_req;
wire [15:0] pause_val;
wire [47:0] pause_source_addr;
wire [47:0] unicast_address;
wire [19:0] mac_cfg_vector;  

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

wire        rx_correct_frame;//synthesis keep
wire        rx_error_frame;//synthesis keep
wire [1:0]  TRI_speed;

assign TRI_speed = 2'b10;//千兆2'b10 百兆2'b01 十兆2'b00

wire        rx_clk_int; 
wire        rx_clk_en_int;
wire        tx_clk_int; 
wire        tx_clk_en_int;

wire        temac_clk;//synthesis keep
wire        udp_clk;  //synthesis keep
wire        temac_clk90;
wire        clk_125_out;
wire        clk_12_5_out;
wire        clk_1_25_out;
wire        rx_valid;  //synthesis keep
wire [7:0]  rx_data;   //synthesis keep 
wire [7:0]  tx_data;    
wire        tx_valid;   
wire        tx_rdy;         
wire        tx_collision;   
wire        tx_retransmit;

wire        reset,reset_reg;
wire        clk_25_out;
reg [7:0]   phy_reset_cnt='d0;
reg [7:0]   soft_reset_cnt=8'hff;
always @(posedge clk_25_out or negedge key1)
begin
    if(~key1)
        phy_reset_cnt<='d0;
    else if(phy_reset_cnt < 255)
        phy_reset_cnt<= phy_reset_cnt+1;
    else
        phy_reset_cnt<=phy_reset_cnt;
end

assign  reset = ~key1 || reset_reg || (soft_reset_cnt != 'd0);
assign  phy_reset = phy_reset_cnt[7];

always @(posedge udp_clk or negedge key1)
begin
    if(~key1)
        soft_reset_cnt<=8'hff;
    else if(soft_reset_cnt > 0)
        soft_reset_cnt<= soft_reset_cnt-1;
    else
        soft_reset_cnt<=soft_reset_cnt;
end

//============================================================
// TEMAC MAC配置
//============================================================
assign  tx_stop    = 1'b0;
assign  tx_ifg_val = 8'h00;
assign  pause_req  = 1'b0;
assign  pause_val  = 16'h0;
assign  pause_source_addr = 48'h5af1f2f3f4f5;

// MAC地址字节序转换（网络字节序）
assign  unicast_address   = {   LOCAL_MAC_ADDRESS[7:0],
                                LOCAL_MAC_ADDRESS[15:8],
                                LOCAL_MAC_ADDRESS[23:16],
                                LOCAL_MAC_ADDRESS[31:24],
                                LOCAL_MAC_ADDRESS[39:32],
                                LOCAL_MAC_ADDRESS[47:40]
                            };

// MAC配置向量：地址过滤、流控、速度、接收器、发送器配置
assign  mac_cfg_vector    = {1'b0,2'b00,TRI_speed,8'b00000010,7'b0000010};

//============================================================
// 模块例化
//============================================================

clk_gen_rst_gen#(
    .DEVICE         (DEVICE     )
) u_clk_gen(
    .reset          (~key1      ),
    .clk_in         (clk_50     ),
    .rst_out        (reset_reg  ),
    .clk_125_out0   (temac_clk  ),
    .clk_125_out1   (clk_125_out),
    .clk_125_out2   (temac_clk90),
    .clk_12_5_out   (clk_12_5_out),
    .clk_1_25_out   (clk_1_25_out),
    .clk_25_out     (clk_25_out )
);

//============================================================
// 新增模块实例化
//============================================================
wire app_rst_n;
assign app_rst_n = ~reset;

//------------------------------------------------------------
// 1. 按键模式控制模块（仅key3切换图片模式）
//------------------------------------------------------------
key_mode_ctrl u_key_mode_ctrl (
    .clk                (udp_clk        ),
    .rst_n              (app_rst_n      ),
    .key3               (key3           ),
    .key4               (1'b1           ),  // key4不再通过此模块处理
    .img_mode           (img_mode       ),
    .sd_trigger         (sd_trigger     ),
    .img_send_start     (img_send_start ),
    .mode_cmd           (),                 // 悬空
    .mode_cmd_valid     ()                  // 悬空
);

//------------------------------------------------------------
// 2. SD卡时钟PLL（生成SD卡所需时钟）
//------------------------------------------------------------
sys_pll u_sys_pll (
    .refclk             (clk_50         ),
    .clk0_out           (sd_card_clk    ),
    .clk1_out           (),
    .clk2_out           (),
    .reset              (1'b0           )
);

//------------------------------------------------------------
// 2b. 视频PLL（完全照抄母板配置：25MHz + 125MHz）
//------------------------------------------------------------
video_pll u_video_pll (
    .refclk             (clk_50         ),
    .reset              (~key1          ),
    .clk0_out           (video_clk      ),  // 25MHz像素时钟
    .clk1_out           (video_clk_5x   )   // 125MHz 5倍时钟
);

//------------------------------------------------------------
// 3. SDRAM控制器（使用import/sdram/sdram.v）
//------------------------------------------------------------
sdram u_sdram (
    .Clk                (mem_clk        ),
    .Clk_sft            (mem_clk_sft    ),
    .Rst                (reset          ),
    .Sdr_init_done      (Sdr_init_done  ),
    .Sdr_init_ref_vld   (Sdr_init_ref_vld),
    .Sdr_busy           (Sdr_busy       ),
    .App_wr_en          (App_wr_en      ),
    .App_wr_addr        (App_wr_addr    ),
    .App_wr_dm          (App_wr_dm      ),
    .App_wr_din         (App_wr_din     ),
    .App_rd_en          (App_rd_en      ),
    .App_rd_addr        (App_rd_addr    ),
    .Sdr_rd_en          (Sdr_rd_en      ),
    .Sdr_rd_dout        (Sdr_rd_dout    )
);

//------------------------------------------------------------
// 4. SD卡BMP读取模块
//------------------------------------------------------------
sd_card_bmp u_sd_card_bmp (
    .clk                (sd_card_clk    ),
    .rst                (~key1          ),
    .key                (sd_trigger     ),
    .state_code         (),
    .bmp_width          (16'd640        ),
    .write_req          (sd_write_req   ),
    .write_req_ack      (sd_write_req_ack),
    .write_en           (sd_write_en    ),
    .write_data         (sd_write_data  ),
    .SD_nCS             (sd_ncs         ),
    .SD_DCLK            (sd_dclk        ),
    .SD_MOSI            (sd_mosi        ),
    .SD_MISO            (sd_miso        )
);

//------------------------------------------------------------
// 5. frame_read_write（SDRAM读写控制，支持HDMI和SD卡发送）
//------------------------------------------------------------
// 读写接口mux信号
wire        frame_read_clk;
wire        frame_read_req;
wire        frame_read_req_ack;
wire        frame_input_read_en;     // 输入到frame_read_write的read_en
wire [31:0] frame_read_data;
wire        frame_write_clk;
wire        frame_write_req;
wire        frame_write_req_ack;
wire        frame_write_en;
wire [31:0] frame_write_data;

// img_mode=0: HDMI显示（UDP写入，视频读取）
// img_mode=1: SD卡发送（SD卡写入，UDP读取）
assign frame_read_clk       = img_mode ? udp_clk : video_clk;
assign frame_read_req       = img_mode ? img_read_req : hdmi_video_read_req;
assign img_read_req_ack     = img_mode ? frame_read_req_ack : 1'b0;
assign hdmi_video_read_req_ack = img_mode ? 1'b0 : frame_read_req_ack;

// read_en mux: 选择谁的read_en输入到frame_read_write
assign frame_input_read_en  = img_mode ? img_read_en_from_udp : hdmi_read_en_from_video;

assign hdmi_video_read_data = img_mode ? 32'h0 : frame_read_data;
assign img_read_data        = img_mode ? frame_read_data : 32'h0;

assign frame_write_clk      = img_mode ? sd_card_clk : udp_clk;
assign frame_write_req      = img_mode ? sd_write_req : hdmi_write_req;
assign sd_write_req_ack     = img_mode ? frame_write_req_ack : 1'b0;
assign hdmi_write_req_ack   = img_mode ? 1'b0 : frame_write_req_ack;
assign frame_write_en       = img_mode ? sd_write_en : hdmi_write_en;
assign frame_write_data     = img_mode ? sd_write_data : hdmi_write_data;

frame_read_write #(
    .ADDR_BITS          (ADDR_BITS      ),
    .READ_DATA_BITS     (32             ),
    .WRITE_DATA_BITS    (32             )
) u_frame_rw (
    .mem_clk            (mem_clk        ),
    .rst                (reset          ),
    .Sdr_init_done      (Sdr_init_done  ),
    .Sdr_init_ref_vld   (Sdr_init_ref_vld),
    .Sdr_busy           (Sdr_busy       ),
    // 读接口（根据img_mode切换）
    .App_rd_en          (App_rd_en      ),
    .App_rd_addr        (App_rd_addr    ),
    .Sdr_rd_en          (Sdr_rd_en      ),
    .Sdr_rd_dout        (Sdr_rd_dout    ),
    .read_clk           (frame_read_clk ),
    .read_req           (frame_read_req ),
    .read_req_ack       (frame_read_req_ack),
    .read_finish        (),
    .read_addr_0        (21'd0          ),
    .read_addr_1        (21'd0          ),
    .read_addr_2        (21'd0          ),
    .read_addr_3        (21'd0          ),
    .read_addr_index    (2'd0           ),
    .read_len           (21'd307200     ),
    .read_en            (frame_input_read_en),
    .read_data          (frame_read_data),
    // 写接口（根据img_mode切换）
    .App_wr_en          (App_wr_en      ),
    .App_wr_addr        (App_wr_addr    ),
    .App_wr_din         (App_wr_din     ),
    .App_wr_dm          (App_wr_dm      ),
    .write_clk          (frame_write_clk),
    .write_req          (frame_write_req),
    .write_req_ack      (frame_write_req_ack),
    .write_finish       (),
    .write_addr_0       (21'd0          ),
    .write_addr_1       (21'd0          ),
    .write_addr_2       (21'd0          ),
    .write_addr_3       (21'd0          ),
    .write_addr_index   (2'd0           ),
    .write_len          (21'd307200     ),
    .write_en           (frame_write_en ),
    .write_data         (frame_write_data)
);

//------------------------------------------------------------
// 6. 模式切换命令发送模块（key4直接发送0x0001/0x0003给母板）
//------------------------------------------------------------
udp_mode_tx u_mode_tx (
    .clk                    (udp_clk                    ),
    .rst_n                  (app_rst_n                  ),
    .key4                   (key4                       ),
    .udp_tx_ready           (udp_tx_ready               ),
    .app_tx_ack             (app_tx_ack && mode_app_tx_data_request),  // 只在发送请求时响应ack
    .app_tx_data_request    (mode_app_tx_data_request   ),
    .app_tx_data_valid      (mode_app_tx_data_valid     ),
    .app_tx_data            (mode_app_tx_data           ),
    .udp_data_length        (mode_udp_data_length       )
);

//------------------------------------------------------------
// 7. 图片UDP发送模块（简单协议，模拟q2.py发送方式）
//------------------------------------------------------------
udp_simple_send u_udp_simple_send (
    .clk                (udp_clk                ),
    .rst_n              (app_rst_n              ),
    .read_req           (img_read_req           ),
    .read_req_ack       (img_read_req_ack       ),
    .read_en            (img_read_en_from_udp   ),
    .read_data          (img_read_data          ),
    .udp_tx_ready       (udp_tx_ready           ),
    .app_tx_ack         (app_tx_ack && img_app_tx_data_request),  // 只在图片发送请求时响应ack
    .app_tx_data_request(img_app_tx_data_request),
    .app_tx_data_valid  (img_app_tx_data_valid  ),
    .app_tx_data        (img_app_tx_data        ),
    .udp_data_length    (img_udp_data_length    ),
    .start_send         (img_send_start         )
);

//------------------------------------------------------------
// 8. LED/数码管UDP发送模块（原有功能）
//------------------------------------------------------------
udp_tx_simple u_udp_tx_simple (
    .clk                (udp_clk                ),
    .rst_n              (app_rst_n              ),
    .key2               (key2                   ),
    .udp_tx_ready       (udp_tx_ready           ),
    .app_tx_ack         (app_tx_ack && led_app_tx_data_request),  // 只在LED发送请求时响应ack
    .app_tx_data_request(led_app_tx_data_request),
    .app_tx_data_valid  (led_app_tx_data_valid  ),
    .app_tx_data        (led_app_tx_data        ),
    .udp_data_length    (led_udp_data_length    )
);

//------------------------------------------------------------
// 9. UDP发送仲裁（3路优先级：模式命令 > 图片 > LED）
//------------------------------------------------------------
assign app_tx_data_request = mode_app_tx_data_request ? mode_app_tx_data_request :
                              (img_mode ? img_app_tx_data_request : led_app_tx_data_request);

assign app_tx_data_valid   = mode_app_tx_data_valid ? mode_app_tx_data_valid :
                              (img_mode ? img_app_tx_data_valid : led_app_tx_data_valid);

assign app_tx_data         = mode_app_tx_data_valid ? mode_app_tx_data :
                              (img_mode ? img_app_tx_data : led_app_tx_data);

assign udp_data_length     = mode_app_tx_data_valid ? mode_udp_data_length :
                              (img_mode ? img_udp_data_length : led_udp_data_length);

//------------------------------------------------------------
// UDP/IP协议栈
//------------------------------------------------------------
udp_ip_protocol_stack #
(
    .DEVICE                     (DEVICE                 ),
    .LOCAL_UDP_PORT_NUM         (LOCAL_UDP_PORT_NUM     ),
    .LOCAL_IP_ADDRESS           (LOCAL_IP_ADDRESS       ),
    .LOCAL_MAC_ADDRESS          (LOCAL_MAC_ADDRESS      )
)
u3_udp_ip_protocol_stack
(
    .udp_rx_clk                 (udp_clk                ),
    .udp_tx_clk                 (udp_clk                ),
    .reset                      (reset                  ),
    .udp2app_tx_ready           (udp_tx_ready           ),
    .udp2app_tx_ack             (app_tx_ack             ),
    .app_tx_request             (app_tx_data_request    ),
    .app_tx_data_valid          (app_tx_data_valid      ),
    .app_tx_data                (app_tx_data            ),
    .app_tx_data_length         (udp_data_length        ),
    .app_tx_dst_port            (DST_UDP_PORT_NUM       ),
    .ip_tx_dst_address          (DST_IP_ADDRESS         ),

    // 静态IP和端口配置
    .input_local_udp_port_num      (LOCAL_UDP_PORT_NUM  ),
    .input_local_udp_port_num_valid(1'b0                ),
    .input_local_ip_address        (LOCAL_IP_ADDRESS    ),
    .input_local_ip_address_valid  (1'b0                ),

    .app_rx_data_valid          (app_rx_data_valid      ),
    .app_rx_data                (app_rx_data            ),
    .app_rx_data_length         (app_rx_data_length     ),
    .app_rx_port_num            (app_rx_port_num        ),
    .temac_rx_ready             (temac_rx_ready         ),
    .temac_rx_valid             (!temac_rx_valid        ),
    .temac_rx_data              (temac_rx_data          ),
    .temac_rx_sof               (temac_rx_sof           ),
    .temac_rx_eof               (temac_rx_eof           ),
    .temac_tx_ready             (temac_tx_ready         ),
    .temac_tx_valid             (temac_tx_valid         ),
    .temac_tx_data              (temac_tx_data          ),
    .temac_tx_sof               (temac_tx_sof           ),
    .temac_tx_eof               (temac_tx_eof           ),
    .ip_rx_error                (                       ),
    .arp_request_no_reply_error (                       )
);

//------------------------------------------------------------  
//TEMAC
//------------------------------------------------------------  
temac_block#(
    .DEVICE               (DEVICE                   )
) u4_trimac_block
(
    .reset                (reset                    ),
    .gtx_clk              (temac_clk                ),//input   125M
    .gtx_clk_90           (temac_clk90              ),//input   125M
    .rx_clk               (rx_clk_int               ),//output  125M 25M    2.5M
    .rx_clk_en            (rx_clk_en_int            ),//output  1    12.5M  1.25M
    .rx_data              (rx_data                  ),
    .rx_data_valid        (rx_valid                 ),
    .rx_correct_frame     (rx_correct_frame         ),
    .rx_error_frame       (rx_error_frame           ),
    .rx_status_vector     (                         ),
    .rx_status_vld        (                         ),
//  .tri_speed            (tri_speed                ),//output
    .tx_clk               (tx_clk_int               ),//output  125M
    .tx_clk_en            (tx_clk_en_int            ),//output  1    12.5M  1.25M 占空比不对
    .tx_data              (tx_data                  ),
    .tx_data_en           (tx_valid                 ),
    .tx_rdy               (tx_rdy                   ),//temac_tx_ready
    .tx_stop              (tx_stop                  ),//input
    .tx_collision         (tx_collision             ),
    .tx_retransmit        (tx_retransmit            ),
    .tx_ifg_val           (tx_ifg_val               ),//input
    .tx_status_vector     (                         ),
    .tx_status_vld        (                         ),
    .pause_req            (pause_req                ),//input
    .pause_val            (pause_val                ),//input
    .pause_source_addr    (pause_source_addr        ),//input
    .unicast_address      (unicast_address          ),//input
    .mac_cfg_vector       (mac_cfg_vector           ),//input
    .rgmii_txd            (phy1_rgmii_tx_data       ),
    .rgmii_tx_ctl         (phy1_rgmii_tx_ctl        ),
    .rgmii_txc            (phy1_rgmii_tx_clk        ),
    .rgmii_rxd            (phy1_rgmii_rx_data       ),
    .rgmii_rx_ctl         (phy1_rgmii_rx_ctl        ),
    .rgmii_rxc            (phy1_rgmii_rx_clk        ),
    .inband_link_status   (                         ),
    .inband_clock_speed   (                         ),
    .inband_duplex_status (                         )
);

udp_clk_gen#(
    .DEVICE               (DEVICE                   )
)  u5_temac_clk_gen(           
    .reset                (~key1                    ),
    .tri_speed            (TRI_speed                ),
    .clk_125_in           (clk_125_out              ),//125M  
    .clk_12_5_in          (clk_12_5_out             ),//12.5M 
    .clk_1_25_in          (clk_1_25_out             ),//1.25M 
    .udp_clk_out          (udp_clk                  )
);

tx_client_fifo#
(
    .DEVICE               (DEVICE                   )
)
u6_tx_fifo
(
    .rd_clk               (tx_clk_int               ),
    .rd_sreset            (reset                    ),
    .rd_enable            (tx_clk_en_int            ),
    .tx_data              (tx_data                  ),
    .tx_data_valid        (tx_valid                 ),
    .tx_ack               (tx_rdy                   ),
    .tx_collision         (tx_collision             ),
    .tx_retransmit        (tx_retransmit            ),
    .overflow             (                         ),
                            
    .wr_clk               (udp_clk                  ),
    .wr_sreset            (reset                    ),
    .wr_data              (temac_tx_data            ),
    .wr_sof_n             (temac_tx_sof             ),
    .wr_eof_n             (temac_tx_eof             ),
    .wr_src_rdy_n         (temac_tx_valid           ),
    .wr_dst_rdy_n         (temac_tx_ready           ),//temac_tx_ready
    .wr_fifo_status       (                         )
);

rx_client_fifo#
(
    .DEVICE               (DEVICE                   )
)
u7_rx_fifo                  
(                           
    .wr_clk               (rx_clk_int               ),
    .wr_enable            (rx_clk_en_int            ),
    .wr_sreset            (reset                    ),
    .rx_data              (rx_data                  ),
    .rx_data_valid        (rx_valid                 ),
    .rx_good_frame        (rx_correct_frame         ),
    .rx_bad_frame         (rx_error_frame           ),
    .overflow             (                         ),
    .rd_clk               (udp_clk                  ),
    .rd_sreset            (reset                    ),
    .rd_data_out          (temac_rx_data            ),//output reg [7:0] rd_data_out,
    .rd_sof_n             (temac_rx_sof             ),//output reg       rd_sof_n,
    .rd_eof_n             (temac_rx_eof             ),//output           rd_eof_n,
    .rd_src_rdy_n         (temac_rx_valid           ),//output reg       rd_src_rdy_n,
    .rd_dst_rdy_n         (temac_rx_ready           ),//input            rd_dst_rdy_n,
    .rx_fifo_status       (                         )
);

//========================================================================
// HDMI显示部分 - 完全照抄母板实现
//========================================================================
//------------------------------------------------------------
// 10. UDP数据写入SDRAM（接收母板图像）- 使用分包协议解析
//------------------------------------------------------------
udp_packet_to_sdram #(
    .PIXEL_COUNT(307200)
) u_hdmi_writer (
    .clk                (udp_clk),
    .reset              (reset),
    .udp_data_valid     (app_rx_data_valid),
    .udp_data           (app_rx_data),
    .udp_data_length    (app_rx_data_length),
    .write_req          (hdmi_write_req),
    .write_req_ack      (hdmi_write_req_ack),
    .write_en           (hdmi_write_en),
    .write_data         (hdmi_write_data)
);

//------------------------------------------------------------
// 11. 视频时序生成
//------------------------------------------------------------
video_timing_data u_hdmi_video_timing (
    .video_clk          (video_clk),
    .rst                (reset),
    .read_req           (hdmi_video_read_req),
    .read_req_ack       (hdmi_video_read_req_ack),
    .hs                 (hdmi_hs),
    .vs                 (hdmi_vs),
    .de                 (hdmi_de)
);

//------------------------------------------------------------
// 12. 视频延迟对齐
//------------------------------------------------------------
video_delay u_hdmi_video_delay (
    .video_clk          (video_clk),
    .rst                (reset),
    .read_en            (hdmi_read_en_from_video),
    .read_data          (hdmi_video_read_data[31:8]),  // 取{R,G,B}，丢弃低8位的0
    .hs                 (hdmi_hs),
    .vs                 (hdmi_vs),
    .de                 (hdmi_de),
    .hs_r               (hdmi_hs_r),
    .vs_r               (hdmi_vs_r),
    .de_r               (hdmi_de_r),
    .vout_data          (hdmi_vout_data)
);

//------------------------------------------------------------
// 13. HDMI发送器
//------------------------------------------------------------
hdmi_tx #(
    .FAMILY("EG4")
) u_hdmi_tx (
    .PXLCLK_I           (video_clk),
    .PXLCLK_5X_I        (video_clk_5x),
    .RST_N              (~reset),
    .VGA_HS             (hdmi_hs_r),
    .VGA_VS             (hdmi_vs_r),
    .VGA_DE             (hdmi_de_r),
    .VGA_RGB            (hdmi_vout_data),
    .HDMI_CLK_P         (HDMI_CLK_P),
    .HDMI_D2_P          (HDMI_D2_P),
    .HDMI_D1_P          (HDMI_D1_P),
    .HDMI_D0_P          (HDMI_D0_P)
);

endmodule