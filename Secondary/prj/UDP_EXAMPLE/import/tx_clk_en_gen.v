// ===========================================================================
// Copyright (c) 2011-2020 Anlogic Inc. All Right Reserved.
//
// TEL: 86-21-61633787
// WEB: http://www.anlogic.com/
// ===========================================================================
//
//
//  
//
//
// ===========================================================================

`timescale 1 ps/1 ps

module tx_clk_en_gen
  (
      input             reset,            //tx_reset
      input             speed_10_100,
      input             speed_100,
      input             clk,              //gtx_clk/tx_clk：  125mHZ
      output   reg      client_txc_en,    //tx_clk_en
      output   reg      gmii_txc_en,
      output   reg      rgmii_txc_en,
      output   reg      rgmii_txc_en_shift
   );
//----------------------------------------------------------------
//模块内部信号
   reg   [5:0]          counter;
   reg   [5:0]          divide_val;
   reg   [5:0]          first_edge;
   reg   [5:0]          second_edge;
   reg                  client_txc_en_int;
   wire                 speed_10_100_int;
   wire                 speed_100_int;
   reg                  rgmii_txc_en_int;
   reg                  rgmii_txc_en_shift_int;
 
//---------------------------------------------------------------- 
// 本地同步速度指示信号
reg [1:0]speed_10_100_reg;
always@(posedge clk)
begin
	speed_10_100_reg <= {speed_10_100_reg[0],speed_10_100};
end
assign speed_10_100_int = speed_10_100_reg[1]; 

reg [1:0]speed_100_reg;
always@(posedge clk)
begin
	speed_100_reg <= {speed_100_reg[0],speed_100};
end
assign speed_100_int = speed_100_reg[1]; 

//---------------------------------------------------------------- 
// 产生一个6位计数器，然后 自动计数值 取决于 速度设置
    always @(posedge clk)
    begin
       if (reset) 
       begin
          counter <= 0;
       end
       else 
       begin
          if (counter >= divide_val) // 1Gbps时：divide_val = 0；counter = 0
          begin
             counter <= 0;
          end
          else 
          begin
             counter <= counter + 1;
          end
       end
    end

    always @(speed_10_100_int or speed_100_int)
    begin
       if (!speed_10_100_int) // 1Gbps
       begin
          divide_val                 = 0;
          first_edge                 = 0;
          second_edge                = 0;
       end
       else 
       begin
          if (speed_100_int) // 100Mbps
          begin
             divide_val                 = 4;  // 125mhz/5=25mhz 
             first_edge                 = 1;  
             second_edge                = 2;
          end
          else              // 10Mbps
          begin
             divide_val                 = 49; // 125mhz/50=2.5mhz 
             first_edge                 = 23;
             second_edge                = 24;
          end
       end
    end

    //---------------------------------------------------------------- 
    //生成 rgmii_txc时钟使能 信号(在rgmii_interface模块中输入给ODDR) - 仅在速度 10/100Mbps时（不为1Gbps）
    always @(posedge clk)
    begin
       if (reset) 
       begin
          rgmii_txc_en_int         <= 0;
          rgmii_txc_en_shift_int   <= 0;
       end
       else 
       begin
          if (speed_10_100_int)    // 10/100Mbps
          begin                    // 在rgmii_interface模块中输入给ODDR，100Mbps对应产生rgmii_txc=25mhz,10Mbps对应产生rgmii_txc=2.5mhz,
             if (counter >= divide_val) 
             begin
                rgmii_txc_en_int         <= 1;
                rgmii_txc_en_shift_int   <= 1;
             end
             else if (counter == first_edge) //rgmii_txc_en_shift_int高电平持续时间比rgmii_txc_en_int多一拍
             begin
                rgmii_txc_en_int         <= 0;
                rgmii_txc_en_shift_int   <= 1;
             end
             else if (counter == second_edge) 
             begin
                rgmii_txc_en_int         <= 0;
                rgmii_txc_en_shift_int   <= 0;
             end
          end
          else                  // 1Gbps
          begin                 // 在rgmii_interface模块中输入给ODDR，产生rgmii_txc=125mhz
             rgmii_txc_en_int            <= 0;
             rgmii_txc_en_shift_int      <= 1;
          end
       end
    end

    //---------------------------------------------------------------- 
     //需要控制使能和时钟之间的流水线延迟，以确保IO的正确时序
    always @(posedge clk)
    begin
       if (reset) 
       begin
          rgmii_txc_en                   <= 0;
          rgmii_txc_en_shift             <= 0;
       end
       else 
       begin
          rgmii_txc_en                   <= rgmii_txc_en_int;
          rgmii_txc_en_shift             <= rgmii_txc_en_shift_int;
       end
    end

    //---------------------------------------------------------------- 
    // client_txc时钟使能-我们要每隔一个脉冲生成第二个使能
    always @(posedge clk)
    begin
       if (reset) 
       begin
          client_txc_en_int <= 0;
       end
       else 
       begin
          if (speed_10_100_int) // 10/100Mbps
          begin
             if (counter >= divide_val) 
             begin
                client_txc_en_int <= !client_txc_en_int; //100Mbps对应产生 client_txc=12.5mhz,10Mbps对应产生 client_txc =1.25mhz
             end
          end
          else          
          begin
             client_txc_en_int <= 0;
          end
       end
    end

    //---------------------------------------------------------------- 
     //需要控制MAC使能和时钟之间的流水线延迟，以确保IO的正确时序：  gmii_txc_en高电平比 rgmii_txc_en高电平 早一个时钟周期

    always @(posedge clk)
    begin
       if (reset) 
       begin
          client_txc_en         <= 0;
          gmii_txc_en           <= 0;
       end
       else // 
       begin
       
          if (counter >= divide_val) //100Mbps对应产生 gmii_txc_en=25mhz,10Mbps对应产生 gmii_txc_en =2.5mhz
          begin
             gmii_txc_en           <= 1;  // gmii_txc_en 一个周期（8ns）高电平
          end  // 1Gbps时：divide_val = 0；counter = 0; 对应产生 gmii_txc_en = 1; 对应产生 gmii_tx_clk = 125mhz
          else 
          begin  
             gmii_txc_en           <= 0;
          end
          
          if ((counter >= divide_val) & !client_txc_en_int) //100Mbps对应产生 client_txc=12.5mhz,10Mbps对应产生 client_txc =1.25mhz
          begin
             client_txc_en        <= 1; //  一个周期（8ns）高电平
          end   // 1Gbps时：divide_val = 0；counter = 0; 对应产生 client_txc_en = 1;  对应产生client_txc =125mhz
          else 
          begin
             client_txc_en        <= 0;
          end
       end
    end



endmodule

