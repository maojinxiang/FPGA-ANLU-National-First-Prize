`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: anlgoic
// Author: 	xg 
// description:  top module
//////////////////////////////////////////////////////////////////////////////////

`define DEBUG

`include "../include/global_def.v"

module sdram_top(
    input                                    SYS_CLK                 ,
    input                                    rst_n                   ,
    input                                    sd_clk                  ,
    output                                   sdr_clk                 ,
    output                                   LED                     ,
    output                                   Sdr_init_done           ,
    output                                   wr_done                 ,
    input                                    sdr_data_valid          ,
    input              [  23: 0]             sdr_data                ,
    output                                   Sdr_rd_en               ,
    output             [`DATA_WIDTH-1: 0]    Sdr_rd_dout             ,
    input                                    full_flag               ,
    output                                   full_flag_sdr  ,
    input           [11:0]udp_wrusedw          
    );



wire                                lock,local_clk,Clk,Clk_sft,Rst/*synthesis syn_keep=1 */;

`ifndef SIMULATION
wire                                SDRAM_CLK                   ;
wire                                SDR_RAS                     ;
wire                                SDR_CAS                     ;
wire                                SDR_WE                      ;
wire               [`BA_WIDTH-1: 0]        SDR_BA                      ;
wire               [`ROW_WIDTH-1: 0]        SDR_ADDR                    ;
wire               [`DATA_WIDTH-1: 0]        SDR_DQ                      ;
wire               [`DM_WIDTH-1: 0]        SDR_DM                      ;
`endif

wire                                Sdr_init_ref_vld            ;//synthesis keep

wire                                App_wr_en                   ;//synthesis keep
wire               [`ADDR_WIDTH-1: 0]        App_wr_addr                 ;//synthesis keep
wire               [`DM_WIDTH-1: 0]        App_wr_dm                   ;
wire               [`DATA_WIDTH-1: 0]        App_wr_din                  ;//synthesis keep

wire                                App_rd_en                   ;//synthesis keep
wire               [`ADDR_WIDTH-1: 0]        App_rd_addr                 ;//synthesis keep


wire                                Check_ok                    ;//synthesis keep

    assign                              LED                         = Check_ok;

clk_pll u0_clk(
    .refclk                             (SYS_CLK                   ),
    .reset                              (1'b0                      ),
    .extlock                            (lock                      ),
    .clk0_out                           (local_clk                 ),
    .clk1_out                           (Clk                       ),
    .clk2_out                           (Clk_sft                   ) 
        );
        
    assign                              sdr_clk                     = Clk;
    assign                              Rst_n                       = rst_n & lock;
wire                                Sdr_busy                    ;

wire                                wr_done                     ;
app_wrrd u1_app_wrrd(
    .clk                                (Clk                       ),
    .sd_clk                             (SYS_CLK                   ),
    .rst_n                              (Rst_n                     ),
    .full_flag_net                      (full_flag                 ),
    .Sdr_init_done                      (Sdr_init_done             ),
    .Sdr_init_ref_vld                   (Sdr_init_ref_vld          ),
    .sdr_data_valid                     (sdr_data_valid            ),
    .sdr_data                           (sdr_data                  ),
    .App_wr_en                          (App_wr_en                 ),
    .App_wr_addr                        (App_wr_addr               ),
    .App_wr_dm                          (App_wr_dm                 ),
    .App_wr_din                         (App_wr_din                ),
    .wr_done                            (wr_done                   ),
    .App_rd_en                          (App_rd_en                 ),
    .App_rd_addr                        (App_rd_addr               ),
    .Sdr_rd_en                          (Sdr_rd_en                 ),
    .Sdr_rd_dout                        (Sdr_rd_dout               ),
    .Sdr_busy                           (Sdr_busy                  ),
    .full_flag                          (full_flag_sdr             ) ,
    .udp_wrusedw(udp_wrusedw)
		// .Check_ok(Check_ok)
    );

sdr_as_ram  #( .self_refresh_open(1'b1))
    u2_ram(
    .Sdr_clk                            (Clk                       ),
    .Sdr_clk_sft                        (Clk_sft                   ),
    .Rst                                (!Rst_n                    ),
			  			  
    .Sdr_init_done                      (Sdr_init_done             ),
    .Sdr_init_ref_vld                   (Sdr_init_ref_vld          ),
    .Sdr_busy                           (Sdr_busy                  ),
		
    .App_ref_req                        (1'b0                      ),
		
    .App_wr_en                          (App_wr_en                 ),
    .App_wr_addr                        (App_wr_addr               ),
    .App_wr_dm                          (App_wr_dm                 ),
    .App_wr_din                         (App_wr_din                ),

    .App_rd_en                          (App_rd_en                 ),
    .App_rd_addr                        (App_rd_addr               ),
    .Sdr_rd_en                          (Sdr_rd_en                 ),
    .Sdr_rd_dout                        (Sdr_rd_dout               ),
	
    .SDRAM_CLK                          (SDRAM_CLK                 ),
    .SDR_RAS                            (SDR_RAS                   ),
    .SDR_CAS                            (SDR_CAS                   ),
    .SDR_WE                             (SDR_WE                    ),
    .SDR_BA                             (SDR_BA                    ),
    .SDR_ADDR                           (SDR_ADDR                  ),
    .SDR_DM                             (SDR_DM                    ),
    .SDR_DQ                             (SDR_DQ                    ) 
    );


    assign                              SDR_CKE                     = 1'b1;

//`ifndef SIMULATION
    EG_PHY_SDRAM_2M_32 sdram(
    .clk                                (SDRAM_CLK                 ),
    .ras_n                              (SDR_RAS                   ),
    .cas_n                              (SDR_CAS                   ),
    .we_n                               (SDR_WE                    ),
    .addr                               (SDR_ADDR[10:0]            ),
    .ba                                 (SDR_BA                    ),
    .dq                                 (SDR_DQ                    ),
    .cs_n                               (1'b0                      ),
    .dm0                                (SDR_DM[0]                 ),
    .dm1                                (SDR_DM[1]                 ),
    .dm2                                (SDR_DM[2]                 ),
    .dm3                                (SDR_DM[3]                 ),
    .cke                                (1'b1                      ) 
        );
//`endif

endmodule
