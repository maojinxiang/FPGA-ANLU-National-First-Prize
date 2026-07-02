## Generated SDC file "sd_sdram_vga.out.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.1.0 Build 625 09/12/2018 SJ Standard Edition"

## DATE    "Wed Dec 06 09:51:02 2023"

##
## DEVICE  "10CL006YU256C8G"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name {clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {sys_pll_m0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 2 -master_clock {clk} [get_pins {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {sys_pll_m0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 2 -master_clock {clk} [get_pins {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}] 
create_generated_clock -name {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]} -source [get_pins {sys_pll_m0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 2 -master_clock {clk} [get_pins {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}] 
create_generated_clock -name {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {video_pll_m0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 74 -divide_by 147 -master_clock {clk} [get_pins {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {altera_reserved_tck}] -rise_to [get_clocks {altera_reserved_tck}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {altera_reserved_tck}] -fall_to [get_clocks {altera_reserved_tck}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {altera_reserved_tck}] -rise_to [get_clocks {altera_reserved_tck}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {altera_reserved_tck}] -fall_to [get_clocks {altera_reserved_tck}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {sys_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] 
set_clock_groups -asynchronous -group [get_clocks {video_pll_m0|altpll_component|auto_generated|pll1|clk[0]}] 


#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_kd9:dffpipe8|dffe9a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_jd9:dffpipe5|dffe6a*}]


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

