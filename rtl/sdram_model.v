module sdram_model
(
// SDRAM MODEL INTERFACE
input       in_CLK,
input       in_CS,              // CHIP SELECT
input       in_write_en,
input       in_CAS,             //COLUMN ADRESS STROBE
input       in_RAS,             //ROW ADRESS STROBE
input[1:0]  in_bank_select,     // BANK SELECTION BITS
input[13:0] in_sdram_addr,      
input[31:0] in_sdram_write_data,

output reg [31:0] out_sdram_read_data 
// SDRAM MODEL INTERFACE END
);

	parameter DATA   = 32,
			  ROW    = 16384,
			  COLUMN = 512;
			
	wire ACT,
		 READ_CAS,
		 WRITE_CAS,
		 NOP,
		 WRITE_READY;
 
	
	reg [13:0]registered_row     = 14'b0;
	reg [8:0]registered_column   = 9'b0;
	reg [1:0]registered_bank_sel = 2'b0;
	reg [1:0]nop_counter	     = 2'b0;
	reg registered_write_cas     = 1'b0, registered_read_cas = 1'b0;
		
	assign ACT         = ~in_CS && ~in_RAS && in_CAS && in_write_en;
	assign READ_CAS    = ~in_CS && in_RAS && ~in_CAS && in_write_en;
	assign WRITE_CAS   = ~in_CS && in_RAS && ~in_CAS && ~in_write_en;
	assign NOP         = ~in_CS && in_RAS && in_CAS && in_write_en;
	assign WRITE_READY = (nop_counter == 2 && NOP && registered_write_cas)? 1'b1: 1'b0; 
	reg [DATA-1 : 0] bank0 [0 : ROW-1][0 : COLUMN-1];
	reg [DATA-1 : 0] bank1 [0 : ROW-1][0 : COLUMN-1];
	reg [DATA-1 : 0] bank2 [0 : ROW-1][0 : COLUMN-1];
	reg [DATA-1 : 0] bank3 [0 : ROW-1][0 : COLUMN-1];
	
	localparam BANK0 = 2'b00,
			   BANK1 = 2'b01,
			   BANK2 = 2'b10,
			   BANK3 = 2'b11;
	
	always @(posedge in_CLK)begin
		if(!in_CS)begin
			if(ACT) begin
				registered_row[13:0]     <= in_sdram_addr[13:0];
				registered_bank_sel[1:0] <= in_bank_select[1:0];
			end
			else if (READ_CAS || WRITE_CAS)begin
				registered_column[8:0]   <= in_sdram_addr[8:0];
				registered_bank_sel[1:0] <= in_bank_select[1:0];
				registered_write_cas     <= WRITE_CAS;
			end

            if(nop_counter == 3)begin
                nop_counter <= 2'b0;
            end
            else if(NOP)begin
                nop_counter <= nop_counter + 1;    
            end	
		end
	end

    always @(*) begin
		if(WRITE_READY)begin

			case(registered_bank_sel)
		
				BANK0:begin
					bank0[registered_row][registered_column] = in_sdram_write_data;
				end
		
				BANK1:begin
					bank1[registered_row][registered_column] = in_sdram_write_data;
				end
		
				BANK2:begin
					bank2[registered_row][registered_column] = in_sdram_write_data;
				end
		
				BANK3:begin
					bank3[registered_row][registered_column] = in_sdram_write_data;
				end
		
			endcase	
		end
		else if(in_write_en)begin
		
			case(registered_bank_sel)
		
				BANK0:begin
					out_sdram_read_data = bank0[registered_row][registered_column];
				end
		
				BANK1:begin
					out_sdram_read_data = bank1[registered_row][registered_column];
				end
		
				BANK2:begin
					out_sdram_read_data = bank2[registered_row][registered_column];
				end
		
				BANK3:begin
					out_sdram_read_data = bank3[registered_row][registered_column];
				end
		
			endcase
		end	
	end

endmodule