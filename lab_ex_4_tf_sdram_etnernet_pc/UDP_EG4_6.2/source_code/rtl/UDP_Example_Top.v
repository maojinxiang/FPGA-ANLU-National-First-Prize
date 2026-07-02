`timescale 1ns / 1ps
//********************************************************************** 
// -------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>Copyright Notice<<<<<<<<<<<<<<<<<<<<<<<<<<<< 
// ------------------------------------------------------------------- 
//             /\ --------------- 
//            /  \ ------------- 
//           / /\ \ -----------
//          / /  \ \ ---------
//         / /    \ \ ------- 
//        / /      \ \ ----- `
//       / /_ _ _   \ \ --- 
//      /_ _ _ _ _\  \_\ -
//*********************************************************************** 
// Author: suluyang 
// Email:luyang.su@anlogic.com 
// Date:2020/11/17 
// Description: 
// 2022/03/10:  修改时钟结构
//              简化约束
//              添加 soft fifo 
//              添加 debug 功能
// 2023/02/16 :add dynamic_local_ip_address port
// 
// web：www.anlogic.com 
//------------------------------------------------------------------- 
//*********************************************************************/
    `define UDP_LOOP_BACK
//  `define DEBUG_UDP
module UDP_Example_Top(
      input  clk_50, 
      input  sys_rst_n,
      input  sd_reset_rd,
      input  sd_miso , 
      output sd_clk  , 
      output sd_cs   , 
      output sd_mosi ,   
      input               phy1_rgmii_rx_clk,
      input               phy1_rgmii_rx_ctl,
      input [3:0]         phy1_rgmii_rx_data,
      output wire         phy1_rgmii_tx_clk,
      output wire         phy1_rgmii_tx_ctl,
      output wire [3:0]   phy1_rgmii_tx_data,     
      output [2:0]        led
);
parameter  DEVICE             = "EG4";//"PH1","EG4"
parameter  LOCAL_UDP_PORT_NUM = 16'h0001;       
parameter  LOCAL_IP_ADDRESS   = 32'hc0a8f001;       
parameter  LOCAL_MAC_ADDRESS  = 48'h0123456789ab;
parameter  DST_UDP_PORT_NUM   = 16'h0002;       
parameter  DST_IP_ADDRESS     = 32'hc0a8f002;
/*------------------------------*/
/*------------------------------*/
wire               key1 = sys_rst_n;
wire         app_rx_data_valid;//synthesis keep 
wire [7:0]   app_rx_data;//synthesis keep       
wire [15:0]  app_rx_data_length;//synthesis keep
wire [15:0]  app_rx_port_num;

wire         udp_tx_ready;//synthesis keep
wire         app_tx_ack;//synthesis keep
wire         app_tx_data_request;//synthesis keep
wire         app_tx_data_valid;//synthesis keep 
wire [7:0]   app_tx_data;//synthesis keep       
wire  [15:0] udp_data_length;

wire  [7:0]  tpg_data           ;
wire         tpg_data_valid     ;
wire  [15:0] tpg_data_udp_length;

//temac signals
wire        tx_stop;
wire [7:0]  tx_ifg_val;
wire        pause_req;
wire [15:0] pause_val;
wire [47:0] pause_source_addr;
wire [47:0] unicast_address;
wire [19:0] mac_cfg_vector;  

wire        temac_tx_ready;//synthesis keep
wire        temac_tx_valid;//synthesis keep
wire [7:0]  temac_tx_data;//synthesis keep 
wire        temac_tx_sof;
wire        temac_tx_eof;
            
wire        temac_rx_ready;
wire        temac_rx_valid;//synthesis keep
wire [7:0]  temac_rx_data;//synthesis keep 
wire        temac_rx_sof;
wire        temac_rx_eof;

wire        rx_correct_frame;
wire        rx_error_frame;
wire [1:0]  TRI_speed;

assign TRI_speed = 2'b10;//千兆2'b10 百兆2'b01 十兆2'b00

wire        rx_clk_int; 
wire        rx_clk_en_int;
wire        tx_clk_int; 
wire        tx_clk_en_int;

