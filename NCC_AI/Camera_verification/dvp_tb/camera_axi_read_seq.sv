`ifndef CAMERA_AXI_READ_SEQ_SV
`define CAMERA_AXI_READ_SEQ_SV

class camera_axi_read_seq extends uvm_sequence #(axi4_master_tx);
    `uvm_object_utils(camera_axi_read_seq)

    cam_format_e     cfg_fmt;
    cam_resolution_e cfg_res;
    rand bit [31:0]  target_addr; 

    // --- RTL HARDCODED ADDRESS OFFSETS ---
    localparam int U_START_ADD = 300; 
    localparam int V_START_ADD = 400; 

    function new(string name = "camera_axi_read_seq");
        super.new(name);
    endfunction

    task body();
        int width;
        int max_line_bytes;
        int hardware_stride;
        
        case (cfg_res)
            RES_720P:  width = 1280;
            RES_1080P: width = 1920;
            RES_VGA:   width = 640;
            RES_QVGA:  width = 320;
            default:   width = 320;
        endcase

        if (cfg_fmt == FMT_YUV420_P) begin
            // -------------------------------------------------------------
            // PLANAR: Emulate DMA 3-Descriptor Jump
            // -------------------------------------------------------------
            int y_stride = (((width * 2) + 127) / 128) * 128;
            int u_stride = (((width / 2) + 127) / 128) * 128;
            int v_stride = (((width / 2) + 127) / 128) * 128;

            `uvm_info("CAM_AXI_SEQ", $sformatf("Reading Planar Y Block -> Bursts: %0d", y_stride/128), UVM_LOW)
            extract_memory_block(target_addr, y_stride / 128);

            `uvm_info("CAM_AXI_SEQ", $sformatf("Reading Planar U Block -> Bursts: %0d", u_stride/128), UVM_LOW)
            extract_memory_block(target_addr + (U_START_ADD * 16), u_stride / 128); 

            `uvm_info("CAM_AXI_SEQ", $sformatf("Reading Planar V Block -> Bursts: %0d", v_stride/128), UVM_LOW)
            extract_memory_block(target_addr + (V_START_ADD * 16), v_stride / 128); 

        end else begin
            // -------------------------------------------------------------
            // RGB, MJPEG, INTERLEAVED: Linear Block
            // -------------------------------------------------------------
            max_line_bytes  = width * 3;
            hardware_stride = ((max_line_bytes + 127) / 128) * 128;

            `uvm_info("CAM_AXI_SEQ", $sformatf("Reading Linear SRAM Block -> Bursts: %0d", hardware_stride/128), UVM_LOW)
            extract_memory_block(target_addr, hardware_stride / 128);
        end
    endtask

    task extract_memory_block(bit [31:0] start_addr, int total_bursts);
        axi4_master_tx req;
        int current_addr;
        semaphore data_done; 
        
        current_addr = start_addr;
        data_done    = new(0);

        fork
            begin : RESPONSE_CONSUMER_LOOP
                uvm_sequence_item rsp;
                for (int j = 0; j < total_bursts; j++) begin
                    get_response(rsp); 
                    data_done.put(1);  
                end
            end
        join_none 
         
        for (int i = 0; i < total_bursts; i++) begin
            req = axi4_master_tx::type_id::create("req");
            start_item(req);
            
            if (!req.randomize() with {
                tx_type       == axi4_globals_pkg::READ;              
                arsize        == axi4_globals_pkg::READ_16_BYTES;       
                arburst       == axi4_globals_pkg::READ_INCR;           
                transfer_type == axi4_globals_pkg::OUTSTANDING_READ;  
                araddr        == local::current_addr;       
                arlen         == 8'd7; 
                arid          == axi4_globals_pkg::ARID_0; 
            }) begin
                `uvm_error("CAM_AXI_SEQ", "VIP Unified Randomization failed!")
            end
            
            finish_item(req);
            current_addr = current_addr + 128;
        end
        data_done.get(total_bursts); 
    endtask
endclass 
`endif // CAMERA_AXI_READ_SEQ_SV
