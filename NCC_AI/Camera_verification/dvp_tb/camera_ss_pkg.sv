`ifndef CAMERA_SS_PKG_SV
`define CAMERA_SS_PKG_SV

package camera_ss_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // 1. Import the Corporate APB VIP Packages
  import apb_global_pkg::*;
  import apb_master_pkg::*; 
  import apb_env_pkg::*;
  // 2. Import your custom DVP Package
  import dvp_pkg::*;

  // 3. Include the Subsystem Integration Components
  `include "camera_vsequencer.sv"
  `include "camera_ss_env.sv"

  // 4. Include the Sequences (Strict Order Required)
  `include "camera_reg_cfg_seq.sv"  // APB wrapper compiles first
  `include "camera_vseq.sv"         // Virtual sequence compiles second

  // 5. Include the Tests
  `include "camera_base_test.sv"    // Test compiles last

endpackage : camera_ss_pkg

`endif // CAMERA_SS_PKG_SV
