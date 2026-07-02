#**************************************************************
# 主时钟约束
#**************************************************************
create_clock -name {clk_in} -period 20.000 -waveform {0.000 10.000} [get_ports {clk_50}]
create_clock -name {phy1_rgmii_rx_clk} -period 8.000 -waveform {0.000 4.000} [get_ports {phy1_rgmii_rx_clk}]

#**************************************************************
# PLL派生时钟
#**************************************************************
derive_clocks

# SD卡/SDRAM PLL时钟重命名 (u_sys_pll)
rename_clock -name {sd_card_clk} [get_clocks {u_sys_pll/pll_inst.clkc[0]}]
rename_clock -name {ext_mem_clk} -source [get_ports {clk}] -master_clock {clk} [get_pins {sys_pll_m0/pll_inst.clkc[1]}]
# 视频PLL时钟重命名 (u_video_pll)
rename_clock -name {video_clk} [get_clocks {u_video_pll/pll_inst.clkc[0]}]
rename_clock -name {video_clk_5x} [get_clocks {u_video_pll/pll_inst.clkc[1]}]

#**************************************************************
# 时钟组隔离 (异步时钟域)
#**************************************************************
# 以太网RX时钟组（RGMII接收时钟与内部时钟异步）
set_clock_groups -exclusive -group [get_clocks {phy1_rgmii_rx_clk}]

# 视频时钟组（视频5x时钟独立）
set_clock_groups -exclusive -group [get_clocks {video_clk_5x}]
