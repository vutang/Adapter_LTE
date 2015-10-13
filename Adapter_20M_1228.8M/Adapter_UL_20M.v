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
	output reg [127:0] 	iq_tx_i, iq_tx_q
    );
	
	// signal for FSM
//	localparam ZERO = 1'b0, ONE = 1'b1;
//	reg state = ZERO;
    reg [2:0] state;
	reg [31:0] tdata_buf_0, tdata_buf_1, tdata_buf_2, tdata_buf_3,
	           tdata_buf_5, tdata_buf_6, tdata_buf_7, tdata_buf_4;
	assign axis_tready = 1'b1;
	
	reg capture_done_buf;
	reg capture_valid;
    wire latch;

//	reg [4:0] counter = 0;
//    ila_4 ila_adapter_ul (
//        .clk(clk),
//        .probe0(tdata_buf_0),   //5
//        .probe1(tdata_buf_1),   //128         
//        .probe2(capture_done_buf)   //128
//        // .probe3(tdata_buf_3),   //1
//        // .probe4(tdata_buf_4),   //1
//        // .probe5(tdata_buf_5),   //5
//        // .probe6(tdata_buf_6),   // 1
//        // .probe7(tdata_buf_7)    // 32
//    );
    reg capture_done;
	always @(posedge clk) begin
		if (~rst_n) begin
//			counter <= 0;
			state <= 3'd0;
			tdata_buf_0 <= 0;
			tdata_buf_1 <= 0;
			tdata_buf_2 <= 0;
            tdata_buf_3 <= 0;
            tdata_buf_4 <= 0;
            tdata_buf_5 <= 0;
            tdata_buf_6 <= 0;
            tdata_buf_7 <= 0;
            capture_done <= 1'b0;
		end
		else begin
			case (state)
				3'd0: begin
					if (axis_tvalid) begin
						tdata_buf_0 <= axis_tdata;
						state <= 3'd1;
					end
					capture_done <= 1'b0;
				end
				3'd1: begin
					if (axis_tvalid) begin
						tdata_buf_1 <= axis_tdata;
						state <= 3'd2;
					end
					capture_done <= 1'b0;
				end
				3'd2: begin
                    if (axis_tvalid) begin
                        tdata_buf_2 <= axis_tdata;
                        state <= 3'd3;
                    end
                    capture_done <= 1'b0;
                end
				3'd3: begin
                    if (axis_tvalid) begin
                        tdata_buf_3 <= axis_tdata;
                        state <= 3'd4;
                    end
                    capture_done <= 1'b0;
                end
				3'd4: begin
                    if (axis_tvalid) begin
                        tdata_buf_4 <= axis_tdata;
                        state <= 3'd5;
                    end
                    capture_done <= 1'b0;
                end
                3'd5: begin
                    if (axis_tvalid) begin
                        tdata_buf_5 <= axis_tdata;
                        state <= 3'd6;
                    end
                    capture_done <= 1'b0;
                end
                3'd6: begin
                    if (axis_tvalid) begin
                        tdata_buf_6 <= axis_tdata;
                        state <= 3'd7;
                    end
                    capture_done <= 1'b0;
                end
                3'd7: begin
                    if (axis_tvalid) begin
                        tdata_buf_7 <= axis_tdata;
                        state <= 3'd0;
                    end
                    capture_done <= 1'b1;
                end
				default : /* default */;
			endcase
		end
	end
	always @(posedge clk) begin
		if (~rst_n) capture_valid <= 1'b0;
		else if (state == 3'd7) capture_valid <= 1'b1;
	end
	always @(posedge clk) 
		if (state == 3'd0 & capture_valid) capture_done_buf <= capture_done; 
		else capture_done_buf <= 1'b0;
	
	// assign latch = (capture_done_buf &capture_done) ^ capture_done;

	always @(posedge clk) begin
		if (~rst_n) begin
			iq_tx_i <= 128'd0;
			iq_tx_q <= 128'd0;
		end
		else if (capture_done_buf) begin
			iq_tx_i <= {tdata_buf_7[15:0], tdata_buf_6[15:0], tdata_buf_5[15:0], tdata_buf_4[15:0],
	                                    tdata_buf_3[15:0], tdata_buf_2[15:0], tdata_buf_1[15:0], tdata_buf_0[15:0]};
	        iq_tx_q <= {tdata_buf_7[31:16], tdata_buf_6[31:16], tdata_buf_5[31:16], tdata_buf_4[31:16],
                                        tdata_buf_3[31:16], tdata_buf_2[31:16], tdata_buf_1[31:16], tdata_buf_0[31:16]};
		end
	end
	// assign iq_tx_i = (state == 3'd0) ? {tdata_buf_7[15:0], tdata_buf_6[15:0], tdata_buf_5[15:0], tdata_buf_4[15:0],
	//                                     tdata_buf_3[15:0], tdata_buf_2[15:0], tdata_buf_1[15:0], tdata_buf_0[15:0]}: 
	// 					                iq_tx_i;
	// assign iq_tx_q = (state == 3'd0) ? {tdata_buf_7[31:16], tdata_buf_6[31:16], tdata_buf_5[31:16], tdata_buf_4[31:16],
	//                                        tdata_buf_3[31:16], tdata_buf_2[31:16], tdata_buf_1[31:16], tdata_buf_0[31:16]} :
	//                                        iq_tx_q;
endmodule
