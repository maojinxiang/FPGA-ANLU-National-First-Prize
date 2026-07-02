module top(
	input                       clk,
	input                       rst_n,
    
    
    
	input                       key1,
    
    
    
	output [5:0]                seg_sel,
	output [7:0]                seg_data,	
    
    output			vga_out_hs,
    output			vga_out_vs,
//    output			vga_out_de,
    output	[11:0]	vga_data,
    //hdmi接口                         
	//HDMI
	output			HDMI_CLK_P,
	output			HDMI_D2_P,
	output			HDMI_D1_P,
	output			HDMI_D0_P,
	output                      sd_ncs,            //SD card chip select (SPI mode)
	output                      sd_dclk,           //SD card clock
	output                      sd_mosi,           //SD card controller data output
	input                       sd_miso           //SD card controller data input
);

parameter MEM_DATA_BITS         = 32  ;            //external memory user interface data width
parameter ADDR_BITS             = 21  ;            //external memory user interface address width
parameter BUSRT_BITS            = 10  ;            //external memory user interface burst width

    wire			vga_out_de;

wire Sdr_init_done;
wire Sdr_init_ref_vld;
wire Sdr_busy;


wire                            read_req;
wire                            read_req_ack;
wire                            read_en;
wire                            write_en;
wire                            write_req;
wire                            write_req_ack;
wire                            sd_card_clk;       //SD card controller clock
wire                            ext_mem_clk;       //external memory clock
wire                            ext_mem_clk_sft;

wire                            video_clk;         //video pixel clock
wire							hdmi_5x_clk;
wire                            hs;
wire                            vs;
wire 							de;
wire[23:0]                      vout_data;
wire[3:0]                       state_code;
wire[6:0]                       seg_data_0;


wire									  write_clk;
wire									  read_clk;

wire                            video_read_req;
wire                            video_read_req_ack;
wire                            video_read_en;
wire[31:0]                      video_read_data;
wire                            sd_card_write_en;
wire[31:0]                      sd_card_write_data;
wire                            sd_card_write_req;
wire                            sd_card_write_req_ack;

wire App_rd_en;
wire [ADDR_BITS-1:0] App_rd_addr;
wire Sdr_rd_en;
wire [MEM_DATA_BITS - 1 : 0]Sdr_rd_dout;

wire App_wr_en;
wire [ADDR_BITS-1:0] App_wr_addr;
wire [MEM_DATA_BITS - 1 : 0]App_wr_din;
wire [3:0] App_wr_dm;


wire video_rd_en;
wire sd_card_wr_en;


wire Rd_state_end;

