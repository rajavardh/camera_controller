#
# ==============================================================================
all: compile compile_log_err sim simulate_log_err

# ==============================================================================
# Environment Variables & Include Directories
# ==============================================================================
APB_VIP_DIR  = ./apb_avip
AXI_VIP_DIR  = ./axi_avip
COMMON_DIR   = ../camera_controller/common
AXI_CTRL_DIR = ../camera_controller/axi_files
RTL_DIR      = ../camera_controller
VLOG         = vlog
VSIM         = vsim


# Clean, unbroken include path (no trailing spaces!)
INC_DIR = +incdir+$(APB_VIP_DIR)/globals+$(APB_VIP_DIR)/hvl_top/env+$(APB_VIP_DIR)/hvl_top/env/virtual_sequencer+$(APB_VIP_DIR)/hvl_top/test/sequences/master_sequences+$(AXI_VIP_DIR)/globals+$(AXI_VIP_DIR)/hvl_top/master+../camera_controller+.+./dvp_agent+./interfaces+./dma_agent

# Clean, unbroken include path (Added +./dma_agent)
INC_DIR = +incdir+$(APB_VIP_DIR)/globals+$(APB_VIP_DIR)/hvl_top/env+$(APB_VIP_DIR)/hvl_top/env/virtual_sequencer+$(APB_VIP_DIR)/hvl_top/test/sequences/master_sequences+$(AXI_VIP_DIR)/globals+$(AXI_VIP_DIR)/hvl_top/master+../camera_controller+.+./dvp_agent+./dma_agent+./interfaces+$(AXI_CTRL_DIR)


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
	# 4. Compile Common and Controller RTL
	# ---------------------------------------------------------
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/mux_sync.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sync_ff.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/intr_req_ack.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sram_wrapper.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/irq_sync_fast_to_slow.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/pulse_extend_sync.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/cam_disp_dma_req_sync.sv

	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/camera_ctrl_bus_interface.v
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/camera_ctrl_localparams.sv
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/camera_ctrl_reg_block.v
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/camera_ctrl_reg_interface.v
	
	# Real SRAM Memory Core
	$(VLOG) -work work $(INC_DIR) $(COMMON_DIR)/sram_cam_disp_8KB.v

	# Real ARM AXI5 SRAM Controller Files
	# --- Basic Primitives (Must be compiled first) ---
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_arm_and2.v
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_arm_or2.v
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_arm_sdff2yrpq.v
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_arm_xor2.v
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_or_tree.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_sync.sv
	
	# --- Core Controller Modules ---
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_addr_dec.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_arb.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_arq.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_awq.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_axi_mux.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_bq.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_clamp.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_fifo_core.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_fifo.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_lpi_ctrl.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_one_hot.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_rbeat.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_resp_gen.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_rq.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_wbeat.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp_wq.sv
	$(VLOG) -work work $(INC_DIR) $(AXI_CTRL_DIR)/sie300_axi5_sram_ctrl_cam_disp.sv
	
	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/camera_data_pipe.sv
	$(VLOG) -work work $(INC_DIR) $(RTL_DIR)/camera_controller.sv
	# ---------------------------------------------------------
	# 5. Compile Top
	# ---------------------------------------------------------
	$(VLOG) -l top.log -work work $(INC_DIR) ./cam_top.sv

sim:
	vsim -c -wlf waveform.wlf -voptargs="+acc" "+notimingchecks" -l simulation.log -do "assertion fail -action continue -recursive /*; log -r /*; run -all; quit -f" -L work "+UVM_TESTNAME=camera_base_test" "+UVM_MAX_QUIT_COUNT=500" work.top
clean:
	rm -rf work modelsim.ini transcript waveform.wlf vsim.wlf vsim_stacktrace.vstf top.log simulation.log

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
