
module temac_block (
      
      // 异步复位
      //--------------------------
      input                reset,
      
      //全局发送时钟
      //--------------------------
      input                gtx_clk,
      input                gtx_clk_90,
      // 客户端接收接口
      //--------------------------
      output               rx_clk,
      output               rx_clk_en,
      output      [7:0]    rx_data,
      output               rx_data_valid,
      output               rx_correct_frame,
      output               rx_error_frame,
      output      [26:0]   rx_status_vector,
      output               rx_status_vld,

      // 客户发送器接口
      //-----------------------------
      output               tx_clk,
      output               tx_clk_en,
      input       [7:0]    tx_data,
      input                tx_data_en,
      output               tx_rdy,
      input                tx_stop,
      output               tx_collision,
      output               tx_retransmit,
      input       [7:0]    tx_ifg_val,
      output      [28:0]   tx_status_vector,
      output               tx_status_vld,

	  output reg  [1:0]	   tri_speed,//"10"表示当前速度为1000m, "01"表示当前速度为100m，"00"表示当前速度为10m
      // 流控接口
      //----------------------
      input                pause_req,
      input       [15:0]   pause_val,
      input       [47:0]   pause_source_addr,

      // 初始默认单播地址值
      //----------------
      input       [47:0]   unicast_address,

      // AXI主机管理接口
      //---------------
//      input                s_axi_aclk,
//      input       [7 : 0]  s_axi_awaddr,
//      input                s_axi_awvalid,
//      output               s_axi_awready,
//      input       [31: 0]  s_axi_wdata,   
//      input                s_axi_wvalid,
//      output               s_axi_wready,
//      output      [1 : 0]  s_axi_bresp,
//      output               s_axi_bvalid,
//      input                s_axi_bready,
//      input       [7 : 0]  s_axi_araddr,
//      input                s_axi_arvalid,
//      output               s_axi_arready,
//      output      [31: 0]  s_axi_rdata,
//      output      [1 : 0]  s_axi_rresp,
//      output               s_axi_rvalid,
//      input                s_axi_rready,

      // 向量配置总线
      //----------------
      input       [19:0]   mac_cfg_vector,
      
      // RGMII接口
      //----------------
      output      [3:0]    rgmii_txd,
      output               rgmii_tx_ctl,
      output               rgmii_txc,
      input       [3:0]    rgmii_rxd,
      input                rgmii_rx_ctl,
      input                rgmii_rxc,
      output               inband_link_status,
      output      [1:0]    inband_clock_speed,
      output               inband_duplex_status,
 
      // MDIO接口
      //---------------
      input                mdio_i,
      output               mdio_o,
      output               mdio_oen,
      output               mdio_clk
      
      );  
   parameter     DEVICE             = "EG4";//"PH1","EG4"
   //-------------------------------------------------------------------------------------------------------------
   // 模块内部信号。
   //-------------------------------------------------------------------------------------------------------------
   
   //复位信号
   //-----------------------
   wire           tx_reset;                  // MAC核和rgmii接口模块 Tx域中的同步复位
   wire           rx_reset;                  // MAC核和rgmii接口模块 rx域中的同步复位
   
   //rx域 接收时钟 及 用户接收时钟使能信号
   //-----------------------
   wire           rx_rgmii_clk_int;          // RGMII 接收时钟.              
   reg            client_rxc_en_int;         // 客户端接收时钟使能信号
   
   //tx域 发送时钟使能信号
   //-----------------------  
   wire           client_txc_en_int;         // 客户端发送时钟使能信号
   wire           gmii_txc_en_int;           // gmii/mii接口发送时钟使能信号
   wire           rgmii_txc_en;              // rgmii接口发送时钟使能信号，  输入到ODDR-d1端口
   wire           rgmii_txc_en_shift;        // rgmii接口发送时钟使能信号，  输入到ODDR-d0端口

   //速度指示信号
   //-----------------------
   wire           speed_10_int;              // 当前速度在 10Mb/s.
   wire           speed_100_int;             // 当前速度在 100Mb/s.
   wire           speed_1000_int;            // 当前速度在 1000Mb/s.   
   wire           speed_10_100_int;          // 当前速度在 10Mb/s 或 100Mb/s.
   wire           speed_10_100;              

   //模块内部 gmii/mii 信号
   //-----------------------
   wire           gmii_tx_en_int;            
   wire           gmii_tx_er_int;            
   wire  [7:0]    gmii_txd_int;              
   wire           gmii_rx_dv_int;            
   wire           gmii_rx_er_int;            
   wire  [7:0]    gmii_rxd_int;              
   wire           gmii_col_int;              
   wire           gmii_crs_int;
      

 //==================================================================================================================
      
   //-----------------------------
   //速度指示信号
   //speed_10_100_int = ！speed_1000_int;
   assign speed_10_100_int = speed_10_int | speed_100_int;  // "1" 指示 10Mb/s 或 100Mb/s 速度运行; "0" 指示 1000Mb/s速度运行
   
   //-----------------------------
   // 将 时钟信号/时钟使能信号 输出给用户.
   assign rx_clk    = rx_rgmii_clk_int;     // 125mhz（1gbps） 25mhz(100mbps)    2.5mhz(10mbps)
   assign tx_clk    = gtx_clk;              // 125mhz
   assign rx_clk_en = client_rxc_en_int;    // 保持1 （1gbps） 12.5mhz(100mbps)  1.25mhz(10mbps)
   assign tx_clk_en = client_txc_en_int;    // 保持1 （1gbps） 12.5mhz(100mbps)  1.25mhz(10mbps)
 
   //---------------------------------------------------------------------------
   // 例化 复位同步
   //---------------------------------------------------------------------------
