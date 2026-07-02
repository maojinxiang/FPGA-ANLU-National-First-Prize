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
// Date:2020/10/22 
// Description: 
// 		时钟分频输出模块
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
module div_clk_gen(
	input        reset,
	input		 clk_en,
	input        clk_in,
	output 		 clk_out
);

reg div_reg1;
reg div_reg2;
reg div_reg3;
reg div_reg4;
reg div_reg5;

always@(posedge clk_in or posedge reset)
begin
	if(reset == 1'b1)
	begin
		div_reg1 <= 1'b0;
		div_reg2 <= 1'b0;
		div_reg3 <= 1'b0;
		div_reg4 <= 1'b0;
		div_reg5 <= 1'b0;
	end
	else if(clk_en == 1'b1)
	begin
		div_reg1 <= !div_reg5;
		div_reg2 <= div_reg1;
		div_reg3 <= div_reg2;
		div_reg4 <= div_reg3;
		div_reg5 <= div_reg4;	
	end
end

assign clk_out = div_reg3;

endmodule
