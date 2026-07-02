
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: anlgoic
// Author: 	xg 
// description: sdram as ram top module
//////////////////////////////////////////////////////////////////////////////////



module sdr_as_ram  #( parameter self_refresh_open=1)
	( 
	    input   		Sdr_clk,
		input			Sdr_clk_sft,
        input   		Rst,
			  			  
		output			Sdr_init_done,
		output			Sdr_init_ref_vld,
		output	    	Sdr_busy,
		
		input			App_ref_req,		
		
        input						App_wr_en, 
        input  [`ADDR_WIDTH-1:0]	App_wr_addr,  	////row[10:0],bank[1:0],col[7:0]
		input	[`DM_WIDTH-1:0]		App_wr_dm,
		input	[`DATA_WIDTH-1:0]	App_wr_din,
		
		input						App_rd_en,
		input	[`ADDR_WIDTH-1:0]	App_rd_addr,
		output						Sdr_rd_en,	//synthesis keep
		output	[`DATA_WIDTH-1:0]	Sdr_rd_dout,//synthesis keep
		

		output							SDRAM_CLK,
		output  						SDR_RAS,
		output							SDR_CAS,
		output							SDR_WE,
		output		[`BA_WIDTH-1:0]		SDR_BA,
		output		[`ROW_WIDTH-1:0]	SDR_ADDR,
		output		[`DM_WIDTH-1:0]		SDR_DM,
		inout		[`DATA_WIDTH-1:0]	SDR_DQ		
		
	);
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "Anlogic"
`pragma protect encrypt_agent_info = "Anlogic Encryption Tool anlogic_2019"
`pragma protect key_keyowner = "Anlogic", key_keyname = "anlogic-rsa-002"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
mqYQZ2hbO27XWGctOsO12q0clK+Uir5kTKbIP2Bu+gr81gfEMCYdNuNziGsbOqVM
VyEqy7zu5fh91M6LFj2pXDZkRSxo0I0iqLvkueMOJqAcstR4H1CvTU3Kyme4o1ND
QPYjmIpzpnhA/I+gObsL89BoJ8129UxJkf84NwTDNKc=
`pragma protect key_keyowner = "Cadence Design Systems.", key_keyname = "CDS_RSA_KEY_VER_1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
OUuSBQlAyxtbHVYZKVjxP7ZMSmmjrhyRY/eeBh03ZL+mVwZXzvpZXOnwYediWSEu
0VY0aza5Km0bf6LOlLgwbg+rqoZ7ePwl4f72QARftkocYAlyBvUW8jW2rjAuPZUH
6xk2X5ZirqVIzytSkIv67WVJcH14JEwm2AOxIcXXm0EZWYhDkbfAyWFdfUMgTC1J
SuWaTUkx9lOigQYyKFhv0GRV4aU84OxaZ/UmqJPLHNID4o31tIJU36JMaCFQaBqS
m8i72buy/F2jEKUq9Xi+p65uIiXwmcEtIXrKl9cSVTH/oYNlHmFRduHaPfseYnkV
KxnqFDqq0ebeXjHgpQ9CAw==
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
PPRtuex+NuWsBflWSsuZ8rCqkW7RH4VZ3X1Jb4pZ42kogYfn7gXICad26ta4jLJS
YOrc8z0YXDjqjKB4wYfpkVpkvKrT23QlvIJkfV54Cx/5cOYOS7nhjY4kS2CAdTCc
NVArmUQyGqRLgHt/vq0jhb/RGMZ5Szp3UUFHAqqXmTU/Jd6xKh8qNOZKqshqpXRz
rzqF0Cc6lfzjhYMwhP8ReO0WvawgLk+b1p4AnIZPwEpsj5bRJZ9QyUgGk9ApdFWy
CC271CtHozPbBLnPrWt0SYv/5VPVQkh2F0CO2vmt9lyPMlDlKecV1+4n+Z6EdtbC
1lUfciA+dVKkzVGL4NBHgQ==
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-1"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
D3QMRhSaNdO4HCDo8REB+sYJsTGUdvF2U8K8OJOQQAQ9tli3vsqcxhs8jB71HxRt
ETajBAFCb/Kgy/nvwZ+SeodQRVHJSeEgQ4dhkSB+zHCDPkKiLJZ+esraByKENBwz
VOJOGvVU0wSacQxr7xAIte3NFWn4gbhKAVgdyJ9+wAw=
`pragma protect key_keyowner = "Mentor Graphics Corporation", key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 256)
`pragma protect key_block
MHwzdDtwVaf4mNRtjk87JmsC0Wj1jZfhZnQssPr/mLnMUg8DFYdvz85U/5RZinl2
van/PJmADBAMy8KsGzqoZu33UVqCrZOcC3MJKCSRJtlWo2iLgOJ8I4unKFzKaLsZ
TbjBbtQ0G9rrZxjFXmjnc/mpzHV07QoZ1v8VwPTwjcjnzsLBp548KVjA85PunMzL
QEfFKGsQTOuT5ABmkMueN8QpdGjcRVzxQts+tcj4RP7AkseBlo/e6t7tTehn0kPg
aAA+tnq7ZL58sHfJVQBKl2yKLRWayfFofNwdnS8f8VZIP0tmq6bX/e8jsVy1eTUW
s6Tu5No4RmRTH8F0jFLcpg==
`pragma protect key_keyowner = "Synopsys", key_keyname = "SNPS-VCS-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 128)
`pragma protect key_block
aqPyfp4VjHK64B2EJOKNji3310p9BRWbLQfFVG6wEn/mEZEnRMOG5US7Cvs78uFA
DpdUZJu1FgE55vZa/TcIx50ppIPpD1RLvKhbibEJllFU2noHV1DysyPu9H8smyUa
st6heMcbd8cjiN5dSx/vg4akpgNq8zL4XbLnvn7lzb8=
`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 64, bytes = 2160)
`pragma protect data_block
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
`pragma protect end_protected

endmodule


