`ifndef CAMERA_SS_PKG_SV
`define CAMERA_SS_PKG_SV

package camera_ss_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // 1. Import the Corporate APB VIP Packages
  import apb_global_pkg::*;
  import apb_master_pkg::*; 

  // 2. Import your custom DVP Package
  import dvp_pkg::*;

  // 3. Include the Subsystem Integration Components
  `include "camera_vsequencer.sv"
  `include "camera_ss_env.sv"

endpackage : camera_ss_pkg

`endif // CAMERA_SS_PKG_SV

