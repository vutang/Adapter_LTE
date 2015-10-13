// Author: 								Pong. Chu
// Editor:								Thien-Vu Tang
// Date(ddmmyyyy): 						11082015
// Project: 							AD9261_Adapter_v1_0
// Module Name: 						Fifo
// Type:								Verilog file
// Last modified by: 					Thien-Vu Tang
// Last modified time (ddmmyyyy): 		11082015

module Adapter_Fifo #(
	parameter FIFO_DATA_WIDTH = 8, 	// Fifo data bit width
			  FIFO_ADDR_WIDTH = 4	// Fifo address bit width
)(
	input wire 							clk, 
	input wire 							rst_n, // negative reset

	input wire 							rd, wr, // read/write signals
	input wire 	[FIFO_DATA_WIDTH-1:0] 	w_data,	// write data
	output wire 						empty, full,	// fifo status signal
	output wire [FIFO_DATA_WIDTH-1:0] 	r_data	// read data
);
	// FIFO Declartion
	reg [FIFO_DATA_WIDTH-1:0] array_reg [2**FIFO_ADDR_WIDTH-1:0]; 

	// FIFO signal
	reg [FIFO_ADDR_WIDTH-1:0] w_ptr_reg, w_ptr_next, w_ptr_succ;
	reg [FIFO_ADDR_WIDTH-1:0] r_ptr_reg, r_ptr_next, r_ptr_succ;
	reg full_reg, empty_reg, full_next, empty_next;
	
	wire wr_en;

	always @(posedge clk)
		if (wr_en)
			array_reg[w_ptr_reg] <= w_data;
			
	assign r_data = array_reg[r_ptr_reg];
	assign wr_en = wr & ~full_reg;
	
	// 
	always @(posedge clk)
		if(~rst_n) begin
			w_ptr_reg <= 0;
			r_ptr_reg <= 0;
			full_reg <= 1'b0;
			empty_reg <= 1'b1;
		end 
		else begin
			w_ptr_reg <= w_ptr_next;
			r_ptr_reg <= r_ptr_next;
			full_reg <= full_next;
			empty_reg <= empty_next;
		end 

	always @*
	begin
		w_ptr_succ = w_ptr_reg + 1;
		r_ptr_succ = r_ptr_reg + 1;
		w_ptr_next = w_ptr_reg;
		r_ptr_next = r_ptr_reg;
		full_next  = full_reg;
		empty_next = empty_reg;
		case ({wr,rd})
			2'b01:
				if(~empty_reg) begin
					r_ptr_next <= r_ptr_succ;
					full_next = 1'b0;
					if(r_ptr_succ == w_ptr_reg)
						empty_next = 1'b1;
				end 
			2'b10:
				if(~full_reg) begin
					w_ptr_next = w_ptr_succ;
					empty_next = 1'b0;
					if(w_ptr_succ == r_ptr_reg)
						full_next = 1'b1;
				end
			2'b11: begin
				r_ptr_next = r_ptr_succ;
				w_ptr_next = w_ptr_succ;
			end
		endcase
	end
		
	assign full = full_reg;
	assign empty = empty_reg;
endmodule					