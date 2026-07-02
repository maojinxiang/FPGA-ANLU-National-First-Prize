
// ===========================================================================
// Copyright (c) 2011-2024 Anlogic Inc. All Right Reserved.
//
// TEL: 86-21-61633787
// WEB: http://www.anlogic.com/
// ===========================================================================
//
//
// support 1588v2(202401)
//
//
// ===========================================================================
module mac_core_aead6cd6dadd #(
   parameter     P_HALF_DUPLEX       = 1'b1,       
   parameter     P_HOST_EN           = 1'b1,       
   parameter     P_ADD_FILT_EN       = 1'b1,       
   parameter     P_ADD_FILT_LIST     = 16,         
   parameter     P_SPEED_10_100      = 1'b0,       
   parameter     P_SPEED_1000        = 1'b0,       
   parameter     P_TRI_SPEED         = 1'b1,    
   parameter     CFG_1588V2          = 1'b0    
   )(   
   input         reset,    
   input         tx_mac_clk,
   input         rx_mac_clk,
   output        speed_1000,
   output        speed_100,
   output        speed_10,
   input         mac_has_sgmii,
   input         tx_clk_en,
   input  [7:0]  tx_data,
   input         tx_data_en,
   output        tx_rdy,
   input         tx_stop,
   output        tx_retransmit,
   output        tx_collision,
   input  [7:0]  tx_ifg_val, 
   output [28:0] tx_status_vector,
   output        tx_status_vld,
   input         rx_clk_en,
   output [7:0]  rx_data,
   output        rx_data_vld,
   output        rx_correct_frame,
   output        rx_error_frame,
   output [26:0] rx_status_vector,
   output        rx_status_vld,
   input         pause_req,
   input [15:0]  pause_val,
   input [47:0]  pause_source_addr,
   input [47:0]  unicast_addr,
   
   input [84:0]  mac_cfg_vector,

   input         gmii_tx_clken,
   output [7:0]  gmii_txd,
   output        gmii_tx_en,
   output        gmii_tx_er,
   input  [7:0]  gmii_rxd,
   input         gmii_rx_vld,
   input         gmii_rx_er,
   input         gmii_col,
   input         gmii_crs,

   input         mdio_in,
   output        mdio_out,
   output        mdio_oen,
   output        mdio_clk    
   );

TEMAC_CORE_aead6cd6dadd #(
   .P_HALF_DUPLEX       (P_HALF_DUPLEX  ),
   .P_HOST_EN           (P_HOST_EN      ),
   .P_ADD_FILT_EN       (P_ADD_FILT_EN  ),
   .P_ADD_FILT_LIST     (P_ADD_FILT_LIST),
   .P_SPEED_10_100      (P_SPEED_10_100 ),
   .P_SPEED_1000        (P_SPEED_1000   ),
   .P_TRI_SPEED         (P_TRI_SPEED    ),
   .CFG_1588V2          (CFG_1588V2     )
   )TEMAC_CORE_INST(   
   .reset                                 (reset            ),    
   .tx_mac_clk                            (tx_mac_clk       ),
   .rx_mac_clk                            (rx_mac_clk       ),
   .speed_1000                            (speed_1000       ),
   .speed_100                             (speed_100        ),
   .speed_10                              (speed_10         ),
   .mac_has_sgmii                         (mac_has_sgmii    ),

   .tx_clk_en                             (tx_clk_en        ),
   .tx_data                               (tx_data          ),
   .tx_data_en                            (tx_data_en       ),
   .tx_rdy                                (tx_rdy           ),
   .tx_stop                               (tx_stop          ),
   .tx_retransmit                         (tx_retransmit    ),
   .tx_collision                          (tx_collision     ),
   .tx_ifg_val                            (tx_ifg_val       ),
   
   .tx_status_vector                      (tx_status_vector ),
   .tx_status_vld                         (tx_status_vld    ),

   .rx_clk_en                             (rx_clk_en        ),
   .rx_data                               (rx_data          ),
   .rx_data_vld                           (rx_data_vld      ),
   .rx_correct_frame                      (rx_correct_frame ),
   .rx_error_frame                        (rx_error_frame   ),

   .rx_status_vector                      (rx_status_vector ),
   .rx_status_vld                         (rx_status_vld    ),
   .pause_req                             (pause_req        ),
   .pause_val                             (pause_val        ),
   .pause_source_addr                     (pause_source_addr),
   .unicast_addr                          (unicast_addr     ),

   .s_axi_aclk                            (1'd0             ),
   .s_axi_awaddr                          (8'd0             ),
   .s_axi_awvalid                         (1'd0             ),
   .s_axi_awready                         (                 ),
   .s_axi_wdata                           (32'd0            ),   
   .s_axi_wvalid                          (1'd0             ),
   .s_axi_wready                          (                 ),
   .s_axi_bresp                           (                 ),
   .s_axi_bvalid                          (                 ),
   .s_axi_bready                          (1'd0             ),
   .s_axi_araddr                          (8'd0             ),
   .s_axi_arvalid                         (1'd0             ),
   .s_axi_arready                         (                 ),
   .s_axi_rdata                           (                 ),
   .s_axi_rresp                           (                 ),
   .s_axi_rvalid                          (                 ),
   .s_axi_rready                          (1'd0             ),
   .mac_cfg_vector                        (mac_cfg_vector   ),

   .gmii_tx_clken                         (gmii_tx_clken    ),
   .gmii_txd                              (gmii_txd         ),
   .gmii_tx_en                            (gmii_tx_en       ),
   .gmii_tx_er                            (gmii_tx_er       ),
   .gmii_rxd                              (gmii_rxd         ),
   .gmii_rx_vld                           (gmii_rx_vld      ),
   .gmii_rx_er                            (gmii_rx_er       ),
   .gmii_col                              (gmii_col         ),
   .gmii_crs                              (gmii_crs         ),

   .ptp_timer_format_i                    (1'd0                ), // 0: TOD;  1: CorrectionField 
   .tx_1588v2_cmd_i                       (64'd0               ),         
   .tx_system_time_i                      (96'd0               ), //ÏµÍ³Ê±¼äTOD/CF
   .tx_timestamp_i                        (96'd0               ), //ÊäÈë½ø¿ÚÊ±¼ä´Á, ÓÃÓÚ×¤ÁôÊ±¼ä¸üÐÂ   
   .tx_timestamp_o                        (                    ),     
   .tx_tagid_o                            (                    ),     
   .tx_timestamp_valid_o                  (                    ),    
   .tx_1588v2_cfg_err_o                   (                    ), 
   .rx_phy_timer_i                        (96'd0               ),
   .rx_timestamp_o                        (                    ),                                                
   .rx_timestamp_valid_o                  (                    ),

   .mdio_in                               (mdio_in          ),
   .mdio_out                              (mdio_out         ),
   .mdio_oen                              (mdio_oen         ),
   .mdio_clk                              (mdio_clk         )    
   ); 
endmodule
