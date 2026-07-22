class dma_driver extends uvm_driver#(dma_item);
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

            while (vif.dma_trig_req !== 1'b1) begin
                @(posedge vif.clk);
            end

            vif.dma_trig_ack      <= 1'b1;
            vif.dma_trig_ack_type <= vif.dma_trig_req_type;
 
            req.dma_trig_req_type = vif.dma_trig_req_type;
            req.dma_trig_ack_type = vif.dma_trig_req_type;

            do begin
                @(posedge vif.clk);
            end while (vif.dma_trig_req === 1'b1);

            vif.dma_trig_ack      <= 1'b0;
            vif.dma_trig_ack_type <= 2'b00;
            @(posedge vif.clk);

            seq_item_port.item_done();
        end
    endtask
endclass

