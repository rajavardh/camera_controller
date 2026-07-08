`ifndef CAMERA_SS_PKG_SV
`define CAMERA_SS_PKG_SV

package camera_ss_pkg;

   import uvm_pkg::*;
   `include "uvm_macros.svh"

   // APB VIP Packages
   import apb_global_pkg::*;
   import apb_master_pkg::*;
   import apb_env_pkg::*;
   import apb_slave_pkg::*;
   
   import axi4_globals_pkg::*;
   import axi4_master_pkg::*;
   
   // DVP Package
   import dvp_pkg::*;

   // Integration Components
   `include "camera_vsequencer.sv"
   `include "camera_ss_env.sv"

   // Sequences & Test
   `include "apb_master_base_seq.sv" // VIP Base
   `include "camera_reg_cfg_seq.sv"  // Our wrapper
   `include "camera_axi_read_seq.sv" // Our AXI read
   `include "camera_vseq.sv"         // Virtual sequence
   `include "camera_base_test.sv"    // Test

endpackage : camera_ss_pkg

`endif // CAMERA_SS_PKG_SV
