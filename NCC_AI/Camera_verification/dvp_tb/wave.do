onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top/axi_vip_if/aclk
add wave -noupdate /top/dvp_if/rst_n
add wave -noupdate /top/axi_vip_if/arid
add wave -noupdate -radix decimal /top/axi_vip_if/araddr
add wave -noupdate -radix decimal /top/axi_vip_if/arlen
add wave -noupdate /top/axi_vip_if/arsize
add wave -noupdate /top/axi_vip_if/arburst
add wave -noupdate /top/axi_vip_if/arlock
add wave -noupdate /top/axi_vip_if/arcache
add wave -noupdate /top/axi_vip_if/arprot
add wave -noupdate /top/axi_vip_if/arqos
add wave -noupdate /top/axi_vip_if/arregion
add wave -noupdate /top/axi_vip_if/aruser
add wave -noupdate /top/axi_vip_if/arvalid
add wave -noupdate /top/axi_vip_if/arready
add wave -noupdate /top/axi_vip_if/rid
add wave -noupdate /top/axi_vip_if/rresp
add wave -noupdate /top/axi_vip_if/ruser
add wave -noupdate /top/axi_vip_if/rvalid
add wave -noupdate /top/axi_vip_if/rready
add wave -noupdate /top/dma_if/dma_trig_req
add wave -noupdate /top/dma_if/dma_trig_ack
add wave -noupdate /top/dvp_if/dvp_vsync
add wave -noupdate /top/dvp_if/dvp_href
add wave -noupdate /top/dvp_if/cam_clk
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_a/mem_clk
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_a/mem_addr
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_a/mem_d
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_a/mem_wen
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_a/mem_cen
add wave -noupdate /top/dvp_if/dvp_pclk
add wave -noupdate /top/dvp_if/dvp_data
add wave -noupdate /top/axi_vip_if/rdata
add wave -noupdate /top/axi_vip_if/rlast
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_a/mem_q
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_b/mem_q
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_b/mem_clk
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_b/mem_addr
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_b/mem_d
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_b/mem_wen
add wave -noupdate /top/dut/u_camera_data_pipe/sram_buffer_b/mem_cen
add wave -noupdate /top/dut/u_camera_data_pipe/sram_a_q
add wave -noupdate /top/dut/u_camera_data_pipe/sram_b_q
add wave -noupdate /top/dut/u_camera_data_pipe/byte_count
add wave -noupdate -radix decimal /top/dut/u_camera_data_pipe/pixel_count
add wave -noupdate /top/dut/u_camera_data_pipe/intr_line_tx_dn
add wave -noupdate /top/dut/u_camera_data_pipe/intr_line_in_dn
add wave -noupdate /top/dut/u_camera_data_pipe/intr_frm_tx_dn
add wave -noupdate /top/dut/u_camera_data_pipe/line_pix
add wave -noupdate /top/dut/u_camera_data_pipe/data_accumulator
add wave -noupdate /top/dma_if/dma_trig_req
add wave -noupdate /top/dma_if/dma_trig_ack
add wave -noupdate /top/dut/u_camera_data_pipe/dma_re_request
add wave -noupdate /top/dut/u_camera_data_pipe/dma_req_pending
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {14865000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 199
configure wave -valuecolwidth 304
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {2753031750 ps}
