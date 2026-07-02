onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /udp_transmit_test_tb/u_udp_test/key1
add wave -noupdate /udp_transmit_test_tb/u_udp_test/key2
add wave -noupdate /udp_transmit_test_tb/u_udp_test/clk_25
add wave -noupdate /udp_transmit_test_tb/u_udp_test/TRI_speed
add wave -noupdate /udp_transmit_test_tb/u_udp_test/phy1_rgmii_rx_clk
add wave -noupdate /udp_transmit_test_tb/u_udp_test/phy1_rgmii_rx_ctl
add wave -noupdate /udp_transmit_test_tb/u_udp_test/phy1_rgmii_rx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/phy1_rgmii_tx_clk
add wave -noupdate /udp_transmit_test_tb/u_udp_test/phy1_rgmii_tx_ctl
add wave -noupdate /udp_transmit_test_tb/u_udp_test/phy1_rgmii_tx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_out
add wave -noupdate /udp_transmit_test_tb/u_udp_test/phy_reset
add wave -noupdate /udp_transmit_test_tb/u_udp_test/app_rx_data_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/app_rx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/app_rx_data_length
add wave -noupdate /udp_transmit_test_tb/u_udp_test/app_rx_port_num
add wave -noupdate /udp_transmit_test_tb/u_udp_test/udp_tx_ready
add wave -noupdate /udp_transmit_test_tb/u_udp_test/app_tx_ack
add wave -noupdate /udp_transmit_test_tb/u_udp_test/app_tx_data_request
add wave -noupdate /udp_transmit_test_tb/u_udp_test/app_tx_data_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/app_tx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/udp_data_length
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tpg_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tpg_data_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tpg_data_udp_length
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tx_stop
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tx_ifg_val
add wave -noupdate /udp_transmit_test_tb/u_udp_test/pause_req
add wave -noupdate /udp_transmit_test_tb/u_udp_test/pause_val
add wave -noupdate /udp_transmit_test_tb/u_udp_test/pause_source_addr
add wave -noupdate /udp_transmit_test_tb/u_udp_test/unicast_address
add wave -noupdate /udp_transmit_test_tb/u_udp_test/mac_cfg_vector
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_tx_ready
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_tx_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_tx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_tx_sof
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_tx_eof
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_rx_ready
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_rx_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_rx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_rx_sof
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_rx_eof
add wave -noupdate /udp_transmit_test_tb/u_udp_test/rx_correct_frame
add wave -noupdate /udp_transmit_test_tb/u_udp_test/rx_error_frame
add wave -noupdate /udp_transmit_test_tb/u_udp_test/rx_clk_int
add wave -noupdate /udp_transmit_test_tb/u_udp_test/rx_clk_en_int
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tx_clk_int
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tx_clk_en_int
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_clk
add wave -noupdate /udp_transmit_test_tb/u_udp_test/udp_clk
add wave -noupdate /udp_transmit_test_tb/u_udp_test/temac_clk90
add wave -noupdate /udp_transmit_test_tb/u_udp_test/clk_125_out
add wave -noupdate /udp_transmit_test_tb/u_udp_test/clk_12_5_out
add wave -noupdate /udp_transmit_test_tb/u_udp_test/clk_1_25_out
add wave -noupdate /udp_transmit_test_tb/u_udp_test/rx_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/rx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tx_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tx_rdy
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tx_collision
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tx_retransmit
add wave -noupdate /udp_transmit_test_tb/u_udp_test/reset
add wave -noupdate /udp_transmit_test_tb/u_udp_test/reset_reg
add wave -noupdate /udp_transmit_test_tb/u_udp_test/clk_25_out
add wave -noupdate /udp_transmit_test_tb/u_udp_test/phy_reset_cnt
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_app_rx_data_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_app_rx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_app_tx_data_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_app_tx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_temac_tx_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_temac_tx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_temac_rx_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_temac_rx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_rx_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_rx_data
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_tx_valid
add wave -noupdate /udp_transmit_test_tb/u_udp_test/debug_tx_data
add wave -noupdate -radix unsigned /udp_transmit_test_tb/u_udp_test/debug_frame_temac_cnt_rx
add wave -noupdate -radix unsigned /udp_transmit_test_tb/u_udp_test/debug_frame_app_cnt_rx
add wave -noupdate -radix unsigned /udp_transmit_test_tb/u_udp_test/debug_frame_fifo_cnt_rx
add wave -noupdate -radix unsigned /udp_transmit_test_tb/u_udp_test/debug_frame_temac_cnt_tx
add wave -noupdate -radix unsigned /udp_transmit_test_tb/u_udp_test/debug_frame_app_cnt_tx
add wave -noupdate -radix unsigned /udp_transmit_test_tb/u_udp_test/debug_frame_fifo_cnt_tx
add wave -noupdate /udp_transmit_test_tb/u_udp_test/udp_debug_out
add wave -noupdate /udp_transmit_test_tb/u_udp_test/tpg_data_done
add wave -noupdate /udp_transmit_test_tb/u_udp_test/soft_reset_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {99311364710 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 211
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 fs} {211299900 ps}
