# 1. Create the work library
vlib work
vmap work work

# 2. Compile the APB VIP Packages & Interfaces
vlog -work work +incdir+./apb_avip/globals ./apb_avip/globals/apb_global_pkg.sv

# HVL (Software Classes) - Master, Slave, then Environment
vlog -work work +incdir+./apb_avip/hvl_top/master ./apb_avip/hvl_top/master/apb_master_pkg.sv
vlog -work work +incdir+./apb_avip/hvl_top/slave  ./apb_avip/hvl_top/slave/apb_slave_pkg.sv
vlog -work work +incdir+./apb_avip/hvl_top/env +incdir+./apb_avip/hvl_top/env/virtual_sequencer ./apb_avip/hvl_top/env/apb_env_pkg.sv

# HDL (Hardware Interfaces) - APB
vlog -work work +incdir+./apb_avip/hdl_top/apb_if ./apb_avip/hdl_top/apb_if/apb_if.sv

# HDL (Hardware BFMs) - Master
vlog -work work +incdir+./apb_avip/hdl_top/master_agent_bfm ./apb_avip/hdl_top/master_agent_bfm/apb_master_driver_bfm.sv
vlog -work work +incdir+./apb_avip/hdl_top/master_agent_bfm ./apb_avip/hdl_top/master_agent_bfm/apb_master_monitor_bfm.sv
vlog -work work +incdir+./apb_avip/hdl_top/master_agent_bfm ./apb_avip/hdl_top/master_agent_bfm/apb_master_agent_bfm.sv

# HDL (Hardware BFMs) - Slave
vlog -work work +incdir+./apb_avip/hdl_top/slave_agent_bfm ./apb_avip/hdl_top/slave_agent_bfm/apb_slave_driver_bfm.sv
vlog -work work +incdir+./apb_avip/hdl_top/slave_agent_bfm ./apb_avip/hdl_top/slave_agent_bfm/apb_slave_monitor_bfm.sv
vlog -work work +incdir+./apb_avip/hdl_top/slave_agent_bfm ./apb_avip/hdl_top/slave_agent_bfm/apb_slave_agent_bfm.sv

# 3. Compile your Custom DVP and Subsystem Packages
vlog -work work +incdir+. +incdir+./dvp_agent ./dvp_pkg.sv
vlog -work work +incdir+. ./camera_ss_pkg.sv

# 4. Compile the Interfaces and RTL Submodules
# Interfaces
vlog -work work +incdir+. ./camera_dvp_if.sv
vlog -work work +incdir+. ./axi_s_cam_cntrl_if.sv
vlog -work work +incdir+. ./dma_trig_cam_cntrl_if.sv
vlog -work work +incdir+. ./intr_cam_cntrl_if.sv

# RTL Submodules
vlog -work work +incdir+. ./mux_sync.sv
vlog -work work +incdir+. ./sync_ff.sv
vlog -work work +incdir+. ./intr_req_ack.sv
vlog -work work +incdir+. ./camera_data_pipe.sv
vlog -work work +incdir+. ./cam_reg_apb_if_stub.sv
vlog -work work +incdir+. ./axi5_sram_ctrl_stub.sv

# Top-Level RTL
vlog -work work +incdir+. ./camera_controller.sv 

# 5. Compile the Top-Level Testbench File
vlog -work work +incdir+. ./cam_top.sv 

# 6. Load the simulation with UVM (Targeting the 'top' module)
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