reg [1:0]reset_reg1;
reg [1:0]reset_reg2;
	
always@(posedge rx_rgmii_clk_int)
begin
	reset_reg1 <= {reset_reg1[0],reset};
end
assign rx_reset = reset_reg1[1];
 
always@(posedge gtx_clk)
begin
	reset_reg2 <= {reset_reg2[0],reset};
end
assign tx_reset = reset_reg2[1]; 

always@(posedge gtx_clk or posedge reset)
begin
	if(reset == 1'b1)
		tri_speed <= 2'b11;
	else if(speed_1000_int == 1'b1)
		tri_speed <= 2'b10;
	else if(speed_100_int == 1'b1)
		tri_speed <= 2'b01;
	else if(speed_10_int == 1'b1)
		tri_speed <= 2'b00;	
	else 
		tri_speed <= 2'b11;			
end
 
//---------------------------------------------------------------------------
// Clock 产生
//---------------------------------------------------------------------------
//   如果外接 RGMII接口 , GTX_CLK 总是 125MHZ，
//   接收的PHY芯片时钟rx_rgmii_clk_int为：125mhz（1gbps） 25mhz(100mbps)  2.5mhz(10mbps)
//   对应三速的时钟如下：
//
//                              1G ethernet       100 Mhz        10 Mhz
//            CORE tx/rx CLK     125   MHZ       12.5 MHZ     1.25  MHZ
//              GMII/MII CLK     125   MHZ       25   MHZ     2.5   MHZ
//                 RGMII CLK     125   MHZ       25   MHZ     2.5   MHZ
//
//  100/10Mbp速度下， GMII/RGMII接口为4位有效数据位宽，客户端8位数据位宽接口，
//                    client_tx_enable 为 gmii/rgmii_tx_enable 频率的1/2
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
// 发送器时钟使能信号产生逻辑。 产生 10/100/1000速度对应时钟 的使能信号。
//---------------------------------------------------------------------------


   tx_clk_en_gen u_tx_clk_en_gen 
   (
      .reset                (tx_reset),          //input
      .speed_10_100         (speed_10_100_int),  //input
      .speed_100            (speed_100_int),     //input
      .clk                  (gtx_clk),           //input 125mhz
      .client_txc_en        (client_txc_en_int), //output 保持1（1gbps） 12.5mhz(100mbps)  1.25mhz(10mbps) ；使能信号 一个周期（8ns）高电平
      .gmii_txc_en          (gmii_txc_en_int),   //output 保持1（1gbps） 25mhz(100mbps)    2.5mhz(10mbps)  ；使能信号 一个周期（8ns）高电平
      .rgmii_txc_en         (rgmii_txc_en),      //output 保持1（1gbps） 25mhz(100mbps)    2.5mhz(10mbps)  ；在rgmii_interface模块中输入给ODDR
      .rgmii_txc_en_shift   (rgmii_txc_en_shift) //output 保持1（1gbps） 25mhz(100mbps)    2.5mhz(10mbps)  ；在rgmii_interface模块中输入给ODDR
   );

   //---------------------------------------------------------------------------
   // 接收器时钟使能信号产生逻辑
   //---------------------------------------------------------------------------
   // 在接收器时钟域中重新同步速度选择使能信号
   
reg [1:0]speed_10_100_reg;
always@(posedge rx_rgmii_clk_int)
begin
	speed_10_100_reg <= {speed_10_100_reg[0],speed_10_100_int};
end
assign speed_10_100 = speed_10_100_reg[1]; 
   
   // 产生客户端接收时钟使能信号
   
   always @(posedge rx_rgmii_clk_int) // 125mhz（1gbps） 25mhz(100mbps)    2.5mhz(10mbps)
   begin
      if (rx_reset == 1'b1) 
      begin
         client_rxc_en_int        <= 1'b0;
      end
      else      // client_rxc_en_int  ： 保持1（1gbps） 12.5mhz(100mbps)  1.25mhz(10mbps)
      begin
         if (speed_10_100 == 1'b1)
            client_rxc_en_int     <= ~(client_rxc_en_int); 
         else
            client_rxc_en_int     <= 1'b1;
      end
   end

   //---------------------------------------------------------------------------
   // 例化 RGMII Interface
   //---------------------------------------------------------------------------

   // 例化RGMII物理接口逻辑
rgmii_interface#(
	.DEVICE				(DEVICE					)
) u1_rgmii_interface 
   (
      // 同步复位
      .tx_reset          (tx_reset),
      .rx_reset          (rx_reset),

      // 指示当前运行速度
      .speed_10_100      (speed_10_100_int),

      // 以下端口是RGMII物理接口：这些端口将位于FPGA的引脚上
      .rgmii_txd         (rgmii_txd),
      .rgmii_tx_ctl      (rgmii_tx_ctl),
      .rgmii_txc         (rgmii_txc),
      .rgmii_rxd         (rgmii_rxd),
      .rgmii_rx_ctl      (rgmii_rx_ctl),
      .rgmii_rxc         (rgmii_rxc),

      //以下信号为RGMII状态信号
      .link_status       (inband_link_status),
      .clock_speed       (inband_clock_speed),
      .duplex_status     (inband_duplex_status),

      // 以下端口连接到 TEMAC核 的 内部GMII接口模块
      .gmii_txc_en      (gmii_txc_en_int),
      .gmii_txd         (gmii_txd_int),
      .gmii_tx_en       (gmii_tx_en_int),
      .gmii_tx_er       (gmii_tx_er_int),
      .gmii_col         (gmii_col_int),
      .gmii_crs         (gmii_crs_int),
      .gmii_rxd         (gmii_rxd_int),
      .gmii_rx_dv       (gmii_rx_dv_int),
      .gmii_rx_er       (gmii_rx_er_int),
      
      //发送时钟信号
      .tx_clk            (gtx_clk),
	  .tx_clk_90         (gtx_clk_90),
      .rgmii_txc_en      (rgmii_txc_en),
      .rgmii_txc_en_shift(rgmii_txc_en_shift),
      
      //MAC核 和 客户端逻辑 的接收器时钟
      .rx_rgmii_clk      (rx_rgmii_clk_int)  //output： 125mhz（1gbps） 25mhz(100mbps)    2.5mhz(10mbps)
      );



TEMAC_CORE trimac_core(
      // 异步复位
      .reset                  	(reset),
      
      // Core Clock 
      .tx_mac_clk               (gtx_clk),           // 125mhz
      .rx_mac_clk               (rx_rgmii_clk_int),  // 125mhz（1gbps） 25mhz(100mbps)    2.5mhz(10mbps)

      // 速度指示
      .speed_1000               (speed_1000_int),
      .speed_100                (speed_100_int),
      .speed_10                 (speed_10_int),

      //客户端发送器接口
      .tx_clk_en     			(client_txc_en_int),
      .tx_data          		(tx_data),
      .tx_data_en       		(tx_data_en),
      .tx_rdy        			(tx_rdy),
      .tx_stop   			    (tx_stop),
      .tx_collision  			(tx_collision),
      .tx_retransmit 			(tx_retransmit),
      .tx_ifg_val   			(tx_ifg_val),

      // 客户端发送器状态总线
      .tx_status_vector         (tx_status_vector),
      .tx_status_vld   	        (tx_status_vld),

       // 客户端接收器接口
      .rx_clk_en     		    (client_rxc_en_int),
      .rx_data          		(rx_data),
      .rx_data_vld       		(rx_data_valid),
      .rx_correct_frame  		(rx_correct_frame),
      .rx_error_frame   		(rx_error_frame),

      // 客户接收器状态总线
      .rx_status_vector         (rx_status_vector),
      .rx_status_vld   	        (rx_status_vld),

      // 流控接口
      .pause_req     			(pause_req),
      .pause_val    		    (pause_val),
      .pause_source_addr        (pause_source_addr),

      // 默认单播地址值
      .unicast_addr     	    (unicast_address), 

      // 主机管理接口
//	  .s_axi_aclk               (s_axi_aclk), 
//	  .s_axi_awaddr             (s_axi_awaddr),   //input  wire [7 : 0]     
//	  .s_axi_awvalid            (s_axi_awvalid),  //input  wire             
//	  .s_axi_awready            (s_axi_awready),  //output wire             
//	  .s_axi_wdata              (s_axi_wdata),    //input  wire [31: 0]     
//	  .s_axi_wvalid             (s_axi_wvalid),   //input  wire             
//	  .s_axi_wready             (s_axi_wready),   //output wire             
//	  .s_axi_bresp              (s_axi_bresp),    //output wire [1 : 0]     
//	  .s_axi_bvalid             (s_axi_bvalid),   //output wire             
//	  .s_axi_bready             (s_axi_bready),   //input  wire             
//	  .s_axi_araddr             (s_axi_araddr),   //input  wire [7 : 0]     
//	  .s_axi_arvalid            (s_axi_arvalid),  //input  wire             
//	  .s_axi_arready            (s_axi_arready),  //output wire             
//	  .s_axi_rdata              (s_axi_rdata),    //output wire [31: 0]     
//	  .s_axi_rresp              (s_axi_rresp),    //output wire [1 : 0]     
//	  .s_axi_rvalid             (s_axi_rvalid),   //output wire             
//	  .s_axi_rready             (s_axi_rready),   //input  wire

	  //向量配置总线
	  .mac_cfg_vector	        (mac_cfg_vector),
      
      // gmii/mii 接口
      .gmii_tx_clken        	(gmii_txc_en_int),
      .gmii_txd             	(gmii_txd_int),
      .gmii_tx_en            	(gmii_tx_en_int),
      .gmii_tx_er            	(gmii_tx_er_int),
      .gmii_crs             	(gmii_crs_int),
      .gmii_col             	(gmii_col_int),
      .gmii_rxd             	(gmii_rxd_int),
      .gmii_rx_vld            	(gmii_rx_dv_int),
      .gmii_rx_er            	(gmii_rx_er_int),

      // MDIO接口
      .mdio_clk         		(mdio_clk),
      .mdio_oen           		(mdio_oen), //mdio输出使能（三态控制）
      .mdio_out           		(mdio_o),
      .mdio_in            		(mdio_i)
	  
   );


endmodule
