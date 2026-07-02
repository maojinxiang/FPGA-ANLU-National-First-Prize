
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: anlgoic
// Author: 	xg 
// description: sdram init and refresh
//////////////////////////////////////////////////////////////////////////////////

`define signle_bit 0


module sdr_init_ref #( parameter self_refresh_open=1
			)
	(
	    input   		Sdr_clk,
        input   		Rst,
			  			  
		////change sdr work mode
		input			Sdr_init_req,
        input	[3:0]	Sdr_init_mode, ////[2:0]: Burst Lenth, [3]:M9 ,1=sigle write
		output 			Sdr_init_done,
		
		////check wrtie and read busy	
		input			App_ref_req,	
		output			Sdr_ref_req,	//it must have 4096 refersh command in 64ms,send 1 time in 15.625ms
		input			Sdr_ref_ack,
		input			Sdr_rw_vld,

		output			Sdr_init_ref_vld,
        output			Sdr_init_ref_ras,
		output			Sdr_init_ref_cas,
		output			Sdr_init_ref_we,
		output	[`BA_WIDTH-1:0]	Sdr_init_ref_ba,
		output	[`ROW_WIDTH:0]	Sdr_init_ref_addr
	);


reg		[17:0]	pwr_200ms_cnt;
reg 			power_up_200ms_1d,power_up_200ms_2d,power_up_en;

reg 			sdr_init_en;
reg 	[31:0]	sdr_init_cnt=32'd0;
reg 			init_vld,init_done;
reg		[13:0]	init_cnt;
reg		[19:0]	sdr_ref_ack_sft;
reg				ref_req,ref_vld;

reg 					ras,cas,we;
reg 	[`ROW_WIDTH:0]	ad;
reg						cke;


//pipe
always @(posedge Sdr_clk)
begin
	if(Rst)
		pwr_200ms_cnt <= 17'd0;
	else if(pwr_200ms_cnt[17])
		pwr_200ms_cnt <= pwr_200ms_cnt;
	else
		pwr_200ms_cnt <= pwr_200ms_cnt+1'b1;
	
	power_up_200ms_1d <= pwr_200ms_cnt[17];
	power_up_200ms_2d <= power_up_200ms_1d;
	power_up_en <= power_up_200ms_1d & (!power_up_200ms_2d);
	
	sdr_init_en <= power_up_en | Sdr_init_req;
end

//sdr init cnt
always @(posedge Sdr_clk)
begin  
  		sdr_init_cnt[0]<= sdr_init_en;	
		sdr_init_cnt[31:1]<=sdr_init_cnt[30:0];
end	

always @(posedge Sdr_clk)
begin  
	if (sdr_init_cnt[30] || Rst)     ////valid 15 clk
        init_vld <= 1'b0;   
	else if (sdr_init_cnt[0]) 
	    init_vld <= 1'b1;
end
always @(posedge Sdr_clk)
begin  
	if (sdr_init_en || Rst)
	    init_done <= 1'b0;
	else if (sdr_init_cnt[30])
	    init_done <= 1'b1;
end
assign Sdr_init_ref_vld = init_vld || ref_vld;	
assign Sdr_init_done = init_done;


////init cunt
always @(posedge Sdr_clk)
begin  
	if (Rst || (!init_done))
        init_cnt <= 14'd0;   
	else
		if(init_cnt==`SELF_REFRESH_INTERVAL)
			init_cnt <= 14'd0;
		else
			init_cnt <= init_cnt+1'b1;
end

////ref ack shift
always @(posedge Sdr_clk)
begin  
	if (Rst)
		sdr_ref_ack_sft <= 'd0;
	else
		begin
			sdr_ref_ack_sft[0]	<= Sdr_ref_ack;
			sdr_ref_ack_sft[19:1]	<= sdr_ref_ack_sft[18:0];
		end
end


////self refresh
always @(posedge Sdr_clk)
begin  
	if (Rst)
		begin
			ref_req <= 1'd0;   
			ref_vld <= 1'b0;
		end
	else begin
		if(self_refresh_open)
			if(init_cnt==(`SELF_REFRESH_INTERVAL-10) && (!Sdr_ref_ack))	////if previous ack allign current ref req
				ref_req <= 1'b1;
			else
				ref_req <= 1'b0;
		else
			ref_req <= 1'b0;

			
		if(Sdr_ref_ack && (~Sdr_rw_vld))
			ref_vld <= 1'b1;
		else if(sdr_ref_ack_sft[19])
			ref_vld <= 1'b0;
	
	end
