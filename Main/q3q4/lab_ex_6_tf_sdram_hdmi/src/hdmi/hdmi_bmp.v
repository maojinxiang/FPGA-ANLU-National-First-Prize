module hdmi_bmp
(
    input                 sys_clk      ,  //系统时钟
    input                 sys_rst_n    ,  //系统复位，低电平有效
	input	[7:0]	      cnt138       ,	                 
    //hdmi接口                           
    output			HDMI_CLK_P,
	output			HDMI_D2_P,
	output			HDMI_D1_P,
	output			HDMI_D0_P,
    
    //VGA_TEST
	output			VGA_HS,
	output			VGA_VS,
    	output [7:0]	VGA_R,		
		output [7:0]	VGA_G,		
		output [7:0]	VGA_B		
);



clk_wize u_clk_wize (
  .refclk(sys_clk),
  .reset(1'b0),
  .clk0_out(pixel_clk_5x),
  .clk1_out(pixel_clk)
);

//例化HDMI驱动模块
hdmi_top u_hdmi_top(
    .PXLCLK_I(pixel_clk),
    .PXLCLK_5X_I(pixel_clk_5x),
    .RST_I(sys_rst_n),
	.cnt138		(cnt138),
    
    .DEN_TPG(1'b0),
    
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    
        
    .HDMI_CLK_P   (HDMI_CLK_P),
    .HDMI_D2_P   (HDMI_D2_P),
    .HDMI_D1_P  (HDMI_D1_P),
    .HDMI_D0_P  (HDMI_D0_P)
);
endmodule


