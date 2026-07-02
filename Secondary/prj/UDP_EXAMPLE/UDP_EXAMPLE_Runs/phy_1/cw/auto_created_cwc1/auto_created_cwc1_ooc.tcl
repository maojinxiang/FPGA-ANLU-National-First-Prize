import_device eagle_s20.db -package EG4S20BG256
set_param flow ooc_flow on
read_verilog -file "auto_created_cwc1_watcherInst.sv"
optimize_rtl
map_macro
map
pack
report_area -file auto_created_cwc1_gate.area
export_db -mode ooc "auto_created_cwc1_ooc.db"
