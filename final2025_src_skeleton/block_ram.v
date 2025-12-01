`timescale 1ns / 1ps

// DO NOT MODIFY BELLOW
module block_ram(
    input clk,

    input ena,
    input wea,
    input [7:0] addra,
    input [23:0] dina,
    output reg [23:0] douta,

    input enb,
    input web,
    input [7:0] addrb,
    input [23:0] dinb,
    output reg [23:0] doutb

);

    (* ram_style = "block" *)
    reg [23:0] memory [255:0];

    always @(posedge clk) begin
        if(wea)
            memory[addra] <= dina;
        else
            douta		<= ena ? memory[addra] : 24'dx;
    end


    always @(posedge clk) begin
        if(web)
            memory[addrb] <= dinb;
        else
            doutb		<= enb ? memory[addrb] : 24'dx;

    end

endmodule

