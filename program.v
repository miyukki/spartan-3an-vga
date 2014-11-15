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
    parameter V_LIMIT_LINE   = V_ACTIVE_LINE + V_FPORCH_LINE + V_SYNC_LINE + V_BPORCH_LINE
)(
    input CLOCK_50M,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HSYNC,
    output VGA_VSYNC,

    input ROT_A,
    // input ROT_B,

    input BUTTON_NORTH,
    // input BUTTON_WEST,
    // input BUTTON_EAST,
    input BUTTON_SOUTH,
    output [4:0] LED
);

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
assign LED[3] = vga_hsync_out;
assign LED[4] = vga_vsync_out;

reg led_state1;
reg led_state2;
assign LED[1] = led_state1;
assign LED[2] = led_state2;

reg [3:0] color = 4'd15;
always @(posedge BUTTON_NORTH or posedge BUTTON_SOUTH) begin
    if (BUTTON_NORTH == TRUE) begin
        color <= color + 1;
    end
    else if (BUTTON_SOUTH == TRUE) begin
        color <= color - 1;
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
    else if (pixel_pos == 0) begin
        vga_r_out <= color;
        vga_g_out <= color;
        vga_b_out <= color;
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
reg led_state0;
assign LED[0] = led_state0;

always @(posedge ROT_A) begin
    led_state0 <= !led_state0;
end

endmodule
