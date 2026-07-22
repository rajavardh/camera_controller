`ifndef DMA_PKG_SV
`define DMA_PKG_SV

package dma_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "dma_seq_item.sv"
    `include "dma_driver.sv"
    `include "dma_sequencer.sv"
    `include "dma_agent.sv"
    `include "dma_base_sequence.sv"

endpackage : dma_pkg

`endif 

