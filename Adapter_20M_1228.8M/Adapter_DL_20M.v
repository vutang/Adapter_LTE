// Author: 								Thien-Vu Tang
// Editor:								Thien-Vu Tang
// Date(ddmmyyyy): 						11082015
// Project: 							AD9361_Adapter_v1_0
// Module Name: 						AD9361_Adapter
// Type:								Verilog file
// Last modified by: 					ThienVutang
// Last modified time (ddmmyyyy): 		11082015

module Adapter_DL #(
    parameter   IQ_BIT_WIDTH = 16,
                FIFO_BIT_WIDTH = 32,
                FIFO_ADDR_WIDTH = 8
)
(
	input wire 			clk_1,    // Clock
	input wire          clk_2,
	input wire 			rst_n,  // Asynchronous reset active low

	// Signal from UTRA-FDD
	input wire 			iq_rx_data_valid,
	input wire [8*IQ_BIT_WIDTH-1:0]	iq_rx_i, iq_rx_q,

	// Signal from Unpack
	input wire 			duc_read_req,
	output wire [31:0]	adapter_data_out,
	output reg 		adapter_data_valid
);

	// Capture Signal
	reg [4:0] capture_counter;	
	reg [8*IQ_BIT_WIDTH-1:0] iq_rx_i_capture, iq_rx_q_capture;
    reg iq_rx_q_capture_valid;
    reg enable;

    // Shifting Signal
    reg shift_state;
    reg [4:0] shift_counter;
    reg enable_2;
    reg [31:0] shift_data;
    reg shift_valid;
    
    // FIFO Signal
    reg fifo_wr;
    reg [FIFO_BIT_WIDTH-1:0] fifo_w_data;
    reg fifo_rd;
    wire [FIFO_BIT_WIDTH-1:0] fifo_r_data;
    wire fifo_full;
    wire fifo_empty;
    

    
//	ila_adapter ila_adapter_1 (
//            .clk(clk_1),
//            // UTRA Module Interface
//            .probe0(capture_counter),
//            .probe1(iq_rx_i_capture),            
//            .probe2(iq_rx_q_capture),  
//            .probe3(iq_rx_q_capture_valid),
//            .probe4(enable),
//            // Adapter_DL Interface
//            .probe5(shift_counter),
//            .probe6(enable_2),
//            .probe7(adapter_data_out),
//            .probe8(adapter_data_valid)
//        );
        
    // ila_2 ila_adapter_1 (
    //         .clk(clk_1),
    //         // UTRA Module Interface
    //         .probe0(capture_counter),
    //         .probe1(iq_rx_i_capture),            
    //         .probe2(iq_rx_q_capture),  
    //         .probe3(iq_rx_q_capture_valid),
    //         .probe4(enable),
    //         // Adapter_DL Interface
    //         .probe5(shift_counter),
    //         .probe6(enable_2)
    //     );
    
    // capture Process  