assign vga_out_hs = hs;
assign vga_out_vs = vs;
assign vga_out_de = de;
assign vga_data = {vout_data[23:20],vout_data[15:12],vout_data[7:4]};
//assign vga_out_r  = vout_data[15:11];
//assign vga_out_g  = vout_data[10:5];
//assign vga_out_b  = vout_data[4:0];
assign sdram_clk = ext_mem_clk;
//generate SD card controller clock and  SDRAM controller clock
sys_pll sys_pll_m0(
	.refclk                     (clk),
	.clk0_out                   (sd_card_clk),
	.clk1_out                   (ext_mem_clk),
    .clk2_out					(ext_mem_clk_sft),
    .reset						(1'b0)
    );
//generate video pixel clock	
video_pll video_pll_m0(
	.refclk                     (clk),
	.clk0_out                   (video_clk),
    .clk1_out					(hdmi_5x_clk),
    .reset						(1'b0)
	);
	
//SD card BMP file read
sd_card_bmp  sd_card_bmp_m0(
	.clk                        (sd_card_clk              ),
	.rst                        (~rst_n ),
	.key                        (key1                     ),
	.state_code                 (state_code               ),
	.bmp_width                  (16'd640                 	),  //image width
	.write_req                  (sd_card_write_req        ),
	.write_req_ack              (sd_card_write_req_ack    ),
	.write_en                   (sd_card_write_en         ),
	.write_data                 (sd_card_write_data       ),
	.SD_nCS                     (sd_ncs                   ),
	.SD_DCLK                    (sd_dclk                  ),
	.SD_MOSI                    (sd_mosi                  ),
	.SD_MISO                    (sd_miso                  )
);

//with a digital display of state_code
// 0:SD card is initializing
// 1:wait for the button to press
// 2:looking for the BMP file
// 3:wait for the fifo
// 4:reading
seg_decoder seg_decoder_m0(
	.bin_data                   (state_code               ),
	.seg_data                   (seg_data_0               )
);

seg_scan seg_scan_m0(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.seg_sel                    (seg_sel                  ),
	.seg_data                   (seg_data                 ),
	.seg_data_0                 ({1'b1,7'b1111_111}       ),
	.seg_data_1                 ({1'b1,7'b1111_111}       ),
	.seg_data_2                 ({1'b1,7'b1111_111}       ),
	.seg_data_3                 ({1'b1,7'b1111_111}       ),
	.seg_data_4                 ({1'b1,7'b1111_111}       ),
	.seg_data_5                 ({1'b1,seg_data_0}        )
);
wire hs_0;
wire vs_0;
wire de_0;
video_timing_data video_timing_data_m0
(
	.video_clk                  (video_clk                ),
	.rst                        (~rst_n    ),
	.read_req                   (video_read_req           ),
	.read_req_ack               (video_read_req_ack       ),
	//.read_en                    (video_read_en            ),
	//.read_data                  (video_read_data          ),
	.hs                         (hs_0                       ),
	.vs                         (vs_0                       ),
	.de                         (de_0                         )
	//.vout_data                  (vout_data                )
);
video_delay video_delay_m0
(
    .video_clk                  (video_clk                ),
	.rst                        (~rst_n    ),
    .read_en					(video_read_en),
    .read_data					(video_read_data[31:8]),
    .hs                         (hs_0                       ),
	.vs                         (vs_0                       ),
	.de                         (de_0                         ),
	.hs_r                       (hs                       ),
	.vs_r                       (vs                       ),
	.de_r                       (de                       ),
	.vout_data					(vout_data)
);
hdmi_tx #(.FAMILY("EG4"))	//EF2、EF3、EG4、AL3、PH1

 u3_hdmi_tx
	(
		.PXLCLK_I(video_clk),
		.PXLCLK_5X_I(hdmi_5x_clk),

		.RST_N (rst_n),
		
		//VGA
		.VGA_HS (hs ),
		.VGA_VS (vs ),
		.VGA_DE (de ),
		.VGA_RGB(vout_data),

		//HDMI
		.HDMI_CLK_P(HDMI_CLK_P),
		.HDMI_D2_P (HDMI_D2_P ),
		.HDMI_D1_P (HDMI_D1_P ),
		.HDMI_D0_P (HDMI_D0_P )	
		
	);
//video frame data read-write control
frame_read_write frame_read_write_m0(
    .mem_clk					(ext_mem_clk),
    .rst						(~rst_n),
    .Sdr_init_done				(Sdr_init_done),
    .Sdr_init_ref_vld			(Sdr_init_ref_vld),
    .Sdr_busy					(Sdr_busy),
    
    .App_rd_en					(App_rd_en),
    .App_rd_addr				(App_rd_addr),
    .Sdr_rd_en					(Sdr_rd_en),
    .Sdr_rd_dout				(Sdr_rd_dout),
    
    .read_clk                   (video_clk           ),
	.read_req                   (video_read_req           ),
	.read_req_ack               (video_read_req_ack       ),
	.read_finish                (                   ),
	.read_addr_0                (24'd0              ), //first frame base address is 0
	.read_addr_1                (24'd0              ),
	.read_addr_2                (24'd0              ),
	.read_addr_3                (24'd0              ),
	.read_addr_index            (2'd0               ), //use only read_addr_0
	.read_len                   (24'd307200         ), //frame size//24'd786432
	.read_en                    (video_read_en            ),
	.read_data                  (video_read_data          ),
    
    .App_wr_en					(App_wr_en),
    .App_wr_addr				(App_wr_addr),
    .App_wr_din					(App_wr_din),
    .App_wr_dm					(App_wr_dm),
    
    .write_clk                  (sd_card_clk        ),
	.write_req                  (sd_card_write_req        ),
	.write_req_ack              (sd_card_write_req_ack    ),
	.write_finish               (                 ),
	.write_addr_0               (24'd0            ),
	.write_addr_1               (24'd0            ),
	.write_addr_2               (24'd0            ),
	.write_addr_3               (24'd0            ),
	.write_addr_index           (2'd0             ), //use only write_addr_0
	.write_len                  (24'd307200       ), //frame size
	.write_en                   (sd_card_write_en         ),
	.write_data                 (sd_card_write_data       )
);

sdram U3
(
.Clk				(ext_mem_clk),
.Clk_sft			(ext_mem_clk_sft),
.Rst				(~rst_n),
    
.Sdr_init_done		(Sdr_init_done),
.Sdr_init_ref_vld	(Sdr_init_ref_vld),
.Sdr_busy			(Sdr_busy),
    
.App_wr_en			(App_wr_en),
.App_wr_addr		(App_wr_addr),  	
.App_wr_dm			(App_wr_dm),
.App_wr_din			(App_wr_din),
    
.App_rd_en			(App_rd_en),//data_req
.App_rd_addr		(App_rd_addr),
.Sdr_rd_en			(Sdr_rd_en),//data_valid
.Sdr_rd_dout		(Sdr_rd_dout)
);
endmodule 