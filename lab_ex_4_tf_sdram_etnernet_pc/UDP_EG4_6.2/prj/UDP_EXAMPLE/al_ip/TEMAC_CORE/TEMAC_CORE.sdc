#TEMAC Constraints
# ->axi_clk crosss clock domain
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/SPEED_IS_100_INT}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/SPEED_IS_10_100_INT}] -nowarn 

# axi_clk crosss clock domain
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/rx_pause_ad[*]}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/rx_jumbo_en}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/rx_crc_mode}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/rx_rst}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/rx_en}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/rx_vlan}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/rx_half_duplex}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/rx_lt_disable}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/rx_ps_lt_disable}] -nowarn 

set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/tx_jumbo_en}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/tx_crc_mode}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/tx_rst}] -nowarn 
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/tx_en}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/tx_vlan}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/tx_half_duplex}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/tx_ifg_del_en}] -nowarn

set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/tx_latency_adjust_int[*]}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/tx_asymmetric_adjust_int[*]}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/command_field_inband_en_int}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/fc_en[*]}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/speed_cfg[*]}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/u_management/u_axi_config/promiscuous_mode}] -nowarn

# usrclk (addr_filter) crosss clock domain
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/rxstatsaddressmatch}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/pauseaddressmatch}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/specialpauseaddressmatch}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/broadcastaddressmatch}] -nowarn

set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data0[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match0}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data1[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match1}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data2[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match2}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data3[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match3}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data4[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match4}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data5[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match5}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data6[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match6}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data7[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match7}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data8[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match8}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data9[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match9}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data10[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match10}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data11[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match11}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data12[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match12}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data13[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match13}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data14[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match14}] -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/add_table_data15[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/match15}] -nowarn

set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/unicast_addr[*]}] -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/addr_filter_top/al102_hxcEIhDE$dynamic_config/unicast_data_shift[*]}] -nowarn

# usrclk (flow_ctrl) crosss clock domain
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/FLOW/RX_PAUSE/PAUSE_VALUE_TO_TX[*]}]  -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/FLOW/RX_PAUSE/PAUSE_REQ_TO_TX}]  -nowarn
set_false_path -from [get_regs -nowarn {*/TEMAC_CORE_INST/*/FLOW/RX_PAUSE/GOOD_FRAME_TO_TX}]  -nowarn

# reset sync
set_false_path -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/*/R1}] -nowarn
set_false_path -to [get_regs -nowarn {*/TEMAC_CORE_INST/*/*/R2}] -nowarn

