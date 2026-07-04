
`timescale 1ns/1ps

interface camera_dvp_if (
    input logic dvp_pclk, 
    input logic rst_n     
);

    logic        dvp_vsync; 
    logic        dvp_href;  
    logic [7:0]  dvp_data;  
    logic        cam_clk;   

    clocking cb_ctrl @(posedge dvp_pclk);
        default input #1step output #1ns;
        input  rst_n;
        input  dvp_vsync;
        input  dvp_href;
        input  dvp_data;
        output cam_clk;
    endclocking

    clocking cb_drv @(posedge dvp_pclk);
        default input #1step output #1ns;
        output dvp_vsync;
        output dvp_href;
        output dvp_data;
        input  cam_clk;
    endclocking
    
    clocking cb_mon @(posedge dvp_pclk);
        input rst_n;
        input dvp_vsync;
        input dvp_href;
        input dvp_data;
        input cam_clk;
    endclocking
endinterface

