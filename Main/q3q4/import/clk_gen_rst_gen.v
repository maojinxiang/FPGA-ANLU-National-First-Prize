`timescale 1ns / 1ps
//******************************************************************** 
// -------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>Copyright Notice<<<<<<<<<<<<<<<<<<<<<<<<<<<< 
// ------------------------------------------------------------------- 
//             /\ --------------- 																
//            /  \ ------------- 												
//           / /\ \ -----------													
//          / /  \ \ ---------	  									
//         / /    \ \ ------- 	  														
//        / /      \ \ ----- 															
//       / /_ _ _   \ \ --- 												
//      /_ _ _ _ _\  \_\ -	 																	
//--------------------------------------------------------------------
// Author: suluyang 
// Email:luyang.su@anlogic.com 
// Date:2022/03/08
// Description: 
// 		时钟复位输出模块
// 
// web：www.anlogic.com 
//--------------------------------------------------------------------
//
// Revision History :
//--------------------------------------------------------------------
// Revision 1.0 Date:2022/03/08 初版建立
//
//
//--------------------------------------------------------------------
//*******************************************************************/
module clk_gen_rst_gen(
	input        reset,
	input        clk_in,
	
	output       rst_out,
	output 		 clk_125_out0,
	output 		 clk_125_out1,
	output 		 clk_125_out2,
	output 		 clk_12_5_out,
	output 		 clk_1_25_out,
	output 		 clk_25_out	
);
parameter  DEVICE             = "EG4";//"PH1","EG4"
wire extlock;
assign rst_out = !extlock;

generate
if(DEVICE == "EG4")
begin
	pll_gen	u_pll_0(
		.refclk  		(clk_in			),//50.000Mhz
		.reset   		(reset  		),
		.extlock 		(extlock		),//Frequency 	| Phase shift
		.clk0_out		(clk_125_out0	),//125.000000MHZ	| 0  DEG     
		.clk1_out		(clk_125_out1	),//125.000000MHZ	| 0  DEG     
		.clk2_out		(clk_12_5_out	),//12.500000 MHZ	| 0  DEG     
		.clk3_out		(clk_25_out  	),//25.000000 MHZ	| 0  DEG  
		.clk4_out		(clk_125_out2  	)
	);
end
else if(DEVICE == "PH1")
begin
	pll_gen u_pll_0(
		.refclk  		(clk_in			),
		.reset   		(reset  		),
		.lock       	(extlock		),
		.clk0_out		(clk_125_out0	),
		.clk1_out		(clk_125_out1	),
		.clk2_out		(clk_12_5_out	),
		.clk3_out		(clk_25_out  	),
		.clk4_out		(clk_125_out2  	)
	);
end

endgenerate


div_clk_gen u_udp_clk_gen_1p25(
	.reset			(!extlock		),
	.clk_en			(1'b1			),
	.clk_in			(clk_12_5_out	),
	.clk_out		(clk_1_25_out   )
);

endmodule
