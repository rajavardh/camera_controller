`ifndef DVP_SEQUENCE_SV
`define DVP_SEQUENCE_SV

class dvp_sequence extends uvm_sequence #(dvp_seq_item);

    `uvm_object_utils(dvp_sequence)

    rand cam_resolution_e target_res = RES_VGA;
    rand cam_format_e     target_fmt = FMT_RGB888;

    function new(string name = "dvp_sequence");
        super.new(name);
    endfunction

   virtual task body();
        dvp_seq_item req;
        int total_lines;
        int width;

        dvp_seq_item temp_item = dvp_seq_item::type_id::create("temp_item");
        
        if (!temp_item.randomize() with { res_cfg == local::target_res; }) begin
            `uvm_fatal("DVP_SEQ", "Failed to resolve sequence item constraints!")
        end
        
        total_lines = temp_item.line_count;
        
        // Decode width to perfectly size our manual arrays
        case (target_res)
            RES_720P:  width = 1280;
            RES_1080P: width = 1920;
            RES_VGA:   width = 640;
            RES_QVGA:  width = 320;
            default:   width = 320;
        endcase
        
        `uvm_info("DVP_SEQ", $sformatf("Starting Frame Generation: %0d Lines | Format: %s", total_lines, target_fmt.name()), UVM_LOW)

        for (int line = 0; line < total_lines; line++) begin
            req = dvp_seq_item::type_id::create("req");
            
            req.line_id = line; 
            
            start_item(req);
            
            if (!req.randomize() with {
                res_cfg           == local::target_res;
                format_cfg        == local::target_fmt;
                is_start_of_frame == (line == 0);
                is_end_of_frame   == (line == (total_lines - 1));
            }) begin
                `uvm_error("DVP_SEQ", "Failed to randomize active line!")
            end

            if (target_fmt == FMT_MJPEG) begin
                req.dvp_data_bytes = new[(width * 3) + 2];
                req.dvp_data_bytes[0] = ((width * 3) >> 8) & 8'hFF; 
                req.dvp_data_bytes[1] = (width * 3) & 8'hFF;        
                
                for (int i = 2; i < req.dvp_data_bytes.size(); i++) begin
                    req.dvp_data_bytes[i] = $urandom; 
                end
                
                if (line == 0) begin
                    req.dvp_data_bytes[2] = 8'hFF; 
                    req.dvp_data_bytes[3] = 8'hD8;
                end
                if (line == (total_lines - 1)) begin
                    req.dvp_data_bytes[req.dvp_data_bytes.size()-2] = 8'hFF; 
                    req.dvp_data_bytes[req.dvp_data_bytes.size()-1] = 8'hD9;
                end
            end 
            else if (target_fmt == FMT_YUV420_P || target_fmt == FMT_YUV420_I) begin
                // Even Lines = YYYY (Width), Odd Lines = YUYV (Width*2)
                if (line % 2 == 0) req.dvp_data_bytes = new[width];
                else               req.dvp_data_bytes = new[width * 2];
                
                foreach(req.dvp_data_bytes[i]) req.dvp_data_bytes[i] = $urandom;
            end
            else begin // RGB888
                req.dvp_data_bytes = new[width * 3];
                foreach(req.dvp_data_bytes[i]) req.dvp_data_bytes[i] = $urandom;
            end
            
            finish_item(req);
        end
        
        `uvm_info("DVP_SEQ", "Frame Transmission Complete.", UVM_LOW)
    endtask
endclass

`endif // DVP_SEQUENCE_SV
