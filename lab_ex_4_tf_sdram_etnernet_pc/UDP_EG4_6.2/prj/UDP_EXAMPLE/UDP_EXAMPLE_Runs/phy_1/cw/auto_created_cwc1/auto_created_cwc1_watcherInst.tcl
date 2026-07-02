source "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/templa.tcl"
set fd [open "D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/cw/atpl/cwc.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        auto_created_cwc1
set bus_num              7
set cwc_ctrl_len         96
set cwc_bus_ctrl_len     76
set bus_din_num          21
set ram_len              21
set input_pipe_num       0
set output_pipe_num      0
set depth                256
set capture_ctrl_exist   0
set bus_width            { 1,1,8,1,1,1,8 };
set bus_din_pos          { 0,1,2,10,11,12,13 };
set bus_ctrl_pos         { 0,4,8,36,40,44,48 };
set fp [open "cw/auto_created_cwc1/auto_created_cwc1_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