wire        temac_clk;//synthesis keep
wire        udp_clk;  //synthesis keep
wire        temac_clk90;//synthesis keep
wire        clk_125_out;
wire        clk_12_5_out;
wire        clk_1_25_out;
wire        rx_valid;//synthesis keep   
wire [7:0]  rx_data;//synthesis keep    
wire [7:0]  tx_data; //synthesis keep   
wire        tx_valid; //synthesis keep  
wire        tx_rdy;         
wire        tx_collision;   
wire        tx_retransmit;

wire        reset,reset_reg;
wire        clk_50_out;
reg [7:0]   phy_reset_cnt='d0;
reg [7:0]   soft_reset_cnt=8'hff;
reg sys_rst_n_1,sys_rst_n_2;
wire  key2;
assign key2 =sys_rst_n_2;
wire locked;
wire clk_50m ,clk_50m_180deg /* synthesis syn_keep=1 */;
assign  reset = ~key1 || reset_reg || (soft_reset_cnt != 'd0);

wire abcdsfg ;//synthesis keep = 1
assign abcdsfg = 1;
wire clk_sample;//synthesis keep = 1
pll_50 u_pll_50(
  .refclk (clk_50)   ,
  .reset  (!sys_rst_n_2)   ,
  .extlock(locked)  ,
  .clk0_out  (clk_50m),
  .clk1_out  (clk_50m_180deg),
  .clk2_out  (clk_sample)
);

    always @(posedge clk_50 or negedge sys_rst_n)           
        begin                                        
            if(!sys_rst_n)  begin
sys_rst_n_1 <= 1'b0;
sys_rst_n_2 <= 1'b0;
            end                             
                                                   
            else begin
sys_rst_n_1 <= sys_rst_n;
sys_rst_n_2 <= sys_rst_n_1;
            end                                                                 
        end                                          
wire rst_n/* synthesis syn_keep=1 */;
assign  rst_n = sys_rst_n_2 ;    


wire sd_rd_start_en;
wire [31:0] sd_rd_sec_addr ;
wire sd_rd_busy;
wire sd_rd_val_en ,sd_init_done/* synthesis syn_keep=1 */;
wire [15:0] sd_rd_val_data;
wire sdr_wr_en;//synthesis keep 
wire [31:0]sdr_wr_data;//synthesis keep 
//SD卡顶层控制模块
sd_ctrl_top t1_sd_ctrl_top(
    .clk_ref                (clk_50m),
    .clk_ref_180deg         (clk_50m_180deg),
    .rst_n                  (rst_n),
    //SD卡接口
    .sd_miso                (sd_miso),
    .sd_clk                 (sd_clk),
    .sd_cs                  (sd_cs),
    .sd_mosi                (sd_mosi),
    // //用户写SD卡接口
    // .wr_start_en            (1'b0),                      //不需要写入数据,写入接口赋值为0
    // .wr_sec_addr            (32'b0),
    // .wr_data                (16'b0),
    // .wr_busy                (),
    // .wr_req                 (),
    // //用户读SD卡接口
    .rd_start_en            (sd_rd_start_en),
    .rd_sec_addr            (sd_rd_sec_addr),
    .rd_busy                (sd_rd_busy),
    .rd_val_en              (sd_rd_val_en),
    .rd_val_data            (sd_rd_val_data),    
    
    .sd_init_done           (sd_init_done)
    );  


    reg sd_reset_rd_d0,sd_reset_rd_d1;
    always @(posedge clk_50 or negedge rst_n)           
        begin                                        
            if(!rst_n)    begin
            sd_reset_rd_d0<=1'b0;
            sd_reset_rd_d1<=1'b0;           
            end                                                                  
            else  begin
            sd_reset_rd_d0<=sd_reset_rd;
            sd_reset_rd_d1<=sd_reset_rd_d0;  
            end                                   
        end      

    wire sd_reset_rd_flag;
    assign   sd_reset_rd_flag =( {sd_reset_rd_d0,sd_reset_rd_d1}  ==   2'b10 )   ?  1'b0 :1'b1;    

                                                      
wire Sdr_init_done/* synthesis syn_keep=1 */;
//读取SD卡图片
wire full_flag_sdr;
sd_read_photo t2_sd_read_photo(
    .clk                   (clk_50m),
    //系统初始化完成之后,再开始从SD卡中读取图片
    .rst_n                 (rst_n & Sdr_init_done & sd_init_done & sd_reset_rd_flag ), 
    .ddr_max_addr          (24'd307200),       
    .sd_sec_num            (16'd1801), 
    .rd_busy               (sd_rd_busy),
    .sd_rd_val_en          (sd_rd_val_en),
    .sd_rd_val_data        (sd_rd_val_data),
    .rd_start_en           (sd_rd_start_en),
    .rd_sec_addr           (sd_rd_sec_addr),
    .sdr_wr_en             (sdr_wr_en  ),
    .sdr_wr_data           (sdr_wr_data),
    .full_flag_sdr(full_flag_sdr)
    );     

wire Sdr_rd_en            ;//synthesis keep
wire [23:0] Sdr_rd_dout   ;//synthesis keep
wire sdr_clk;

wire  [11:0] udp_wrusedw;//synthesis keep
sdram_top t3_sdram (
    .SYS_CLK                            (clk_50m                   ),
    // .LED                                (LED                       ),
    .sdr_data_valid                     (sdr_wr_en                 ),
    .sdr_data                           (sdr_wr_data               ),
    .rst_n                              (rst_n    & sd_reset_rd_flag                ),
    .sdr_clk							(sdr_clk),
    .Sdr_rd_en                          (Sdr_rd_en                 ),  
    .Sdr_rd_dout                        (Sdr_rd_dout               ) , 
    .Sdr_init_done                      (Sdr_init_done             ) ,
    .full_flag							(full_flag),
    .full_flag_sdr  (full_flag_sdr),
    .udp_wrusedw  (udp_wrusedw)
    );




always @(posedge clk_50_out or negedge key1)
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
`ifdef DEBUG_UDP
//=========================================================
//debug signal
//=========================================================
reg       debug_app_rx_data_valid   ;//synthesis keep
reg [7:0] debug_app_rx_data         ;//synthesis keep
reg       debug_app_tx_data_valid   ;//synthesis keep
reg [7:0] debug_app_tx_data         ;//synthesis keep
reg       debug_temac_tx_valid      ;//synthesis keep
reg [7:0] debug_temac_tx_data       ;//synthesis keep
reg       debug_temac_rx_valid      ;//synthesis keep
reg [7:0] debug_temac_rx_data       ;//synthesis keep
reg       debug_rx_valid            ;//synthesis keep
reg [7:0] debug_rx_data             ;//synthesis keep
reg       debug_tx_valid            ;//synthesis keep
reg [7:0] debug_tx_data             ;//synthesis keep

reg [31:0] debug_frame_temac_cnt_rx ;//synthesis keep
reg [31:0] debug_frame_app_cnt_rx   ;//synthesis keep
reg [31:0] debug_frame_fifo_cnt_rx  ;//synthesis keep
reg [31:0] debug_frame_temac_cnt_tx ;//synthesis keep
reg [31:0] debug_frame_app_cnt_tx   ;//synthesis keep
reg [31:0] debug_frame_fifo_cnt_tx  ;//synthesis keep

wire udp_debug_out;
// wire debug_out;
assign debug_out =   debug_app_rx_data_valid
                   | debug_app_rx_data      
                   | debug_app_tx_data_valid
                   | debug_app_tx_data      
                   | debug_temac_tx_valid   
                   | debug_temac_tx_data    
                   | debug_temac_rx_valid   
                   | debug_temac_rx_data    
                   | debug_rx_valid         
                   | debug_rx_data          
                   | debug_tx_valid       
                   | debug_tx_data
                   | debug_frame_temac_cnt_rx
                   | debug_frame_app_cnt_rx  
                   | debug_frame_fifo_cnt_rx 
                   | debug_frame_temac_cnt_tx
                   | debug_frame_app_cnt_tx  
                   | debug_frame_fifo_cnt_tx 
                   | udp_debug_out;

reg       debug_0;
reg [7:0] debug_1;
reg       debug_2;
reg [7:0] debug_3;
reg       debug_4;
reg [7:0] debug_5;
reg       debug_6;
reg [7:0] debug_7;
reg       debug_8;
reg [7:0] debug_9;
reg       debug_a;
reg [7:0] debug_b;

reg       debug_0_d;
reg [7:0] debug_1_d;
reg       debug_2_d;
reg [7:0] debug_3_d;
reg       debug_4_d;
reg [7:0] debug_5_d;
reg       debug_6_d;
reg [7:0] debug_7_d;
reg       debug_8_d;
reg [7:0] debug_9_d;
reg       debug_a_d;
reg [7:0] debug_b_d;

always @(posedge temac_clk or negedge key1)
begin
    if(~key1)
    begin
        debug_app_rx_data_valid <= 'd0;
        debug_app_rx_data       <= 'd0;
        debug_app_tx_data_valid <= 'd0;
        debug_app_tx_data       <= 'd0;
        debug_temac_tx_valid    <= 'd0;
        debug_temac_tx_data     <= 'd0;
        debug_temac_rx_valid    <= 'd0;
        debug_temac_rx_data     <= 'd0;
        debug_rx_valid          <= 'd0;
        debug_rx_data           <= 'd0;
        debug_tx_valid          <= 'd0;
        debug_tx_data           <= 'd0;
    end
    else
    begin
        debug_app_rx_data_valid <=debug_0_d;
        debug_app_rx_data       <=debug_1_d;
        debug_app_tx_data_valid <=debug_2_d;
        debug_app_tx_data       <=debug_3_d;
        debug_temac_tx_valid    <=debug_4_d;
        debug_temac_tx_data     <=debug_5_d;
        debug_temac_rx_valid    <=debug_6_d;
        debug_temac_rx_data     <=debug_7_d;
        debug_rx_valid          <=debug_8_d;
        debug_rx_data           <=debug_9_d;
        debug_tx_valid          <=debug_a_d;
        debug_tx_data           <=debug_b_d;
    end
end

always @(posedge temac_clk or negedge key1)
begin
    if(~key1)
    begin
        debug_0_d <= 'd0;
        debug_1_d <= 'd0;
        debug_2_d <= 'd0;
        debug_3_d <= 'd0;
        debug_4_d <= 'd0;
        debug_5_d <= 'd0;
        debug_6_d <= 'd0;
        debug_7_d <= 'd0;
        debug_8_d <= 'd0;
        debug_9_d <= 'd0;
        debug_a_d <= 'd0;
        debug_b_d <= 'd0;
    end
    else
    begin
        debug_0_d <= debug_0 ;
        debug_1_d <= debug_1 ;
        debug_2_d <= debug_2 ;
        debug_3_d <= debug_3 ;
        debug_4_d <= debug_4 ;
        debug_5_d <= debug_5 ;
        debug_6_d <= debug_6 ;
        debug_7_d <= debug_7 ;
        debug_8_d <= debug_8 ;
        debug_9_d <= debug_9 ;
        debug_a_d <= debug_a ;
        debug_b_d <= debug_b ;
    end
end

always @(posedge temac_clk or negedge key1)
begin
    if(~key1)
    begin
        debug_0 <= 'd0;
        debug_1 <= 'd0;
        debug_2 <= 'd0;
        debug_3 <= 'd0;
        debug_4 <= 'd0;
        debug_5 <= 'd0;
        debug_6 <= 'd0;
        debug_7 <= 'd0;
        debug_8 <= 'd0;
        debug_9 <= 'd0;
        debug_a <= 'd0;
        debug_b <= 'd0;
    end
    else
    begin
        debug_0 <= app_rx_data_valid   ;
        debug_1 <= app_rx_data         ;
        debug_2 <= app_tx_data_valid   ;
        debug_3 <= app_tx_data         ;
        debug_4 <= !temac_tx_valid     ;
        debug_5 <= temac_tx_data       ;
        debug_6 <= !temac_rx_valid     ;
        debug_7 <= temac_rx_data       ;
        debug_8 <= rx_valid            ;
        debug_9 <= rx_data             ;
        debug_a <= tx_valid            ;
        debug_b <= tx_data             ;
    end
end

always @(posedge temac_clk or negedge key1)
begin
    if(~key1)
    begin
        debug_frame_fifo_cnt_rx <= 'd0;
    end
    else if( !debug_6_d && debug_6)
    begin
        debug_frame_fifo_cnt_rx <= debug_frame_fifo_cnt_rx + 'd1;
    end
    else
    begin
        debug_frame_fifo_cnt_rx <=debug_frame_fifo_cnt_rx;
    end
end

always @(posedge temac_clk or negedge key1)
begin
    if(~key1)
    begin
        debug_frame_fifo_cnt_tx <= 'd0;
    end
    else if( !debug_4_d && debug_4)
    begin
        debug_frame_fifo_cnt_tx <= debug_frame_fifo_cnt_tx + 'd1;
    end
    else
    begin
        debug_frame_fifo_cnt_tx <=debug_frame_fifo_cnt_tx;
    end
end


always @(posedge temac_clk or negedge key1)
begin
    if(~key1)
    begin
        debug_frame_app_cnt_rx  <= 'd0;
    end
    else if( !debug_0_d && debug_0)
    begin
        debug_frame_app_cnt_rx  <= debug_frame_app_cnt_rx + 'd1;
    end
    else
    begin
        debug_frame_app_cnt_rx  <=debug_frame_app_cnt_rx;
    end
end

always @(posedge temac_clk or negedge key1)
begin
    if(~key1)
    begin
        debug_frame_app_cnt_tx  <= 'd0;
    end
    else if( !debug_2_d && debug_2)
    begin
        debug_frame_app_cnt_tx  <= debug_frame_app_cnt_tx + 'd1;
    end
    else
    begin
        debug_frame_app_cnt_tx  <=debug_frame_app_cnt_tx;
    end
end

always @(posedge temac_clk or negedge key1)
begin
    if(~key1)
    begin
        debug_frame_temac_cnt_rx    <= 'd0;
    end
    else if( !debug_8_d && debug_8)
    begin
        debug_frame_temac_cnt_rx    <= debug_frame_temac_cnt_rx + 'd1;
    end
    else
    begin
        debug_frame_temac_cnt_rx    <=debug_frame_temac_cnt_rx;
    end
end

always @(posedge temac_clk or negedge key1)
begin
    if(~key1)
    begin
        debug_frame_temac_cnt_tx    <= 'd0;
    end
    else if( !debug_a_d && debug_a)
    begin
        debug_frame_temac_cnt_tx    <= debug_frame_temac_cnt_tx + 'd1;
    end
    else
    begin
        debug_frame_temac_cnt_tx    <=debug_frame_temac_cnt_tx;
    end
end

`endif

//============================================================
// 参数配置逻辑
//============================================================
//需配置的客户端接口（初始默认值）
assign  tx_stop    = 1'b0;
assign  tx_ifg_val = 8'h00;
assign  pause_req  = 1'b0;
assign  pause_val  = 16'h0;
assign  pause_source_addr = 48'h5af1f2f3f4f5;
// assign  unicast_address   = 48'hab8967452301;
assign  unicast_address   = {   LOCAL_MAC_ADDRESS[7:0],
                                LOCAL_MAC_ADDRESS[15:8],
                                LOCAL_MAC_ADDRESS[23:16],
                                LOCAL_MAC_ADDRESS[31:24],
                                LOCAL_MAC_ADDRESS[39:32],
                                LOCAL_MAC_ADDRESS[47:40]
                            };


assign  mac_cfg_vector    = {1'b0,2'b00,TRI_speed,8'b00000010,7'b0000010}; //地址过滤模式、流控配置、速度配置、接收器配置、发送器配置
//assign  mac_cfg_vector    = {1'b0,2'b00,2'b10,8'b00000010,7'b0000010}; //地址过滤模式、流控配置、速度配置、接收器配置、发送器配置
//assign  mac_cfg_vector    = {1'b0,2'b00,2'b01,8'b00000010,7'b0000010}; //地址过滤模式、流控配置、速度配置、接收器配置、发送器配置
//assign  mac_cfg_vector    = {1'b0,2'b00,2'b00,8'b00000010,7'b0000010}; //地址过滤模式、流控配置、速度配置、接收器配置、发送器配置

//-----------------------------------------------------
//test dynamic_local_ip_address
//-----------------------------------------------------

//参数定义
reg [32:0] cnt0;
wire      end_cnt0;
wire      add_cnt0;
reg [7:0] cnt1;
wire      end_cnt1;
wire      add_cnt1;

wire rst_n ;
//计数器2
 always @(posedge udp_clk or negedge sys_rst_n_2)begin
     if(!sys_rst_n_2)begin
         cnt0 <= 0;
     end
     else if(add_cnt0)begin
         if(end_cnt0)
             cnt0 <= 0;
         else
             cnt0 <= cnt0 + 1;
     end
 end

 assign add_cnt0 = 1;
 assign end_cnt0 = add_cnt0 && 0;

 always @(posedge udp_clk or negedge sys_rst_n_2)begin 
     if(!sys_rst_n_2)begin
         cnt1 <= 0;
     end
     else if(add_cnt1)begin
         if(end_cnt1)
             cnt1 <= 0;
         else
             cnt1 <= cnt1 + 1;
     end
 end

 assign add_cnt1 = end_cnt0;
 assign end_cnt1 = add_cnt1 && cnt1== 15;  

reg [31:0]  input_local_ip_address;
reg         input_local_ip_address_valid;

always@(posedge udp_clk or posedge reset)
begin
    if(reset) 
    begin
        input_local_ip_address      <= LOCAL_IP_ADDRESS;
        input_local_ip_address_valid<= 1'b0;
    end
    else if(end_cnt0 == 1'b1)
    begin
        input_local_ip_address      <= {LOCAL_IP_ADDRESS[31:8],cnt1};
        input_local_ip_address_valid<= 1'b1;
    end
    else
    begin
        input_local_ip_address      <= input_local_ip_address;
        input_local_ip_address_valid<= 1'b1;
    end
end

assign led = ~input_local_ip_address[3:0];

reg [15:0] input_local_udp_port_num;
reg        input_local_udp_port_num_valid;

always@(posedge udp_clk or posedge reset)
begin
    if(reset) 
    begin
        input_local_udp_port_num      <= LOCAL_UDP_PORT_NUM;
        input_local_udp_port_num_valid<= 1'b0;
    end
    else
    begin
        input_local_udp_port_num      <= input_local_ip_address[3:0] + 3;
        input_local_udp_port_num_valid<= 1'b1;
    end
end

//-----------------------------------------------------

//app
//app u_app (
//    .sys_clk                    (clk_50                ),
//    .udp_rx_clk                 (udp_clk                ),
//    .udp_tx_clk                 (udp_clk                ),
//    .reset                      (key2                  ), 
//    .app_rx_data_valid          (app_rx_data_valid      ), 
//    .app_rx_data                (app_rx_data            ), 
//    .app_rx_data_length         (app_rx_data_length     ), 
//    .app_rx_port_num            (app_rx_port_num        ),
//    .VGA_HSYNC	                (VGA_HSYNC              ),
//	.VGA_VSYNC 	                (VGA_VSYNC              ),
//	.VGA_D                      (VGA_D                  ),
//    .rd_en                      (rd_en                  )
//);

/*vga_bmp u_vga_bmp
(   .VGA_HSYNC	                (VGA_HSYNC              ),
	.VGA_VSYNC 	                (VGA_VSYNC              ),
	.VGA_D                      (VGA_D                  ),
    .sys_clk                    (clk_50                ),
    .reset                      (key2                  )
);*/

clk_gen_rst_gen#(
    .DEVICE         (DEVICE     )
)u_clk_gen(
    .reset                (~key1                ),//~key1 
    .clk_in         (clk_50     ),
    .rst_out        (reset_reg  ),
    .clk_125_out0   (temac_clk  ),
    .clk_125_out1   (clk_125_out),
    .clk_125_out2   (temac_clk90),
    .clk_12_5_out   (clk_12_5_out),
    .clk_1_25_out   (clk_1_25_out),
    .clk_25_out     (clk_50_out )
);


udp_data_tpg u1_udp_data_tpg(
    .clk                (udp_clk            ),
    .reset              (~key2              ),

    .tpg_data           (tpg_data           ),//数据输出
    .tpg_data_valid     (tpg_data_valid     ),//数据有效信号
    .tpg_data_udp_length(tpg_data_udp_length),//数据长度（包含帧头）
    .tpg_data_done      (tpg_data_done      ),
    
    .tpg_data_enable    (phy_reset          ),
    .tpg_data_header0   (16'haabb           ),//帧头0
    .tpg_data_header1   (16'hccdd           ),//帧头1
    .tpg_data_type      (16'ha8b8           ),//数据帧类垿
    .tpg_data_length    (16'h00ff           ),//数据长度500
    .tpg_data_num       (16'h000a           ),//产生的帧个数10
    .tpg_data_ifg       (8'd130             )
);

wire [23:0] image_data;
// assign image_data = (Sdr_rd_dout[23:16] * 76 +Sdr_rd_dout[23:16] * 150 +Sdr_rd_dout[7:0] * 30 ) >>8;
assign image_data = Sdr_rd_dout[23:0] ;
//------------------------------------------------------------
//udp_loopback
//------------------------------------------------------------
udp_loopback#(
    .DEVICE(DEVICE)
)
 u2_udp_loopback
 (
    .app_rx_clk                 (sdr_clk                ),
    .app_tx_clk                 (udp_clk                ),
    .reset                      (reset                ),//reset
    .udp_wrusedw                   (udp_wrusedw),
    `ifdef UDP_LOOP_BACK    
    .app_rx_data                (image_data        ),
    .app_rx_data_valid          (Sdr_rd_en      ),
    .app_rx_data_length         (16'd3    ),
    `else   
    .app_rx_data                (tpg_data               ),
    .app_rx_data_valid          (tpg_data_valid         ),
    .app_rx_data_length         (tpg_data_udp_length    ),
    `endif              
    .full_flag                  (full_flag),
    .udp_tx_ready               (udp_tx_ready           ),
    .app_tx_ack                 (app_tx_ack             ),
    .app_tx_data                (app_tx_data            ),
    .app_tx_data_request        (app_tx_data_request    ),
    .app_tx_data_valid          (app_tx_data_valid      ),
    .udp_data_length            (udp_data_length        )   
);


// udp_loopback#(
//    .DEVICE(DEVICE)
// )
// u2_udp_loopback
// (
//    .app_rx_clk                 (udp_clk                ),
//    .app_tx_clk                 (udp_clk                ),
//    .reset                      (reset                 ),//reset
    
//    `ifdef UDP_LOOP_BACK    
//    .app_rx_data                (app_rx_data            ),
//    .app_rx_data_valid          (app_rx_data_valid      ),
//    .app_rx_data_length         (app_rx_data_length     ),
//    `else   
//    .app_rx_data                (tpg_data               ),
//    .app_rx_data_valid          (tpg_data_valid         ),
//    .app_rx_data_length         (tpg_data_udp_length    ),
//    `endif              
    
//    .udp_tx_ready               (udp_tx_ready           ),
//    .app_tx_ack                 (app_tx_ack             ),
//    .app_tx_data                (app_tx_data            ),
//    .app_tx_data_request        (app_tx_data_request    ),
//    .app_tx_data_valid          (app_tx_data_valid      ),
//    .udp_data_length            (udp_data_length        )   
// );
//------------------------------------------------------------  
//UDP
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
    .reset                      (reset                 ), 
    .udp2app_tx_ready           (udp_tx_ready           ), 
    .udp2app_tx_ack             (app_tx_ack             ), 
    .app_tx_request             (app_tx_data_request    ), 
    .app_tx_data_valid          (app_tx_data_valid      ), 
    .app_tx_data                (app_tx_data            ), 
    .app_tx_data_length         (udp_data_length        ), 
    .app_tx_dst_port            (DST_UDP_PORT_NUM       ), 
    .ip_tx_dst_address          (DST_IP_ADDRESS         ), 
    
    .input_local_udp_port_num      (input_local_udp_port_num      ),
    .input_local_udp_port_num_valid(input_local_udp_port_num_valid),
    
    .input_local_ip_address     (input_local_ip_address     ),
    .input_local_ip_address_valid(input_local_ip_address_valid),
    
    .app_rx_data_valid          (app_rx_data_valid      ), 
    .app_rx_data                (app_rx_data            ), 
    .app_rx_data_length         (app_rx_data_length     ), 
    .app_rx_port_num            (app_rx_port_num        ), 
    .temac_rx_ready             (temac_rx_ready         ),//output
    .temac_rx_valid             (!temac_rx_valid        ),//input
    .temac_rx_data              (temac_rx_data          ),//input
    .temac_rx_sof               (temac_rx_sof           ),//input
    .temac_rx_eof               (temac_rx_eof           ),//input
    .temac_tx_ready             (temac_tx_ready         ),//input
    .temac_tx_valid             (temac_tx_valid         ),//output
    .temac_tx_data              (temac_tx_data          ),//output
    .temac_tx_sof               (temac_tx_sof           ),//output
    .temac_tx_eof               (temac_tx_eof           ),//output
`ifdef DEBUG_UDP
    .udp_debug_out              (udp_debug_out          ),
`endif
    .ip_rx_error                (                       ), 
    .arp_request_no_reply_error (                       )
);
wire phy1_rgmii_rx_clk_0;
wire phy1_rgmii_rx_clk_90;

rx_pll u_rx_pll(
	.refclk		(phy1_rgmii_rx_clk),
    .reset       (1'b0),
    .clk0_out	(phy1_rgmii_rx_clk_0),
	.clk1_out	(phy1_rgmii_rx_clk_90)
);
//------------------------------------------------------------  
//TEMAC
//------------------------------------------------------------  
temac_block#(
    .DEVICE               (DEVICE                   )
)  
u4_trimac_block
(
    .reset                (reset                   ),
    .gtx_clk              (clk_125_out                ),//input   125M
    .gtx_clk_90           (temac_clk90                ),//input   125M
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
    .rgmii_rxc            (phy1_rgmii_rx_clk_90        ),
    .inband_link_status   (                         ),
    .inband_clock_speed   (                         ),
    .inband_duplex_status (                         )
);

udp_clk_gen#(
    .DEVICE               (DEVICE                   )
)           
u5_temac_clk_gen(           
    .reset                (~key1               ),//~key1 
    .tri_speed            (TRI_speed                ),
    .clk_125_in           (clk_125_out              ),//125M  
    .clk_12_5_in          (clk_12_5_out             ),//12.5M 
    .clk_1_25_in          (clk_1_25_out             ),//1.25M 
    .udp_clk_out          (udp_clk                  )
);

tx_client_fifo #
(
    .DEVICE               (DEVICE                   )
)
u6_tx_fifo
(
    .rd_clk               (tx_clk_int               ),
    .rd_sreset            (reset                   ),
    .rd_enable            (tx_clk_en_int            ),
    .tx_data              (tx_data                  ),
    .tx_data_valid        (tx_valid                 ),
    .tx_ack               (tx_rdy                   ),
    .tx_collision         (tx_collision             ),
    .tx_retransmit        (tx_retransmit            ),
    .overflow             (                         ),
                            
    .wr_clk               (udp_clk                  ),
    .wr_sreset            (reset                   ),
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
    .rd_sreset            (reset                   ),
    .rd_data_out          (temac_rx_data            ),//output reg [7:0] rd_data_out,
    .rd_sof_n             (temac_rx_sof             ),//output reg       rd_sof_n,
    .rd_eof_n             (temac_rx_eof             ),//output           rd_eof_n,
    .rd_src_rdy_n         (temac_rx_valid           ),//output reg       rd_src_rdy_n,
    .rd_dst_rdy_n         (temac_rx_ready           ),//input            rd_dst_rdy_n,
    .rx_fifo_status       (                         )
);



endmodule