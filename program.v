`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:08:51 11/14/2014 
// Design Name:    program
// Module Name:    program 
// Project Name:   VGA Playing
// Target Devices: Spartan 3AN Starter Kit
// Tool versions:  ISE Project Navigator P.20131013
// Description:    
//
//
//////////////////////////////////////////////////////////////////////////////////

module program # (
    parameter TRUE = 1'b1,
    parameter FALSE = 1'b0,

    // VGA specification from http://en.wikipedia.org/wiki/Video_Graphics_Array
    parameter H_ACTIVE_PIXEL = 640,
    parameter H_FPORCH_PIXEL = 16,
    parameter H_SYNC_PIXEL   = 96,
    parameter H_BPORCH_PIXEL = 48,
    parameter H_LIMIT_PIXEL  = H_ACTIVE_PIXEL + H_FPORCH_PIXEL + H_SYNC_PIXEL + H_BPORCH_PIXEL,

    parameter V_ACTIVE_LINE  = 480,
    parameter V_FPORCH_LINE  = 10,
    parameter V_SYNC_LINE    = 2,
    parameter V_BPORCH_LINE  = 33,
    parameter V_LIMIT_LINE   = V_ACTIVE_LINE + V_FPORCH_LINE + V_SYNC_LINE + V_BPORCH_LINE,

    parameter BLOCK_SIZE = 40,

    parameter SERIAL_CLOCK_PER_BAUD_RATE = 5208,
    parameter SERIAL_STATE_LAST = 8,
    parameter SERIAL_STATE_SENT = 9,
    parameter SERIAL_STATE_WAIT = 10
)(
    input wire CLOCK_50M,

    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,
    output wire VGA_HSYNC,
    output wire VGA_VSYNC,

    input wire RS232_DCE_RXD,
    output wire RS232_DCE_TXD,

    // input ROT_A,
    // input ROT_B,

    input wire BUTTON_NORTH,
    input wire BUTTON_WEST,
    input wire BUTTON_EAST,
    input wire BUTTON_SOUTH,
    output wire [4:0] LED
);

/*
 * SERIAL CLOCK GENERATOR
 */
reg CLOCK_SERIAL = FALSE;
reg [12:0] serial_clock_counter;
always @(posedge CLOCK_50M) begin
    if (serial_clock_counter < SERIAL_CLOCK_PER_BAUD_RATE) begin
        CLOCK_SERIAL <= FALSE;
        serial_clock_counter <= serial_clock_counter + 1;
    end
    else begin
        CLOCK_SERIAL <= TRUE;
        serial_clock_counter <= 0;
    end
end

/*
 * SERIAL TX
 */
reg [63:0] send_buffer = 64'b0;
reg [2:0] send_buffer_count = 3'b0;
reg [7:0] tx_buffer = 8'b0;
reg [3:0] tx_counter = SERIAL_STATE_SENT; // 0->start bit sent,1=>first bit sent,...8=>wight bit sent,9=>sent, 10=>not send yet
reg tx_state = TRUE;
assign RS232_DCE_TXD = tx_state;

// reg [63:0] receive_buffer = 64'b0;
// reg [2:0] receive_buffer_count = 3'b0;
reg [7:0] rx_buffer = 8'b0;
reg [3:0] rx_counter = SERIAL_STATE_WAIT;
wire rx_state = RS232_DCE_RXD;

initial begin
    send_buffer[7:0] <= "B";
    send_buffer_count <= 1;
end

always @(posedge CLOCK_SERIAL or posedge BUTTON_WEST) begin
    if (BUTTON_WEST == TRUE) begin
        send_buffer[7:0] <= "B";
        send_buffer_count <= 1;
    end
    else begin
        // TX
        if (tx_counter < SERIAL_STATE_LAST) begin
            tx_state <= tx_buffer[tx_counter];
            tx_counter <= tx_counter + 1;
        end
        else if (tx_counter == SERIAL_STATE_LAST) begin
            tx_state <= TRUE;
            tx_counter <= SERIAL_STATE_SENT;
        end
        else if (tx_counter == SERIAL_STATE_SENT && send_buffer_count > 0) begin
            tx_buffer <= send_buffer[7:0];
            tx_counter <= SERIAL_STATE_WAIT;
            send_buffer <= send_buffer >> 8;
            send_buffer_count <= send_buffer_count - 1;
        end
        else if (tx_counter == SERIAL_STATE_WAIT) begin
            tx_state <= FALSE;
            tx_counter <= 0;
        end

        // RX
        if (rx_counter < SERIAL_STATE_LAST) begin
            rx_buffer[rx_counter] <= rx_state;
            rx_counter <= rx_counter + 1;
        end
        else if (rx_counter == SERIAL_STATE_LAST) begin
            send_buffer[7:0] <= rx_buffer;
            send_buffer_count <= 1;
            block <= block << 1;
            block[0] <= rx_buffer == "1" ? TRUE : FALSE;
            rx_counter <= SERIAL_STATE_WAIT;
        end
        else if (rx_counter == SERIAL_STATE_WAIT && rx_state == FALSE) begin
            rx_counter <= 0;
        end
    end
end

// serial serial(
//     .CLOCK_50M(CLOCK_50M),
//     .TX(RS232_DCE_TXD),
//     .LED1(LED[3]),
//     .LED2(LED[4]),
//     .send_buffer_in(send_buffer),
//     .send_buffer_count_in(send_buffer_count),
//     .send_buffer_out(send_buffer_out),
//     .send_buffer_count_out(send_buffer_count_out)
// );

/*
 * CLOCK GENERATOR
 */
reg CLOCK_25M = FALSE;
always @(posedge CLOCK_50M) begin
    CLOCK_25M <= !CLOCK_25M;
end

/*
 * VIDEO OUTPUT
 * 800*525 = 420000
 */
reg [9:0] line_pos = 10'b0; // horizontal position
reg [9:0] pixel_pos = 10'b0; // vertical position

reg [3:0] vga_r_out;
reg [3:0] vga_g_out;
reg [3:0] vga_b_out;
reg vga_hsync_out;
reg vga_vsync_out;
assign VGA_R = vga_r_out;
assign VGA_G = vga_g_out;
assign VGA_B = vga_b_out;
assign VGA_HSYNC = vga_hsync_out;
assign VGA_VSYNC = vga_vsync_out;

reg led_state1;
reg led_state2;
assign LED[1] = led_state1;
assign LED[2] = led_state2;

reg [191:0] block = 1'b0;
reg [3:0] select_line_pos = 4'b0;
reg [3:0] select_pixel_pos = 4'b0;
always @(posedge BUTTON_EAST) begin
    if (BUTTON_EAST == TRUE) begin
        if (select_pixel_pos == 15) begin
            select_pixel_pos = 0;
            if (select_line_pos == 11) begin
                select_line_pos = 0;
            end
            else begin
                select_line_pos = select_line_pos + 1;
            end
        end
        else begin
            select_pixel_pos = select_pixel_pos + 1;
        end
    end
end

reg [3:0] color = 4'd15;
always @(posedge BUTTON_NORTH) begin
    if (BUTTON_NORTH == TRUE) begin
        color <= color + 1;
    end
end

always @(posedge CLOCK_25M) begin
    led_state1 <= !led_state1;

    // active video
    if (pixel_pos == H_ACTIVE_PIXEL || line_pos == V_ACTIVE_LINE) begin
        vga_r_out <= 4'd0;
        vga_g_out <= 4'd0;
        vga_b_out <= 4'd0;
    end
    else if (pixel_pos < H_ACTIVE_PIXEL && line_pos < V_ACTIVE_LINE) begin
        if (block[(pixel_pos/BLOCK_SIZE) + ((line_pos/BLOCK_SIZE)*16)]) begin
            vga_r_out <= 4'd15;
            vga_g_out <= 4'd0;
            vga_b_out <= 4'd0;
        end
        else begin
            vga_r_out <= color;
            vga_g_out <= color;
            vga_b_out <= color;
        end
    end

    // horizontal sync
    if (pixel_pos == H_ACTIVE_PIXEL + H_FPORCH_PIXEL) begin
        vga_hsync_out <= FALSE;
    end
    if (pixel_pos == H_ACTIVE_PIXEL + H_FPORCH_PIXEL + H_SYNC_PIXEL) begin
        vga_hsync_out <= TRUE;
    end

    // vertical sync
    if (line_pos == V_ACTIVE_LINE + V_FPORCH_LINE) begin
        vga_vsync_out <= FALSE;
    end
    if (line_pos == V_ACTIVE_LINE + V_FPORCH_LINE + V_SYNC_LINE) begin
        vga_vsync_out <= TRUE;
    end

    // counter
    pixel_pos <= pixel_pos + 1;
    if (pixel_pos == H_LIMIT_PIXEL + 1) begin
        pixel_pos <= 0;
        line_pos <= line_pos + 1;
        if (line_pos == V_LIMIT_LINE + 1) begin
            line_pos <= 0;
            led_state2 <= !led_state2;
        end
    end
end

/*
 * PLAYING
 */
// reg led_state0;
assign LED[0] = TRUE;
assign LED[3] = TRUE;
assign LED[4] = TRUE;

always @(posedge BUTTON_SOUTH) begin
end

endmodule
