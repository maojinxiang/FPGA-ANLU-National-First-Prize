

`timescale 1ns/1ps


module tb();

//-------------------------------------------
reg clk_in,Rst;

wire HDMI_CLK_P;
wire HDMI_CLK_N;
wire HDMI_D2_P;
wire HDMI_D2_N;
wire HDMI_D1_P;
wire HDMI_D1_N;
wire HDMI_D0_P;
wire HDMI_D0_N;

//-------------------------------------------

initial
begin
    clk_in      = 0;  
end

always #20 clk_in = ~clk_in;  

initial
begin 
    #500
    Rst =1;
    #100; 
    Rst =0;
end


/*
initial
  begin
    $fsdbDumpfile("tb_lvds_test.fsdb");
    $fsdbDumpvars;
end
*/
//-----------------master-----------------------------


hdmi_display dut(
		.FPGA_SYS_25M_CLK_P(clk_in),

		.LED(),

		.HDMI_CLK_P(),
		.HDMI_D2_P(),
		.HDMI_D1_P(),
		.HDMI_D0_P()

    );



PH1_PHY_GSR PH1_PHY_GSR();
glbl glbl();

endmodule

