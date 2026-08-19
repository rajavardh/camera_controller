# ==============================================================================
all: compile compile_log_err sim simulate_log_err

# ==============================================================================
# Environment Variables & Include Directories
# ==============================================================================
APB_VIP_DIR  = ./apb_avip
AXI_VIP_DIR  = ./axi_avip

# Updated to point directly to the newly extracted third-party RTL directories
COMMON_DIR   = ../rjn_cam_rtl/common
RTL_DIR      = ../rjn_cam_rtl/cam_cntrl

VLOG         = vlog
VSIM         = vsim

# Clean, unbroken include path (AXI_CTRL_DIR removed, added new RTL directories)
INC_DIR = +incdir+$(APB_VIP_DIR)/globals+$(APB_VIP_DIR)/hvl_top/env+$(APB_VIP_DIR)/hvl_top/env/virtual_sequencer+$(APB_VIP_DIR)/hvl_top/test/sequences/master_sequences+$(AXI_VIP_DIR)/globals+$(AXI_VIP_DIR)/hvl_top/master+$(RTL_DIR)+$(COMMON_DIR)+.+./dvp_agent+./dma_agent+./interfaces

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
	$(VLOG) -work work $(INC_DIR) ./dma_pkg.sv
	$(VLOG) -work work $(INC_DIR) ./camera_ss_pkg.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/dvp_interface.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/cam_axi_interface.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/cam_dma_interface.sv
	$(VLOG) -work work $(INC_DIR) ./interfaces/cam_intr_interface.sv

	# ---------------------------------------------------------
	# 4. Compile New Third-Party RTL (rjn_cam_rtl)
	# ---------------------------------------------------------
	# Common folder files
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/mux_sync.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sync_ff.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/intr_req_ack.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/pulse_extender.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sram_8KB.v
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sram_wrapper.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/axi5_sram_ctrl.sv

	# Camera Controller folder files
	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/cam_reg_apb_if.v
	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/camera_data_pipe.sv
	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/camera_controller.sv
	
	# ---------------------------------------------------------
	# 5. Compile Top
	# ---------------------------------------------------------
	$(VLOG) -l top.log -work work $(INC_DIR) ./cam_top.sv

sim:
	vsim -c -wlf waveform.wlf -voptargs="+acc" "+notimingchecks" -l simulation.log -do "log -r /*; run -all; quit -f" -L work "+UVM_TESTNAME=camera_base_test" +FMT=0 +RES=3 work.top

clean:
	rm -rf work modelsim.ini transcript waveform.wlf vsimx.wlf vsim_stacktrace.vstf top.log simulation.log

compile_log_err:
	@echo ""
	@echo "-----------------------------------------------------------------"
	@echo "------------------- Compilation Report --------------------------"
	@echo ""
	@echo " Detailed Errors:"
	@grep -i "\*\* at" top.log || echo "No Errors found"
	@echo ""
	@echo " Summary:"
	@grep -i "^Errors:" top.log || echo "Summary not found"
	@echo ""
	@echo "Log file path: top.log"
	@echo ""
	@echo "-----------------------------------------------------------------"
	@echo "-----------------------------------------------------------------"
	@echo ""

simulate_log_err:
	@echo ""
	@echo "------------------------------------------------------------"
	@echo "-------------------- Simulation Report ---------------------"
	@echo ""
	@echo "UVM Fatal"
	@grep "FATAL" simulation.log || echo "No UVM_FATAL"
	@echo ""
	@echo "UVM Errors"
	@grep "ERROR" simulation.log | grep -v "NO_ERROR" || echo "No UVM_ERROR"
	@echo ""
	@echo "UVM Warnings"
	@grep "WARNING" simulation.log || echo "No UVM_WARNING"
	@echo ""
	@echo "Waveform: vsim -view waveform.wlf &"
	@echo "------------------------------------------------------------"
	@echo ""
