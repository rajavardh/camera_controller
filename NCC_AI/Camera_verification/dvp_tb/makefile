# ==============================================================================
# Default Target (Runs compile, then sim automatically)
# ==============================================================================
all: compile sim

# ==============================================================================
# Environment Variables & Include Directories
# ==============================================================================
APB_VIP_DIR = ./apb_avip
AXI_VIP_DIR = ./axi_avip
COMMON_DIR  = ../camera_controller/common
RTL_DIR     = ../camera_controller
VLOG        = vlog
VSIM        = vsim

# Clean, unbroken include path (no trailing spaces!)
INC_DIR = +incdir+$(APB_VIP_DIR)/globals+$(APB_VIP_DIR)/hvl_top/env+$(APB_VIP_DIR)/hvl_top/env/virtual_sequencer+$(APB_VIP_DIR)/hvl_top/test/sequences/master_sequences+$(AXI_VIP_DIR)/globals+$(AXI_VIP_DIR)/hvl_top/master+../camera_controller+.+./dvp_agent+./interfaces

# ==============================================================================
# Compilation Targets
# ==============================================================================
compile:
	# ---------------------------------------------------------
	# 1. Compile APB VIP
	# ---------------------------------------------------------
	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/globals/apb_global_pkg.sv
	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/hvl_top/master/apb_master_pkg.sv
	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/hvl_top/slave/apb_slave_pkg.sv
	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/hvl_top/env/apb_env_pkg.sv

	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/hdl_top/master_agent_bfm/apb_master_agent_bfm.sv
	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/hdl_top/master_agent_bfm/apb_master_driver_bfm.sv
	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/hdl_top/master_agent_bfm/apb_master_monitor_bfm.sv

	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/hdl_top/slave_agent_bfm/apb_slave_agent_bfm.sv
	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/hdl_top/slave_agent_bfm/apb_slave_driver_bfm.sv
	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/hdl_top/slave_agent_bfm/apb_slave_monitor_bfm.sv

	$(VLOG) -work work $(INC_DIR) $(APB_VIP_DIR)/hdl_top/apb_if/apb_if.sv

	# ---------------------------------------------------------
	# 2. Compile AXI VIP
	# ---------------------------------------------------------
	$(VLOG) -work work $(INC_DIR) $(AXI_VIP_DIR)/globals/axi4_globals_pkg.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_VIP_DIR)/hvl_top/master/axi4_master_pkg.sv
	
	# Full AXI BFM Set
	$(VLOG) -work work $(INC_DIR) $(AXI_VIP_DIR)/hdl_top/master_agent_bfm/axi4_master_agent_bfm.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_VIP_DIR)/hdl_top/master_agent_bfm/axi4_master_driver_bfm.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_VIP_DIR)/hdl_top/master_agent_bfm/axi4_master_monitor_bfm.sv
	
	$(VLOG) -work work $(INC_DIR) $(AXI_VIP_DIR)/hdl_top/axi4_interface/axi4_if.sv
  
	$(VLOG) -work work $(INC_DIR) $(AXI_VIP_DIR)/hdl_top/master_assertions.sv
	# ---------------------------------------------------------
	# 3. Compile Custom Packages & Interfaces
	# ---------------------------------------------------------
	$(VLOG) -work work $(INC_DIR) ./dvp_pkg.sv
	$(VLOG) -work work $(INC_DIR) ./camera_ss_pkg.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/dvp_interface.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/cam_axi_interface.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/cam_dma_interface.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/cam_intr_interface.sv

	# ---------------------------------------------------------
	# 4. Compile Common and Controller RTL
	# ---------------------------------------------------------
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/mux_sync.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sync_ff.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/intr_req_ack.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/axi5_sram_ctrl_stub.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sram_wrapper.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sram_8kb_stub.sv

	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/cam_reg_apb_if_stub.v
	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/camera_data_pipe.sv
	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/camera_controller.sv

	# ---------------------------------------------------------
	# 5. Compile Top
	# ---------------------------------------------------------
	$(VLOG) -work work $(INC_DIR) ./cam_top.sv

sim:
	$(VSIM) -c -voptargs="+acc" -do "log -r /*; run -all; quit -f" -L work +UVM_TESTNAME=camera_base_test work.top 

clean:
	rm -rf work modelsim.ini transcript vsim.wlf vsim_stacktrace.vstf
