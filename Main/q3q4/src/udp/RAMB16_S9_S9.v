
`timescale 1ns / 1ps

module RAMB16_S9_S9 ( 
	doa, dia, addra, cea, clka, wea,
	dob, dib, addrb, ceb, clkb, web
);

parameter  			 	DEVICE            = "PH1";//"PH1","EG4"

	output [8:0] doa;
	output [8:0] dob;


	input  [8:0] dia;
	input  [8:0] dib;
	input  [10:0] addra;
	input  [10:0] addrb;
	input  wea;
	input  web;
	input  cea;
	input  ceb;
	input  clka;
	input  clkb;


generate 
if(DEVICE == "EG4")
begin
	EG_LOGIC_BRAM #( .DATA_WIDTH_A(9),
				.DATA_WIDTH_B(9),
				.ADDR_WIDTH_A(11),
				.ADDR_WIDTH_B(11),
				.DATA_DEPTH_A(2048),
				.DATA_DEPTH_B(2048),
				.MODE("DP"),
				.REGMODE_A("NOREG"),
				.REGMODE_B("NOREG"),
				.WRITEMODE_A("WRITETHROUGH"),
				.WRITEMODE_B("WRITETHROUGH"),
				.RESETMODE("SYNC"),
				.IMPLEMENT("9K"),
				.INIT_FILE("NONE"),
				.FILL_ALL("NONE"))
			inst(
				.dia(dia),
				.dib(dib),
				.addra(addra),
				.addrb(addrb),
				.cea(cea),
				.ceb(ceb),
				.ocea(1'b0),
				.oceb(1'b0),
				.clka(clka),
				.clkb(clkb),
				.wea(wea),
				.web(web),
				.bea(1'b0),
				.beb(1'b0),
				.rsta(1'b0),
				.rstb(1'b0),
				.doa(doa),
				.dob(dob));
end
else if(DEVICE == "PH1" )
begin
	PH1_LOGIC_ERAM #( .DATA_WIDTH_A(9),
			.DATA_WIDTH_B(9),
			.ADDR_WIDTH_A(11),
			.ADDR_WIDTH_B(11),
			.DATA_DEPTH_A(2048),
			.DATA_DEPTH_B(2048),
			.MODE("DP"),
			.REGMODE_A("NOREG"),
			.REGMODE_B("NOREG"),
			.WRITEMODE_A("WRITETHROUGH"),
			.WRITEMODE_B("WRITETHROUGH"),
			.IMPLEMENT("20K"),
			.ECC_ENCODE("DISABLE"),
			.ECC_DECODE("DISABLE"),
			.CLKMODE("ASYNC"),
			.SSROVERCE("DISABLE"),
			.OREGSET_A("SET"),
			.OREGSET_B("SET"),
			.RESETMODE_A("SYNC"),
			.RESETMODE_B("SYNC"),
			.ASYNC_RESET_RELEASE_A("SYNC"),
			.ASYNC_RESET_RELEASE_B("SYNC"),
			.INIT_FILE("NONE"),
			.FILL_ALL("NONE"))
		inst(
			.dia(dia),
			.dib(dib),
			.addra(addra),
			.addrb(addrb),
			.cea(cea),
			.ceb(ceb),
			.ocea(1'b0),
			.oceb(1'b0),
			.clka(clka),
			.clkb(clkb),
			.wea(wea),
			.web(web),
			.bea(1'b0),
			.beb(1'b0),
			.rsta(1'b0),
			.rstb(1'b0),
			.doa(doa),
			.ecc_sbiterr(open),
			.ecc_dbiterr(open),
			.dob(dob));
end
endgenerate




endmodule