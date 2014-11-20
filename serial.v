`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:06:59 11/16/2014 
// Design Name: 
// Module Name:    serial 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module serial # (
    parameter TRUE = 1'b1,
    parameter FALSE = 1'b0,

    parameter CLOCK_PER_BAUD_RATE = 5208,
    parameter SERIAL_STATE_LAST = 8,
    parameter SERIAL_STATE_SENT = 9,
    parameter SERIAL_STATE_WAIT = 10
)(
    input CLOCK_50M,
    // input RX,
    output TX,
    input [63:0] send_buffer_in,
    input [2:0] send_buffer_count_in,
    // output [63:0] send_buffer_out,
    output [2:0] send_buffer_count_out,
    output LED1,
    output LED2
);

reg [63:0] send_buffer;
reg [2:0] send_buffer_count;
assign send_buffer_out = send_buffer;
assign send_buffer_count_out = send_buffer_count;

/*
 * CLOCK GENERATOR
 */
reg CLOCK = FALSE;
reg [15:0] clock_counter;
always @(posedge CLOCK_50M) begin
    if (clock_counter < CLOCK_PER_BAUD_RATE) begin
        CLOCK <= FALSE;
        clock_counter <= clock_counter + 1;
    end
    else begin
        CLOCK <= TRUE;
        clock_counter <= 0;
    end
end

/*
 * TRANSMIT DATA
 */
// reg serial_state = SERIAL_STATE_WAIT;
reg [7:0] tx_buffer = "A";
reg [3:0] tx_counter = SERIAL_STATE_WAIT; // 0->start bit sent,1=>first bit sent,...8=>wight bit sent,9=>sent, 10=>not send yet
reg tx_state = TRUE;
assign TX = tx_state;
assign LED1 = tx_state;
assign LED2 = TRUE;
// wire send_buffer_input;
// wire send_buffer_count_input;
// assign send_buffer_input = send_buffer;
// assign send_buffer_count_input = send_buffer_count;

always @(posedge CLOCK) begin
    if (tx_counter == SERIAL_STATE_WAIT) begin
        tx_state <= FALSE;
        tx_counter <= 0;
    end
    else if (tx_counter == SERIAL_STATE_LAST) begin
        tx_state <= TRUE;
        tx_counter <= SERIAL_STATE_SENT;
    end
    else if (tx_counter == SERIAL_STATE_SENT && send_buffer_count_in > 0) begin
        tx_buffer <= send_buffer_in[7:0];
        send_buffer <= send_buffer_in >> 8;
        send_buffer_count <= send_buffer_count_in - 1;
    end
    else begin
        tx_state <= tx_buffer[tx_counter];
        tx_counter <= tx_counter + 1;
    end
end

// function send (
//     input dummy
// );
// begin 
//     tx_buffer = "A";
//     tx_counter = SERIAL_STATE_WAIT;
// end
// endfunction

/*
 * RECEIVE DATA
 */
// always @(posedge CLOCK) begin

// end

endmodule
