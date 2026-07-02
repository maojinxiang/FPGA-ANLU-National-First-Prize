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
// Date:2020/10/21
// Description: 
// 		BUFGMUX，支持PH1器件和EG4器件
// 
// web：www.anlogic.com 
//--------------------------------------------------------------------
//
// Revision History :
//--------------------------------------------------------------------
// Revision 1.0 Date:2020/10/21 初版建立
//
//
//--------------------------------------------------------------------
//*******************************************************************/

module BUFGMUX(
	output wire o,  // 1-bit output: Clock output
	input  wire i0, // 1-bit input: Clock input (S=0)
	input  wire i1, // 1-bit input: Clock input (S=1)
	input  wire s   // 1-bit input: Clock select
);
parameter DEVICE 		= "EG4";//"PH1","EG4"
parameter INIT_OUT 		= "0";
parameter PRESELECT_I0 	= "TRUE";
parameter PRESELECT_I1 	= "FALSE";

generate 
if(DEVICE == "EG4")
begin
	EG_LOGIC_BUFGMUX#(
		.INIT_OUT 		(INIT_OUT 	 ),	
		.PRESELECT_I0  	(PRESELECT_I0),
		.PRESELECT_I1  	(PRESELECT_I1)
	)
	u_bufgmux
	(
		.o	(o	),
		.i0	(i0),
		.i1	(i1),
		.s	(s )
	); 
end
else if(DEVICE == "PH1")
begin
	reg [1:0]seln;	
	reg [1:0]cen;	

	always@(*)
	begin
		if(s==1'b1)
		begin
			seln <= 2'b00;
			cen	 <= 2'b01;
		end
		else
		begin
			seln <= 2'b00;
			cen	 <= 2'b10;	
		end
	end


	PH1_PHY_GCLK_V2#(
		.PRESELECT	("CLK0"	),
		.HOLD 		("YES"	),
		.SEL_TRIGGER("POS"	)
	)
	u_bufgmux
	(
		.seln		(seln	),
		.cen		(cen	),
		.drct		(2'b00	),//无毛刺切换使能，当drct=2’b00实现无毛刺切换
		.clkin		({i1,i0}),
		.clkout		(o		)
	);
end
endgenerate

endmodule