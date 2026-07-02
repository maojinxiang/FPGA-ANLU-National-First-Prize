#
# Create work library
#
vlib work
#
# Compile sources
#

vlog  ../tb/udp_demo_tb.v
vlog  ../tb/udp_transmit_test_sim.v
vlog  ../src/*.v

#vlog -incr C:/Anlogic/TD5.0.27252/sim_release/al/*.v
#vlog -incr C:/Anlogic/TD5.0.27252/sim_release/eg/*.v
#vlog -incr C:/Anlogic/TD5.0.27252/sim_release/ph2/*.v

vlog -incr C:/Anlogic/TD5.0.43066/sim_release/al/*.v
vlog -incr C:/Anlogic/TD5.0.43066/sim_release/ph2/*.v

#
# Call vsim to invoke simulator
#
vsim -gui -voptargs=+acc work.udp_transmit_test_tb
#
# Add waves
#
do ./wave.do
#
# Run simulation
#
run 1200 us
#
# End