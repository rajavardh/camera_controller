`ifndef DMA_SEQ_ITEM_SV
`define DMA_SEQ_ITEM_SV

typedef enum bit { DMA_WAIT_REQ, DMA_DRIVE_ACK } dma_action_e;

class dma_seq_item extends uvm_sequence_item;
    `uvm_object_utils(dma_seq_item)

    // Control fields
    rand dma_action_e action;
    rand bit [1:0]    target_ack_type;
    
    bit [1:0]         dma_trig_req_type;

    function new(string name = "dma_seq_item");
        super.new(name);
    endfunction
endclass

`endif // DMA_SEQ_ITEM_SV

