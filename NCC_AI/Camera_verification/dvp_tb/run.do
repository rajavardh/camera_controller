# 1. Create the work library
vlib work
vmap work work

# 2. Compile the APB VIP Packages & Interfaces
vlog -work work +incdir+./apb_avip/globals ./apb_avip/globals/apb_global_pkg.sv

# HVL (Software Classes)
vlog -work work +incdir+./apb_avip/hvl_top/master ./apb_avip/hvl_top/master/apb_master_pkg.sv

# HDL (Hardware Interfaces)
vlog -work work +incdir+./apb_avip/hdl_top/apb_if ./apb_avip/hdl_top/apb_if/apb_if.sv

# HDL (Hardware BFMs)
vlog -work work +incdir+./apb_avip/hdl_top/master_agent_bfm ./apb_avip/hdl_top/master_agent_bfm/apb_master_driver_bfm.sv
vlog -work work +incdir+./apb_avip/hdl_top/master_agent_bfm ./apb_avip/hdl_top/master_agent_bfm/apb_master_monitor_bfm.sv
vlog -work work +incdir+./apb_avip/hdl_top/master_agent_bfm ./apb_avip/hdl_top/master_agent_bfm/apb_master_agent_bfm.sv

# 3. Compile your Custom DVP and Subsystem Packages
# FIXED: Added +incdir+./dvp_agent so the compiler can find the included files!
# (If dvp_env.sv is in a different folder, add another +incdir+ for it here)
vlog -work work +incdir+. +incdir+./dvp_agent ./dvp_pkg.sv
vlog -work work +incdir+. ./camera_ss_pkg.sv

# 4. Compile the RTL (DUT)
vlog -work work +incdir+. ./camera_controller.sv 

# 5. Compile the Top-Level Testbench
vlog -work work +incdir+. ./top.sv

# 6. Load the simulation with UVM
vsim -voptargs=+acc -t 1ps \
     -L work \
     +UVM_TESTNAME=camera_base_test \
     work.top

# 7. Add waveforms and run
add wave -position insertpoint sim:/top/apb_vip_if/*
add wave -position insertpoint sim:/top/dvp_if/*
add wave -position insertpoint sim:/top/dut/*

# Run for 10 microseconds
run 10us
