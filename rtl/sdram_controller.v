module sdram_controller(

// BUS INTERFACE
input        in_HCLK,
input        in_HRESET,
input        in_HWRITE,
input        in_HSEL,
input [31:0] in_HWDATA,
input [31:0] in_HADDR,

output reg        out_HREADY,
output reg [31:0] out_HRDATA,
// BUS INTERFACE END


// SDRAM MODEL INTERFACE
input [31:0] in_sdram_read_data,

output reg       out_CS,              // CHIP SELECT
output reg       out_write_en,
output reg       out_CAS,             //COLUMN ADRESS STROBE
output reg       out_RAS,             //ROW ADRESS STROBE
output reg[1:0]  out_bank_select,     // BANK SELECTION BITS
output reg[13:0] out_sdram_addr,      
output reg[31:0] out_sdram_write_data 
// SDRAM MODEL INTERFACE END

);

	// REGISTERED 
	reg [31:0] hold_HWDATA;
	reg [31:0] hold_sdram_read_data;
	// REGISTERED END
	
	
	// SDRAM FSM DEFINITION
	reg [3:0] state, next_state;
	localparam IDLE       = 4'b0000,
			READ_ACT      = 4'b0001,
			READ_NOP1     = 4'b0010,
			READ_CAS      = 4'b0011,
			READ_NOP2     = 4'b0100,
			READ_NOP3     = 4'b0101,
			WRITE_ACT     = 4'b0110,
			WRITE_NOP1    = 4'b0111,
			WRITE_CAS     = 4'b1000,
			WRITE_NOP2    = 4'b1001,
			WRITE_NOP3    = 4'b1010;
	// SDRAM FSM DEFINITION END
	
	
	
	// TRANSITION BLOCK
	always @(posedge (in_HRESET) or posedge(in_HCLK))begin
		if (in_HRESET)begin
			state                            <= IDLE;
		end
		else begin
			state                            <= next_state;
		end
	end
	// TRANSITION BLOCK END
	
	
	//SDRAM COMMAND CONTROLLER FSM
	always @(*) begin
	
		case(state)
	
			IDLE: begin
				if (in_HSEL == 1'b1 && in_HWRITE == 1'b1)begin
					out_HREADY                 = 1'b0;
					hold_sdram_read_data[31:0] = in_sdram_read_data[31:0];
					next_state                 = READ_ACT;
				end
				else if(in_HSEL == 1'b1 && in_HWRITE == 1'b0)begin
					out_HREADY                 = 1'b0;
					hold_HWDATA[31:0]          = in_HWDATA[31:0];	
					next_state                 = WRITE_ACT;                
				end
				else begin
					next_state = IDLE;
				end
			end
			
			//                               [31:31] 2 bits    [29:25] 5 bits  [24:16] 9 bits    [15:14] 2 bits  [13:0] 14 bits 
			// ADRESS DECODING: [31:0] ==>       10              bbbbb          bbbbbbbbb             bb         bbbbbbbbbbbbbb
			//                             Memory mapped I/O    INVALID        COLUMN ADRESS      BANK ADRESS      ROW ADRESS
			
			READ_ACT: begin          
				// SEND ROW ADRESS TO SDRAM (RAS) AND SELECT BANK
				out_sdram_addr[13:0] = in_HADDR[13:0];
				out_bank_select[1:0] = in_HADDR[15:14];				
				// ACT TRUTH TABLE CS#: 0, RAS#: 0, CAS#: 1, WE#(out_write_en): 1  
				out_CS       = 1'b0;
				out_RAS      = 1'b0;
				out_CAS      = 1'b1;
				out_write_en = 1'b1;
				//STATE TRANSITION
				next_state = READ_NOP1;
			end
			
			READ_NOP1: begin 
				// NOP TRUTH TABLE CS#: 0, RAS#: 1, CAS#: 1, WE#(out_write_en): 1 
				out_CS       = 1'b0;
				out_RAS      = 1'b1;
				out_CAS      = 1'b1;
				out_write_en = 1'b1;
				next_state   = READ_CAS;
			end
	
	
			READ_CAS: begin 
				// SEND COLUMN ADRESS TO SDRAM (CAS) AND SELECT BANK		
				out_sdram_addr[13:0] = in_HADDR[24:16];
				out_bank_select[1:0] = in_HADDR[15:14];			
				// READ TRUTH TABLE CS#: 0, RAS#: 1, CAS#: 0, WE#: 1				
				out_CS       = 1'b0;
				out_RAS      = 1'b1;
				out_CAS      = 1'b0;
				out_write_en = 1'b1;
				next_state   = READ_NOP2;				
			end
			
			READ_NOP2: begin 
				// NOP TRUTH TABLE CS#: 0, RAS#: 1, CAS#: 1, WE#(out_write_en): 1 
				out_CS       = 1'b0;
				out_RAS      = 1'b1;
				out_CAS      = 1'b1;
				out_write_en = 1'b1;
				next_state   = READ_NOP3;
			end
			
			READ_NOP3: begin 
				// DRIVE DATA TO PROCESSOR and TRIGGER out_READY TO ACTIVE;			
				out_HRDATA[31:0] = hold_sdram_read_data[31:0]; // 
				out_HREADY       = 1'b1;
				// NOP TRUTH TABLE CS#: 0, RAS#: 1, CAS#: 1, WE#(out_write_en): 1 
				out_CS       = 1'b0;
				out_RAS      = 1'b1;
				out_CAS      = 1'b1;
				out_write_en = 1'b1;
				next_state   = IDLE;
			end
			
					
			WRITE_ACT: begin          
				// SEND ROW ADRESS TO SDRAM (RAS) AND SELECT BANK
				out_sdram_addr[13:0] = in_HADDR[13:0];
				out_bank_select[1:0] = in_HADDR[15:14];				
				// ACT TRUTH TABLE CS#: 0, RAS#: 0, CAS#: 1, WE#(out_write_en): 1  
				out_CS       = 1'b0;
				out_RAS      = 1'b0;
				out_CAS      = 1'b1;
				out_write_en = 1'b1;
				//STATE TRANSITION
				next_state = WRITE_NOP1;
			end
			
			WRITE_NOP1: begin 
				// NOP TRUTH TABLE CS#: 0, RAS#: 1, CAS#: 1, WE#: 1
				out_CS       = 1'b0;
				out_RAS      = 1'b1;
				out_CAS      = 1'b1;
				out_write_en = 1'b1;
				next_state   = WRITE_CAS;
			end		
	
			WRITE_CAS: begin 
				// SEND COLUMN ADRESS TO SDRAM (CAS) AND SELECT BANK
				//registered cancelled
				out_sdram_addr[13:0] = in_HADDR[24:16];
				out_bank_select[1:0] = in_HADDR[15:14];
				// WRITE TRUTH TABLE CS#: 0, RAS#: 1, CAS#: 0, WE#: 0				
				out_CS       = 1'b0;
				out_RAS      = 1'b1;
				out_CAS      = 1'b0;
				out_write_en = 1'b0;
				next_state   = WRITE_NOP2;					
			end
			
			WRITE_NOP2: begin 
				// NOP TRUTH TABLE CS#: 0, RAS#: 1, CAS#: 1, WE#: 1
				out_CS       = 1'b0;
				out_RAS      = 1'b1;
				out_CAS      = 1'b1;
				out_write_en = 1'b1;
				next_state   = WRITE_NOP3;
			end
			
			WRITE_NOP3: begin 
				// NOP TRUTH TABLE CS#: 0, RAS#: 1, CAS#: 1, WE#: 1
				out_sdram_write_data = hold_HWDATA;
				out_CS       = 1'b0;
				out_RAS      = 1'b1;
				out_CAS      = 1'b1;
				out_write_en = 1'b1;
				next_state   = IDLE;
			end		
	
	
			default: begin //INHIBIT TRUTH TABLE CS#: 1, RAS#: X, CAS#: X, WE#: X
				out_CS       = 1'b1;
				out_RAS      = 1'b1;
				out_CAS      = 1'b1;
				out_write_en = 1'b1;
				next_state   = IDLE;
			end
	
		endcase
	end
	//SDRAM COMMAND CONTROLLER FSM END

endmodule