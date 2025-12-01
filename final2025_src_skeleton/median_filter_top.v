module median_filter_top (
    input                     clk,
    input                     resetn,

    input                     valid_in,
    output                    ready_in,

    input      [24*9-1:0]     data_in,  

    output     [23:0]         pixel_out,

    input                     ready_out,
    output                    valid_out
);




endmodule