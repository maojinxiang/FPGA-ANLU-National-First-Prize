# This is default flow script for normal condition: neither syn ip flow nor multi-seed mode.
# Noted that only script in editable zone can be changed. 

if { ![info exists alRun] } { source ./settings.cfg }
proc step_begin { step } {
  set stopFile ".stop.f"
  if {[file isfile .stop.f]} {
    puts ""
    puts " #Halting run"
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.f"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exists ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exists ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Ownner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}
proc step_end { step } {
  set endFile ".$step.end.f"
  set ch [open $endFile w]
  close $ch
}
proc step_error { step } {
  set errorFile ".$step.error.f"
  set ch [open $errorFile w]
  close $ch
}
set stepList {read_design opt_rtl opt_gate opt_place opt_route bitgen}
set l [lsearch $stepList $start_step]
set r [lsearch $stepList $end_step]
proc prepare { step } {
  upvar device_name device_name
  upvar package_name package_name
  upvar speed speed
  upvar prj_name prj_name
  upvar parent parent
  upvar synWildParams synWildParams
  upvar phyWildParams phyWildParams
  upvar alRun alRun
  upvar singleRun singleRun
  upvar sp sp
  upvar ADCList ADCList
  upvar SDCList SDCList
  set command "import_device $device_name -package $package_name"; if { [info exists speed] } { append command " -speed ${speed}" }; eval $command
  if { ![info exists singleRun] } {
    if { [info exists alRun] } { 
        open_project ${prj_name}.al -single_run
        load_run_param -run ${alRun}
    } else {
    set command "open_project {${prj_name}.prj}"; if { $step != 0 } { append command " -noanalyze" }; eval $command
    }
  }
  set preSteps {non elaborate rtl gate place pr}
  set preStep [ lindex ${preSteps} $step ]
  if { $step == 3 } { import_db $parent/${prj_name}_${preStep}.db }\
  elseif { $step != 0 } { import_db ${prj_name}_${preStep}.db }
  set wildParams ""
  if { [info exists synWildParams] } { set wildParams ${synWildParams} } elseif { [info exists phyWildParams] } { set wildParams ${phyWildParams} }
  for { set i 0 } { $i < [llength $wildParams] } { incr i 3 } {
    set_param [lindex $wildParams $i] [lindex $wildParams [expr $i + 1]] [lindex $wildParams [expr $i + 2]]
  }
  if { [info exists singleRun] } report_param
  if { [info exists sp] } {
    if { [info exists ADCList] } { foreach adc $ADCList { read_adc $adc } }
    if { [info exists SDCList] } {
      clear_sdc -user
      foreach sdc $SDCList { read_sdc $sdc }
    }
  }
}
proc read_design_fun {} {
  upvar prj_name prj_name
  upvar top_model_name top_model_name
  upvar singleRun singleRun
  upvar ADCList ADCList
  upvar IpADCList IpADCList
  upvar SDCList SDCList
  upvar IpSDCList IpSDCList
  if { ![info exists singleRun] } { commit_param -step design }

### Editable zone for read_design ###
  elaborate -top $top_model_name
#####################################
  if { [info exists ADCList] } { foreach adc $ADCList { read_adc $adc } }
  if { [info exists IpADCList] } {
    set i 0
    while {$i < [llength $IpADCList]} {
      read_ip_adc -ip [lindex $IpADCList $i] -file [lindex $IpADCList [expr $i + 1] ]
      incr i 2
    }
  }
  if { [info exists SDCList] } { foreach sdc $SDCList { read_sdc $sdc } }
  if { [info exists IpSDCList] } {
    set i 0
    while {$i < [llength $IpSDCList]} {
      read_sdc -ip [lindex $IpSDCList $i] [lindex $IpSDCList [expr $i + 1] ]
      incr i 2
    }
  }
  export_db ${prj_name}_elaborate.db
}
proc opt_rtl_fun {} {
  upvar prj_name prj_name
  upvar singleRun singleRun
  if { ![info exists singleRun] } { commit_param -step rtl }


### Editable zone for opt_rtl ###
  upvar chipDebugger chipDebugger
  if { ![info exists chipDebugger] } {
     insert_debugger
  } else { insert_debugger $chipDebugger }
  optimize_rtl
  report_area -file ${prj_name}_rtl.area
#################################

  export_db ${prj_name}_rtl.db
}
proc opt_gate_fun {} {
  upvar prj_name prj_name
  upvar area_option area_option
  upvar singleRun singleRun
  if { ![info exists singleRun] } { commit_param -step gate }

### Editable zone for opt_gate ###
  optimize_gate ${area_option} ${prj_name}_gate.area
  legalize_phy_inst
  update_timing
  report_timing_status -file ${prj_name}_gate.ts
  report_timing_summary -file ${prj_name}_gate.timing
  flow_status -file flow.status
##################################

  export_db ${prj_name}_gate.db
}
proc opt_place_fun {} {
  upvar prj_name prj_name
  upvar cwcList cwcList
  upvar singleRun singleRun
  upvar chipDebugger chipDebugger
  upvar bkaADCList bkaADCList
  upvar arr_filter arr_filter
  upvar arr_pwns arr_pwns
  upvar arr_cong arr_cong
  if { ![info exists singleRun] } { commit_param -step place }
  if { ![info exists chipDebugger] } {
     insert_debugger
  } else { insert_debugger $chipDebugger }
  if { [info exists bkaADCList] } { 
     clear_inst_adc
     foreach adc $bkaADCList { read_adc $adc } 
  }

### Editable zone for opt_place ###
  place
  update_timing -mode manhattan
  report_timing_summary -file ${prj_name}_place.timing
  report_area -io_info -file ${prj_name}_phy.area
  flow_status -file place_flow.status
  report_clock_utilization -file place_clock_utilization.txt
  if { [string equal $arr_filter true] } { flow_continue_check -step place -wns $arr_pwns -congestion $arr_cong }
###################################

  export_db ${prj_name}_place.db
}
proc opt_route_fun {} {
  upvar prj_name prj_name
  upvar singleRun singleRun
  upvar arr_filter arr_filter
  upvar arr_rwns arr_rwns
  upvar drHoldFix drHoldFix
  if { ![info exists singleRun] } { commit_param -step route }

### Editable zone for opt_route ###
  if { [string equal $arr_filter on] && [string equal $drHoldFix on] } { 
    set_param route fix_hold off
    set_param flow qor_monitor off
  }
  route
  if { [string equal $arr_filter on] && [string equal $drHoldFix on] } {
    flow_continue_check -step route -wns $arr_rwns -name ${prj_name}
    fix_hold
    set_param route fix_hold on
    set_param flow qor_monitor on
    report_qor -step route -file route.qor
  }
  report_area -io_info -file ${prj_name}_phy.area
  update_timing -mode final
  report_timing_status -file ${prj_name}_phy.ts
  report_timing_summary -file ${prj_name}_pr.timing
  report_timing_exception -file ${prj_name}_exception.timing
  flow_status -file route_flow.status
  report_clock_utilization -file route_clock_utilization.txt
###################################

  export_db ${prj_name}_pr.db
}
proc bitgen_fun {} {
  upvar prj_name prj_name
  upvar cpcList cpcList
  upvar singleRun singleRun
  if { ![info exists singleRun] } { commit_param -step bitgen }
  if { [info exists cpcList] } {
    import_chipprobe_config $cpcList
    compile_probe
  }

### Editable zone for bitgen ###
  bitgen -bit $prj_name.bit
################################
  upvar chipDebugger chipDebugger
  if { ![info exists chipDebugger] } {
    setup_debugger
  } else { setup_debugger $chipDebugger }
  export_bitgen_param -file .bitgen_param.f 
}
foreach s [lrange $stepList $l $r] {
  step_begin $s
  set ACTIVESTEP $s
  set rc [catch {
    if { [string equal $s $start_step] } { prepare $l }
    ${s}_fun
  } RESULT]
  if { $rc } {
    step_error $s
    return -code error $RESULT
  } else {
    step_end $s
    unset ACTIVESTEP
  }
}
export_flow_status -s $start_step -e $end_step