end
assign Sdr_ref_req=ref_req | App_ref_req;


`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "Anlogic"
`pragma protect encrypt_agent_info = "Anlogic Encryption Tool anlogic_2019"
`pragma protect key_keyowner = "Anlogic", key_keyname = "anlogic-rsa-002"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
TumXHV+P0RyZ4ox5uovO9rYKSsZ+goeH+Nvax/Qe9iRNV6lmarae89CBhqgteudw
6fSt/8+quJJJMhW7rzHwVJ7ELN5PbYQ+gi3ozB0xtPSCYhNA2v5rvnUx7wM/ogv1
WK3OCtcFQgoO1demZOoziLLEML5ofCcdH0UDzFKYhkQ=
`pragma protect key_keyowner = "Cadence Design Systems.", key_keyname = "CDS_RSA_KEY_VER_1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
WkdJDJQFEI60Lxqf3dP/AzkllP6Xyl6jspaTmYWgiYjaU3LVvEIaL1ZAJgr2k4wU
fgbMRYzlLigEOVL2+o4Ytq4morPldPZtP8W/h8UYsEoYJ+3wiOQr4i/bxpzp17iy
uJlS/htv+zOnTNJ/2U/u8HVskBzAOpTcIWuVCFlevf1wHJ7TpYM8AKMsL9Zr8xsm
P80WzV1BF4Fkm3owrm5+Px9EYNckhyaGtwDLOO0YEZoIpMTXyeIozt1Zj1G6Qn5q
Pg2uFTsHCv5mXnfUIlwkQM/W+md1RgkZ4RvKYZnnj4nZTvBbUCURiZHUPjZSH7NI
P0J4nCtvSJ8KGUnVbvidog==
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
eF9dLrxQRR+B5Kv9F9yX/3FsrnDpO16NyEpXKNQkUsscZNhOhgUgYrCKMP6XL3U8
UnUuMQM1dcZxIMVw3EY2tCTZoMNu75+vaxk62cefvAoNnmiqwNddk00dx7kgYxE4
lpDG+r1f9MMr8/Lep9aePbrnG8aBuTgug5nCl0uC72s87wZZuprLhT+tqR273jwC
fPwAviKsaw3OD5veQ8cMZNzMERyAOMt2CCp9SexjicSt/sW0fPrCBckmu3TvbYso
K9WFgiK6UBs3gwOHs7RnuX9zyoPfQPcVR2LYyPmDnirl637y4df7zxSFzeOkDZ5Z
UBGPVkx33id4vlcUHtRZRQ==
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
bFJ9XZwFzu1grbRSOpiDrSbdLZZGWuvNyLuz9SzVM1wVp96HfwIK0gtPvZvGISCL
rYZbkJkmm3ZVhpr/UNaO8/xCQeNzMQVbsGPUSnXYPvNPwdkTyFoa4RjTKrnZR346
h4RpywtoQCyPZQVsiJjhoK3T7rIIa+gLRW03+MVegjw=
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
lh92RutLHCXJmVHmr2ZVkOi3Lcecorqzr0WpBnY9s4Ox6lRkWK13lhfVd6kiIwn2
9JyELzPr9qbruKPPQJXWfLjYiz8wQvglbAhQC8YfgrtaVetePAy9A+ozLd/M+e3P
+9T3QSBI4YlaRuq2y6EH74Gtu4olQYGOcX3h/dwG3m6IO1i1nRHqFIspppJF/wEa
cfUElBJ0tEQy8K5wcNGR4Ng0dnem0FasWuBUfmOW6xgzq+VJfoCAFeOhd/sr2Y8e
rHVxb8OhMHuIxDwVHLmhlz9TWl7ZDmNMQKhwDF76oDGI6sWsY4YxTf0aaRzPYkOP
/ltOnZKfwW0dE++NXm7FXw==
`pragma protect key_keyowner = "Synopsys", key_keyname = "SNPS-VCS-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
bqq41wkOj1YfCyQETBk6cgEYsqvl1tXpSZW+iVwg6wjcVefG2agb2S0MPUqul7FE
+Qn7lruOTNWMPQfJo6G7gm7izX54svUuTeIysTFDGTdWBCfoJFZI+Mh52lqmAtUB
/rja9FrthXkqbcIOqirkzR8V7aTRc+ez9Q6it5pDeG4=
`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 1728)
`pragma protect data_block
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
`pragma protect end_protected	
	
endmodule


