module control_unit_fsm (
    input clk, 
    input resetn,

    input valid_in, 
    output ready_in,

    input [24*9-1:0] mux_data_in,

    output reg valid_out,
    input ready_out,

    output [8*9-1:0] blkram_read_address,


    output reg [7:0] blkram_write_address,
    output reg [8:0] blkram_write_enable,


    output reg [24*9-1:0] mux_data_out
);



endmodule