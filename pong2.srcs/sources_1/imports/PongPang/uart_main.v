`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2021 09:00:47 PM
// Design Name: 
// Module Name: uart_main
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


module system(
//    input PS2Data,
//    input PS2Clk,
    input clk,
    input reset,
    output RsTx,
    input RsRx,
	output[11:0] rgb,
	output vsync, hsync,
	output dp,
    output[6:0] seg,
    output[3:0] an
);
    
    wire baud;
    wire received, sent;
    wire [7:0] data_receive;
    reg [7:0] data_send;
    reg en;
    reg[3:0] key;
     
    initial begin
        key <= 4'b1111;
    end
    
    baudrate_gen baudgen(baud, clk);
    transmitter t(RsTx, sent, data_send, en, baud);
    receiver r(data_receive, received, RsRx, baud);
//    keyboard_top kt(clk,PS2Data,PS2Clk,RsTx);
    pong_top pt(clk,reset,key,rgb,vsync,hsync,dp,seg,an);

    initial begin
        en <= 1;
    end

//    reg oldre;

    always @(posedge baud) begin
        if(en == 1) en <= 0;
        if(received) begin
            case (data_receive)
            //P1
                119 : key = 4'b1110; // W
                115 : key = 4'b1101; // S
            //P2
                38 : key = 4'b1011; // up arrow
                40 : key = 4'b0111; // down arrow
                default : key = 4'b1111;
            endcase
            data_send <= data_receive;
            en <= 1;
        end
        else key <= 4'b1111;
//        oldre <= received;
    end

endmodule
