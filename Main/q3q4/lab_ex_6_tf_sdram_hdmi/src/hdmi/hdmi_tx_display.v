`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: anlgoic
// Author: 	xg 
//////////////////////////////////////////////////////////////////////////////////


module hdmi_tx_display(

		input           FPGA_SYS_50M_CLK_P,
		
		output			LED,
		
		//HDMI
		output			HDMI_CLK_P,
		output			HDMI_D2_P,
		output			HDMI_D1_P,
		output			HDMI_D0_P,
				
        //VGA
		output			VGA_HS,
		output			VGA_VS,
		output [7:0]	VGA_R,		
		output [7:0]	VGA_G,		
		output [7:0]	VGA_B			

    );
	
wire clk25m,pxlclk_5x_i;
wire pxlclk_i,locked;
	

wire 	reset;
assign  reset = 1'b0;

reg	[7:0]	rst_cnt=0;	
always @(posedge FPGA_SYS_50M_CLK_P)
begin
	if (rst_cnt[7])
		rst_cnt <=  rst_cnt;
	else
		rst_cnt <= rst_cnt+1'b1;
end

tx_pll inst
  (
  
		.refclk(FPGA_SYS_50M_CLK_P),
		.reset(!rst_cnt[7]),
		.extlock(locked),
		.clk0_out(clk25m),
		.clk1_out(pxlclk_i),
		.clk2_out(pxlclk_5x_i)
	);

reg			pat_1d,pat_2d,pat_begin;
reg	[25:0]	pattern_cnt;
reg	[3:0]	t_mode;
always @(posedge clk25m)
begin
	pattern_cnt <= pattern_cnt+1'b1;
end

always @(posedge clk25m)
begin
	pat_1d <= pattern_cnt[25];
	pat_2d <= pat_1d;
	pat_begin <= pat_1d & (!pat_2d);
end

always @(posedge clk25m)
begin
	if(!locked)
		t_mode <= 4'd1;
	else if(pat_begin)
		if(t_mode==4'd11)
			t_mode <= 4'd1;
		else
			t_mode <= t_mode+1'b1;
end
	
	
hdmi_top ux_hdmi(   
	.PXLCLK_I	(pxlclk_i),
	.PXLCLK_5X_I(pxlclk_5x_i),
	.RST_I		(reset),
	.DEN_TPG	(1'b1 ),
	.TPG_mode	(t_mode),
	.HDMI_CLK_P	(HDMI_CLK_P	),
	.HDMI_D2_P	(HDMI_D2_P	),
	.HDMI_D1_P	(HDMI_D1_P	),
	.HDMI_D0_P	(HDMI_D0_P	),	
	.VGA_HS     (VGA_HS),
	.VGA_VS	    (VGA_VS),
	.VGA_R		(VGA_R),
    .VGA_G	    (VGA_G),
    .VGA_B      (VGA_B)	
	);		
	

reg		[23:0]	cnt;	
always @(posedge pxlclk_i)
begin
	if(locked)
		cnt <= cnt+1'b1;
	else
		cnt  <= 16'd0;
end
assign LED=cnt[23];

	
endmodule
