`ifndef DMA_SEQ_ITEM_SV
`define DMA_SEQ_ITEM_SV
class dma_seq_item extends uvm_sequence_item;
    `uvm_object_utils(dma_seq_item)

    bit [1:0] dma_trig_req_type; 
    bit [1:0] dma_trig_ack_type; 

    function new(string name = "dma_seq_item");
        super.new(name);
    endfunction
endclass
`endif 
