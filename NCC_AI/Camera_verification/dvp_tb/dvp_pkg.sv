`ifndef DVP_PKG_SV
`define DVP_PKG_SV

package dvp_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "dvp_seq_item.sv"
  `include "dvp_sequencer.sv"
  `include "dvp_driver.sv"
  `include "dvp_monitor.sv"
  `include "dvp_agent.sv"
  `include "dvp_sequence.sv" 
  `include "dvp_scoreboard.sv"
  `include "dvp_subscriber.sv"
  `include "dvp_env.sv"

endpackage : dvp_pkg

`endif // DVP_PKG_SV
