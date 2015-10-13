`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2015 03:43:09 PM
// Design Name: 
// Module Name: CPRI_DDC_Adapter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Adapter_UL(
	input 			clk, rst_n,
	// Port for AXIS DDC
	input [31:0] 	axis_tdata,
	input 			axis_tvalid,

	output 			axis_tready,
	// Port for CPRI
	output [31:0] 	iq_tx_i, iq_tx_q
    );
	
	// signal for FSM
	localparam ZERO = 1'b0, ONE = 1'b1;
	reg state = ZERO;
	reg [31:0] tdata_buf_1 = 0;
	reg	[31:0] tdata_buf_2 = 0;

	reg [4:0] counter = 0;

	always @(posedge clk) begin
		if (~rst_n) begin
			counter <= 0;
			state <= ZERO;
			tdata_buf_1 <= 0;
			tdata_buf_2 <= 0;
		end
		else begin
			case (state)
				ZERO: begin
					if (axis_tvalid) begin
						tdata_buf_1 <= axis_tdata;
						state <= ONE;
					end
				end
				ONE: begin
					if (axis_tvalid) begin
						tdata_buf_2 <= axis_tdata;
						state <= ZERO;
					end
				end
				default : /* default */;
			endcase
		end
	end

	assign axis_tready = 1'b1;

	assign iq_tx_i = (state == ZERO) ? {tdata_buf_2[15:0], tdata_buf_1[15:0]} : 
						iq_tx_i;
	assign iq_tx_q = (state == ZERO) ? {tdata_buf_2[31:16], tdata_buf_1[31:16]} :
						iq_tx_q;
endmodule