//    ila_0 ila_adapter_capture (
//        .clk(clk_1),
//        // UTRA Module Interface
//        .probe0(capture_counter),//5
//        .probe1(iq_rx_i_capture),   //128         
//        .probe2(iq_rx_q_capture),   //128
//        .probe3(iq_rx_q_capture_valid), //1
//        .probe4(enable), //1
//        // Adapter_DL Interface
//        .probe5(shift_counter), //5
//        .probe6(enable_2),  // 1
//        .probe7(fifo_r_data) // 32
//    );
        
    ila_2 ila_adapter_fifo (
        .clk(clk_1),
        .probe0(fifo_wr), // 1
        .probe1(fifo_w_data), // 32            
        .probe2(fifo_rd),  // 1
        .probe3(fifo_r_data), // 32
        .probe4(shift_valid), // 1
        .probe5(shift_data) // 32
        );  
    always @(posedge clk_1 or negedge rst_n) begin
        if (~rst_n) begin
            enable <= 1'b0;
        end
        else if (iq_rx_data_valid) begin
            enable <= 1'b1;
        end
    end
    

    always @(posedge clk_1 or negedge rst_n) begin
        if (~rst_n)
            capture_counter <= 5'd0;
        else if (enable) begin
            capture_counter <= capture_counter + 5'd1;
        end
    end

    always @(posedge clk_1 or negedge rst_n) begin
        if (~rst_n) begin
            iq_rx_i_capture <= {8*IQ_BIT_WIDTH{1'b0}};
            iq_rx_q_capture <= {8*IQ_BIT_WIDTH{1'b0}};
        end
        else if (capture_counter == 5'd18) begin
            iq_rx_i_capture <= iq_rx_i;
            iq_rx_q_capture <= iq_rx_q;
            iq_rx_q_capture_valid <= 1'b1;
        end
        else begin
            iq_rx_q_capture_valid <= 1'b0;
            // iq_rx_q_capture <= iq_rx_q_capture;
            // iq_rx_i_capture <= iq_rx_i_capture;
        end 
    end
    
    // Shifting Process
    always @(posedge clk_1 or negedge rst_n) begin
        if (~rst_n) begin
            enable_2 <= 1'b0;
        end
        else if (capture_counter == 5'd18) begin
            enable_2 <= 1'b1;
        end
    end

    always @(posedge clk_1 or negedge rst_n) begin
        if (~rst_n) begin
            shift_counter <= 5'd0;
        end
        else if (enable_2) begin
            shift_counter <= shift_counter + 5'd1;
        end
    end

    generate 
        if (IQ_BIT_WIDTH == 16) begin
            always @(posedge clk_1 or negedge rst_n) begin
                if (~rst_n) begin
                    shift_data <= 32'd0;
                end
                else if (shift_counter == 5'd3) begin
                    shift_data <= {iq_rx_q_capture[IQ_BIT_WIDTH-1:0], 
                                   iq_rx_i_capture[IQ_BIT_WIDTH-1:0]}; 		// 15:0
                    shift_valid <= 1'b1;
                end         
                else if (shift_counter == 5'd7) begin
                    shift_data <= {iq_rx_q_capture[IQ_BIT_WIDTH*2-1:IQ_BIT_WIDTH], 
                                   iq_rx_i_capture[IQ_BIT_WIDTH*2-1:IQ_BIT_WIDTH]}; 	// 31:16
                    shift_valid <= 1'b1;
                end        
                else if (shift_counter == 5'd11) begin
                    shift_data <= {iq_rx_q_capture[IQ_BIT_WIDTH*3-1:IQ_BIT_WIDTH*2], 
                                   iq_rx_i_capture[IQ_BIT_WIDTH*3-1:IQ_BIT_WIDTH*2]}; 		// 47:32
                    shift_valid <= 1'b1;
                end
                else if (shift_counter == 5'd15) begin
                   shift_data <= {iq_rx_q_capture[IQ_BIT_WIDTH*4-1:IQ_BIT_WIDTH*3], 
                                  iq_rx_i_capture[IQ_BIT_WIDTH*4-1:IQ_BIT_WIDTH*3]}; 		// 63:48
                   shift_valid <= 1'b1;
                end
                else if (shift_counter == 5'd19) begin
                    shift_data <= {iq_rx_q_capture[IQ_BIT_WIDTH*5-1:IQ_BIT_WIDTH*4], 
                                   iq_rx_i_capture[IQ_BIT_WIDTH*5-1:IQ_BIT_WIDTH*4]};		// 79:64
                    shift_valid <= 1'b1;
                end         
                else if (shift_counter == 5'd23) begin
                    shift_data <= {iq_rx_q_capture[IQ_BIT_WIDTH*6-1:IQ_BIT_WIDTH*5], 
                                   iq_rx_i_capture[IQ_BIT_WIDTH*6-1:IQ_BIT_WIDTH*5]};		// 95:80
                    shift_valid <= 1'b1;
                end        
                else if (shift_counter == 5'd27) begin
                    shift_data <= {iq_rx_q_capture[IQ_BIT_WIDTH*7-1:IQ_BIT_WIDTH*6], 
                                   iq_rx_i_capture[IQ_BIT_WIDTH*7-1:IQ_BIT_WIDTH*6]};		// 111:96
                    shift_valid <= 1'b1;
                end                
                else if (shift_counter == 5'd31) begin
                   shift_data <= {iq_rx_q_capture[IQ_BIT_WIDTH*8-1:IQ_BIT_WIDTH*7], 
                                  iq_rx_i_capture[IQ_BIT_WIDTH*8-1:IQ_BIT_WIDTH*7]}; 		// 127:112
                   shift_valid <= 1'b1;
                end
                else 
                    shift_valid <= 1'b0;
            end
        end
        else if (IQ_BIT_WIDTH == 15) begin
            always @(posedge clk_1 or negedge rst_n) begin
                if (~rst_n) begin
                    shift_data <= 32'd0;
                end
                else if (shift_counter == 5'd3) begin
                    shift_data <= {1'b0,iq_rx_q_capture[IQ_BIT_WIDTH-1:0], 
                                   1'b0,iq_rx_i_capture[IQ_BIT_WIDTH-1:0]};         // 15:0
                    shift_valid <= 1'b1;
                end         
                else if (shift_counter == 5'd7) begin
                    shift_data <= {1'b0,iq_rx_q_capture[IQ_BIT_WIDTH*2-1:IQ_BIT_WIDTH], 
                                   1'b0,iq_rx_i_capture[IQ_BIT_WIDTH*2-1:IQ_BIT_WIDTH]};     // 31:16
                    shift_valid <= 1'b1;
                end        
                else if (shift_counter == 5'd11) begin
                    shift_data <= {1'b0,iq_rx_q_capture[IQ_BIT_WIDTH*3-1:IQ_BIT_WIDTH*2], 
                                   1'b0,iq_rx_i_capture[IQ_BIT_WIDTH*3-1:IQ_BIT_WIDTH*2]};         // 47:32
                    shift_valid <= 1'b1;
                end
                else if (shift_counter == 5'd15) begin
                    shift_data <= {1'b0,iq_rx_q_capture[IQ_BIT_WIDTH*4-1:IQ_BIT_WIDTH*3], 
                                  1'b0,iq_rx_i_capture[IQ_BIT_WIDTH*4-1:IQ_BIT_WIDTH*3]};         // 63:48
                    shift_valid <= 1'b1;
                end
                else if (shift_counter == 5'd19) begin
                    shift_data <= {1'b0,iq_rx_q_capture[IQ_BIT_WIDTH*5-1:IQ_BIT_WIDTH*4], 
                                   1'b0,iq_rx_i_capture[IQ_BIT_WIDTH*5-1:IQ_BIT_WIDTH*4]};        // 79:64
                    shift_valid <= 1'b1;
                end         
                else if (shift_counter == 5'd23) begin
                    shift_data <= {1'b0,iq_rx_q_capture[IQ_BIT_WIDTH*6-1:IQ_BIT_WIDTH*5], 
                                   1'b0,iq_rx_i_capture[IQ_BIT_WIDTH*6-1:IQ_BIT_WIDTH*5]};        // 95:80
                    shift_valid <= 1'b1;
                end        
                else if (shift_counter == 5'd27) begin
                    shift_data <= {1'b0,iq_rx_q_capture[IQ_BIT_WIDTH*7-1:IQ_BIT_WIDTH*6], 
                                   1'b0,iq_rx_i_capture[IQ_BIT_WIDTH*7-1:IQ_BIT_WIDTH*6]};        // 111:96
                    shift_valid <= 1'b1;
                end                
                else if (shift_counter == 5'd31) begin
                    shift_data <= {1'b0,iq_rx_q_capture[IQ_BIT_WIDTH*8-1:IQ_BIT_WIDTH*7], 
                                   1'b0,iq_rx_i_capture[IQ_BIT_WIDTH*8-1:IQ_BIT_WIDTH*7]};         // 127:112
                    shift_valid <= 1'b1;
                end
                else 
                    shift_valid <= 1'b0;
            end
         end
    endgenerate
    // FIFO Controller
    Adapter_Fifo #(
        .FIFO_DATA_WIDTH(32),
        .FIFO_ADDR_WIDTH(4)) 
    FIFO (
        .clk   (clk_1),
        .rst_n (rst_n),
        .rd    (fifo_rd),
        .wr    (fifo_wr),
        .w_data(fifo_w_data),
        .empty (fifo_empty),
        .full  (fifo_full),
        .r_data(fifo_r_data));
            
    // FIFO Writing process
    always @(posedge clk_1 or negedge rst_n) begin
        if (~rst_n) begin
            fifo_wr <= 1'b0;
        end
        else begin
            if (shift_valid) begin
                fifo_wr <= 1'b1;
                fifo_w_data <= shift_data;
            end
            else begin
                fifo_wr <= 1'b0;
                fifo_w_data <= 0;
            end
        end
    end
    // FIFO Reading process
    reg read_ready, read_ready_counter_enable;
    reg [5:0] read_ready_counter;

    always @(posedge clk_1 or negedge rst_n) begin
        if (~rst_n) begin
            read_ready_counter_enable <= 1'b0;
        end
        else if (shift_valid) begin
            read_ready_counter_enable <= 1'b1;
        end
//        if (read_ready_counter_enable) begin
//            read_ready_counter <= read_ready_counter + 4'b1;
//        end

//        if (read_ready_counter == 6'd32)
//            read_ready <= 1'b1;
    end
    
    always @(posedge clk_1 or negedge rst_n) begin
        if (~rst_n) begin
            read_ready_counter <= 6'b0;
        end
        else if (read_ready_counter_enable) begin
            read_ready_counter <= read_ready_counter + 4'b1;
        end
    end
    
    always @(posedge clk_1 or negedge rst_n) begin
        if (~rst_n) begin
            read_ready <= 1'b0;                
        end
        else if (read_ready_counter == 6'd32) begin
            read_ready <= 1'b1;
        end
    end
    reg [4:0] read_counter;
    always @(posedge clk_2 or negedge rst_n) begin
        if (~rst_n) begin
            fifo_rd <= 1'b0;
            // fifo_r_data <= 32'b0;
            read_counter <= 5'b0;
        end
        else if (read_ready) begin
            read_counter <= read_counter + 5'd1;
            if ((read_counter == 5'd3)) begin
                fifo_rd <= 1'b1;
            end
            else if ((read_counter == 5'd7)) begin
                fifo_rd <= 1'b1;
            end
            else if ((read_counter == 5'd11)) begin
                fifo_rd <= 1'b1;
            end
            else if ((read_counter == 5'd15)) begin
                fifo_rd <= 1'b1;
            end
            else if ((read_counter == 5'd19)) begin
                fifo_rd <= 1'b1;
            end
            else if ((read_counter == 5'd23)) begin
                fifo_rd <= 1'b1;
            end
            else if ((read_counter == 5'd27)) begin
                fifo_rd <= 1'b1;
            end
            else if ((read_counter == 5'd31)) begin
                fifo_rd <= 1'b1;
            end
            else 
                fifo_rd <= 1'b0;
        end
    end
    always @(posedge clk_1) adapter_data_valid <= fifo_rd;
    assign adapter_data_out = fifo_r_data;
    // assigning test signal
    // assign counter_test = {capture_counter,shift_counter};   

endmodule