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
// 		udp时钟模块
// 
// web：www.anlogic.com 
//--------------------------------------------------------------------
//
// Revision History :
//--------------------------------------------------------------------
// Revision 1.0 Date:2022/03/08 初版建立
//
//--------------------------------------------------------------------
//*******************************************************************/
module udp_clk_gen(
	input        reset,
	input [1:0]	 tri_speed,
	
	input		 clk_125_in,	//125M  
	input        clk_12_5_in,	//12.5M 
	input		 clk_1_25_in,	//1.25M 
	
	output 		 udp_clk_out	
);

parameter DEVICE 	=  "EG4";//"PH1" "EG4"

generate
if(DEVICE == "PH1")
begin
	wire clk_12p5_1p25;

	BUFGMUX#(
		.DEVICE(DEVICE)
	) 
	bufgmux_clk_12p5_1p25
	(
		.i0(clk_1_25_in		),
		.i1(clk_12_5_in		),
		.s (tri_speed[0]	),
		.o (clk_12p5_1p25	)
	);

	BUFGMUX#(
		.DEVICE(DEVICE)
	)  
	bufgmux_udp_tx_clk_out
	(
		.i0(clk_12p5_1p25	),
		.i1(clk_125_in   	),
		.s (tri_speed[1]	),
		.o (udp_clk_out 	)
	);
end
else 
begin
	reg clk_12p5_1p25;
	
	always@(*)
	begin
		if(tri_speed[0] == 1'b1)
			clk_12p5_1p25 = clk_12_5_in;
		else
			clk_12p5_1p25 = clk_1_25_in;
	end
	
	assign udp_clk_out = tri_speed[1]==1'b1 ? clk_125_in:clk_12p5_1p25;
end

endgenerate


endmodule
