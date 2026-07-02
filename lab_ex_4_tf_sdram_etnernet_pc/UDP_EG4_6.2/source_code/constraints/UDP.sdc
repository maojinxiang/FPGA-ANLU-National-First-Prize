create_clock -name {clk_in} -period 20.000 -waveform {0.000 10.000} [get_ports {clk_50}]
create_clock -name {phy1_rgmii_rx_clk} -period 8.000 -waveform {0.000 4.000} [get_ports {phy1_rgmii_rx_clk}]

derive_clocks
rename_clock -name {pll_inst_125M_0} [get_clocks {u_clk_gen/u_pll_0/pll_inst.clkc[0]}]
rename_clock -name {pll_inst_125M_1} [get_clocks {u_clk_gen/u_pll_0/pll_inst.clkc[1]}]
#rename_clock -name {pll_inst_12p5M} [get_clocks {u_clk_gen/u_pll_0/pll_inst.clkc[2]}]
rename_clock -name {pll_inst_25M} [get_clocks {u_clk_gen/u_pll_0/pll_inst.clkc[3]}]

create_generated_clock -name {udp_clk_125m} -source [get_pins {u_clk_gen/u_pll_0/pll_inst.clkc[1]}] -master_clock {pll_inst_125M_1} -divide_by 1.000 -phase 0.000 -add [get_nets {udp_clk}]
#create_generated_clock -name {udp_clk_12p5m} -add -source [get_pins {u_clk_gen/u_pll_0/pll_inst.clkc[2]}] -master_clock {pll_inst_12p5M} -divide_by 1.000 [get_nets {udp_clk}]
#create_generated_clock -name {udp_clk_1p25m} -add -source [get_pins {u_clk_gen/u_pll_0/pll_inst.clkc[2]}] -master_clock {pll_inst_12p5M} -divide_by 10.000 [get_nets {udp_clk}]
set_clock_groups -exclusive -group [get_clocks {udp_clk_125m}]
#set_clock_groups -exclusive -group [get_clocks {udp_clk_12p5m}]
#set_clock_groups -exclusive -group [get_clocks {udp_clk_1p25m}]


set_clock_groups -exclusive -group [get_clocks {phy1_rgmii_rx_clk}]
