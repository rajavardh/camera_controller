`ifndef DMA_DRIVER_SV
`define DMA_DRIVER_SV

class dma_driver extends uvm_driver#(dma_seq_item);
    `uvm_component_utils(dma_driver)
    
    virtual dma_trig_cam_cntrl_if vif;

    function new(string name = "dma_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.dma_trig_ack      <= 1'b0;
        vif.dma_trig_ack_type <= 2'b00;

        wait(vif.reset_n === 1'b1);

        forever begin
            seq_item_port.get_next_item(req);

            case (req.action)
                DMA_WAIT_REQ: begin
                    while (vif.master_cb.dma_trig_req !== 1'b1) begin
                        @(vif.master_cb); 
                    end
                    req.dma_trig_req_type = vif.master_cb.dma_trig_req_type;
                end

                DMA_DRIVE_ACK: begin
                    vif.master_cb.dma_trig_ack      <= 1'b1;
                    vif.master_cb.dma_trig_ack_type <= req.target_ack_type-1; //FIXME 
                    
                    while (vif.master_cb.dma_trig_req === 1'b1) begin
                        @(vif.master_cb);
                    end

                    repeat(2) @(vif.master_cb); 

                    vif.master_cb.dma_trig_ack      <= 1'b0;
                    vif.master_cb.dma_trig_ack_type <= 2'b00;
                    
                    @(vif.master_cb);
                end
            endcase


            seq_item_port.item_done();
        end
    endtask
endclass

`endif // DMA_DRIVER_SV

