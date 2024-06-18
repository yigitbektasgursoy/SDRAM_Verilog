`timescale 1ns / 1ps

module sdram_top
(input        in_HCLK,        
 input        in_HRESET,      
 input        in_HWRITE,         
 input        in_HSEL,        
 input [31:0] in_HWDATA,      
 input [31:0] in_HADDR,       

 output         out_HREADY,
 output  [31:0] out_HRDATA
);

    wire [31:0]sdram_read_data;
    wire CS, write_en, CAS, RAS;
    wire [1:0]bank_select;
    wire [13:0]sdram_addr;
    wire [31:0]sdram_write_data;
    
        sdram_controller sdram_controller(in_HCLK, in_HRESET, in_HWRITE, in_HSEL, in_HWDATA,in_HADDR,
                                          out_HREADY, out_HRDATA,
                                          
                                          sdram_read_data,
                                          CS, write_en, CAS, RAS, bank_select, sdram_addr, sdram_write_data); 
                                          
        sdram_model sdram_model(in_HCLK, CS, write_en, CAS, RAS, bank_select, sdram_addr, sdram_write_data, sdram_read_data); 

endmodule