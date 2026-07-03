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

# 3. Compile Custom UVM DVP and Subsystem Packages
vlog -work work +incdir+. +incdir+./dvp_agent ./dvp_pkg.sv
vlog -work work +incdir+. ./camera_ss_pkg.sv

# 4. Compile Hardware Interfaces
vlog -work work +incdir+./interfaces ./interfaces/dvp_interface.sv
vlog -work work +incdir+./interfaces ./interfaces/cam_axi_interface.sv
vlog -work work +incdir+./interfaces ./interfaces/cam_dma_interface.sv
vlog -work work +incdir+./interfaces ./interfaces/cam_intr_interface.sv

# 5. Compile Common RTL Submodules
# (Paths set relative to running inside the dvp_tb directory)
set COMMON_PATH "../common"
vlog -work work +incdir+$COMMON_PATH $COMMON_PATH/mux_sync.sv
vlog -work work +incdir+$COMMON_PATH $COMMON_PATH/sync_ff.sv
vlog -work work +incdir+$COMMON_PATH $COMMON_PATH/intr_req_ack.sv
vlog -work work +incdir+$COMMON_PATH $COMMON_PATH/axi5_sram_ctrl_stub.sv
vlog -work work +incdir+$COMMON_PATH $COMMON_PATH/sram_wrapper.sv
vlog -work work +incdir+$COMMON_PATH $COMMON_PATH/sram_8KB_stub.v

# 6. Compile Controller RTL Modules
set RTL_PATH "../camera_controller"
vlog -work work +incdir+$RTL_PATH $RTL_PATH/cam_reg_apb_if_stub.v
vlog -work work +incdir+$RTL_PATH $RTL_PATH/camera_data_pipe.sv
vlog -work work +incdir+$RTL_PATH $RTL_PATH/camera_controller.sv 

# 7. Compile Top-Level Testbench Module
vlog -work work +incdir+. ./cam_top.sv 

# 8. Load the simulation with UVM
vsim -voptargs=+acc -t 1ps \
     -L work \
     +UVM_TESTNAME=camera_base_test \
     work.top

# 9. Add Waveforms
add wave -position insertpoint sim:/top/apb_vip_if/*
add wave -position insertpoint sim:/top/dvp_if/*
add wave -position insertpoint sim:/top/dut/*

# 10. Run simulation
run 10us
