module clock_divider (
    input clk,
    output slow_clock
);
    //This module converts 100MHz Clock on Basys3 board
    //to slower 1,843,200Hz clock for UART communication
    reg [25:0] counter = 26'd0;
    reg slow_clk_reg = 1'b0;

    //Note that "assign" can only be applied to "wire" data types. 
    assign slow_clock = slow_clk_reg;

    always @(posedge clk ) begin
            //Use this at Synthesis / Implementation
            //if (counter == 27'd49_999_999) begin

            //Use this at simulation
            if (counter == 27'd27) begin
                counter <= 26'd0;
                slow_clk_reg <= ~slow_clk_reg;
            end 
            else begin
                counter <= counter + 1'd1;
            end

    end
    
endmodule