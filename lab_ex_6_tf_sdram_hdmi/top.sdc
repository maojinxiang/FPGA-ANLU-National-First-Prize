
#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************
create_clock -name clk -period 20 -waveform {0 10} [get_ports {clk}]
#create_generated_clock -name sd_card_clk -source [get_ports {clk}] -master_clock {clk} -phase 0 -multiply_by 2 [get_pins {sys_pll_m0/pll_inst.clkc[0]}]
#create_generated_clock -name ext_mem_clk -source [get_ports {clk}] -master_clock {clk} -phase 270 -multiply_by 2 [get_pins {sys_pll_m0/pll_inst.clkc[1]}]
#create_generated_clock -name flash_sys_clk -source [get_ports {clk}] -master_clock {clk} -phase 0 -multiply_by 2 [get_pins {sys_pll_m0/pll_inst.clkc[2]}]
#create_generated_clock -name video_clk -source [get_ports {clk}] -master_clock {clk} -phase 0 -multiply_by 2 [get_pins {video_pll_m0/pll_inst.clkc[0]}]
derive_pll_clocks
rename_clock -name {sd_card_clk} -source [get_ports {clk}] -master_clock {clk} [get_pins {sys_pll_m0/pll_inst.clkc[0]}]
rename_clock -name {ext_mem_clk} -source [get_ports {clk}] -master_clock {clk} [get_pins {sys_pll_m0/pll_inst.clkc[1]}]
rename_clock -name {video_clk} -source [get_ports {clk}] -master_clock {clk} [get_pins {video_pll_m0/pll_inst.clkc[0]}]


#**************************************************************
# Set False Path
#**************************************************************

#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************


#**************************************************************
# Set Input Transition
#**************************************************************