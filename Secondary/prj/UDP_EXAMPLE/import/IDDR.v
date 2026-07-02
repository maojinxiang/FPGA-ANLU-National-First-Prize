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
//********************************************************************
// Author: suluyang 
// Email:luyang.su@anlogic.com 
// Date:2020/10/16 
// Description: 
// 1.0:Date:2020/10/16 通用IDDR模块建立，支持PH1器件和EG4器件
// web：www.anlogic.com 
//-------------------------------------------------------------------- 
//*******************************************************************/
module IDDR (
        q1,
        q0,
        clk,
        d,
        rst
);
output           q1;
output           q0;
input            clk;
input            d;
input            rst;
parameter ASYNCRST      = "ENABLE";     //ENABLE, DISABLE
parameter PIPEMODE      = "PIPED";      //PIPED, NONE
parameter DEVICE 		= "PH1";//"PH1" "EG4" "PH1A400"

generate 
if(DEVICE == "EG4")
begin
	EG_LOGIC_IDDR #(
		.ASYNCRST(ASYNCRST),     //ENABLE, DISABLE
		.PIPEMODE(PIPEMODE)      //PIPED, NONE
	)
	u_iddr
	(
		.q1	(q1	),
		.q0	(q0	),
		.clk(clk),
		.d	(d	),
		.rst(rst)
	);		
end
else if(DEVICE == "PH1")
begin
	PH1_LOGIC_IDDR #(
		.ASYNCRST(ASYNCRST),     //ENABLE, DISABLE
		.PIPEMODE(PIPEMODE)      //PIPED, NONE
	)
	u_iddr
	(
		.q1	(q1	),
		.q0	(q0	),
		.clk(clk),
		.d	(d	),
		.rst(rst)
	);		
end
endgenerate

endmodule