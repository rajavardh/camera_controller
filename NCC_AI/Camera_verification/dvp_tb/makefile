# --- Directories ---
TB_DIR    = .
RTL_DIR   = ../camera_controller
COMMON_DIR= ../camera_controller/common
VIP_DIR   = ./apb_avip

# --- Compiler Flags ---
VLOG      = vlog
VSIM      = vsim
VOPT_ARGS = +acc
INC_DIR   = +incdir+$(VIP_DIR)/globals+$(VIP_DIR)/hvl_top/env+$(VIP_DIR)/hvl_top/env/virtual_sequencer+$(RTL_DIR)+$(TB_DIR)+$(TB_DIR)/dvp_agent+$(TB_DIR)/interfaces

# --- Compilation ---
all: clean lib compile sim

lib:
	vlib work
	vmap work work

compile:
	# Compile APB VIP
	$(VLOG) -work work $(INC_DIR) $(VIP_DIR)/globals/apb_global_pkg.sv
	$(VLOG) -work work $(INC_DIR) $(VIP_DIR)/hvl_top/master/apb_master_pkg.sv
	$(VLOG) -work work $(INC_DIR) $(VIP_DIR)/hvl_top/slave/apb_slave_pkg.sv
	$(VLOG) -work work $(INC_DIR) $(VIP_DIR)/hvl_top/env/apb_env_pkg.sv
	$(VLOG) -work work $(INC_DIR) $(VIP_DIR)/hdl_top/master_agent_bfm/apb_master_agent_bfm.sv
	$(VLOG) -work work $(INC_DIR) $(VIP_DIR)/hdl_top/master_agent_bfm/apb_master_driver_bfm.sv
	$(VLOG) -work work $(INC_DIR) $(VIP_DIR)/hdl_top/master_agent_bfm/apb_master_monitor_bfm.sv
	$(VLOG) -work work $(INC_DIR) $(VIP_DIR)/hdl_top/apb_if/apb_if.sv
	
	# Compile DVP and Subsystem Packages
	$(VLOG) -work work $(INC_DIR) ./dvp_pkg.sv
	$(VLOG) -work work $(INC_DIR) ./camera_ss_pkg.sv
	
	# Compile Interfaces
	$(VLOG) -work work $(INC_DIR) ./interfaces/dvp_interface.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/cam_axi_interface.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/cam_dma_interface.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/cam_intr_interface.sv
	
	# Compile Common and Controller RTL
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/mux_sync.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sync_ff.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/intr_req_ack.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/axi5_sram_ctrl_stub.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sram_wrapper.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sram_8kb_stub.sv
	
	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/cam_reg_apb_if_stub.v
	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/camera_data_pipe.sv
	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/camera_controller.sv
	
	# Compile Top
	$(VLOG) -work work $(INC_DIR) ./cam_top.sv
	#$(VLOG) -work work -timescale 1ns/1ps $(INC_DIR) $(VIP_DIR)/hdl_top/hdl_top.sv

sim:
	$(VSIM) -c -do "run 10us; quit -f" $(VOPT_ARGS) -L work +UVM_TESTNAME=camera_base_test work.top 

clean:
	rm -rf work modelsim.ini transcript
