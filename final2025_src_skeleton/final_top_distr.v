`timescale 1ns / 1ps

module final_top_distr(
    input clk,
    input btnC,

    input RsRx,
    output RsTx ,
    output Rx_pmod,
    output Tx_pmod
    
);

    assign Rx_pmod = RsRx;
    assign Tx_pmod = RsTx;
    

    wire resetn;
    assign resetn = ~btnC;


    wire uart_samplig_clk;
    clock_divider UART_CLK_GEN (clk, uart_samplig_clk);

    

    
    wire [7:0] received_data;
    wire rx_valid, rx_ready;
    uart_receiver UART_RX(
        .uart_samplig_clk ( uart_samplig_clk ),
        .reset            ( resetn            ),
        .RsRx             ( RsRx             ),
        .valid            ( rx_valid            ),
        .ready            ( rx_ready            ), 
        .received_data    ( received_data    )
    );


    wire dwc_valid_out;
    wire dwc_ready_out;
    wire [23:0] dwc_data_out;
    
    data_width_converter DWC_8_to_24 (
        .clk       ( uart_samplig_clk       ),
        .resetn    ( resetn    ),
        .data_in   ( received_data   ),
        .valid_in  ( rx_valid  ),
        .ready_in  ( rx_ready  ),
        .data_out  ( dwc_data_out  ),
        .valid_out ( dwc_valid_out ),
        .ready_out ( dwc_ready_out  )
    );




    wire [24*9-1:0] blkram_read_data;
    wire [8*9-1:0] blkram_read_address;
    wire [7:0] blkram_write_address;
    wire [8:0] blkram_write_enable;

    genvar i;
    //Array of BRAMs for line buffer
    generate
        for(i =0; i < 9; i = i +1) begin
            //Use port a to read, b to write
            block_ram LINE_BUFFERS(
                .clk   ( uart_samplig_clk   ),
                .ena   ( 1'b1  ),
                .wea   ( 1'b0   ),
                .addra ( blkram_read_address[8*i+:8] ),
                .dina  (   ),
                .douta ( blkram_read_data[24*i+:24] ),

                .enb   ( 1'b1   ),
                .web   ( blkram_write_enable[i]   ),
                .addrb ( blkram_write_address ),
                .dinb  ( dwc_data_out ),
                .doutb  (   )
            );
        end
    endgenerate



    wire [24*9-1:0] median_filter_data_in;
    wire valid_out_control;
    wire ready_out_control;

    control_unit_fsm CONTROL_fsm(
        .clk         ( uart_samplig_clk   ),
        .resetn      ( resetn      ),

        .valid_in    ( dwc_valid_out    ),
        .ready_in    ( dwc_ready_out    ),

        .mux_data_in ( blkram_read_data ),
        .valid_out   ( valid_out_control  ),
        .ready_out   ( ready_out_control  ),

        .blkram_read_address (blkram_read_address),
        .blkram_write_address (blkram_write_address),
        .blkram_write_enable (blkram_write_enable),

        .mux_data_out  ( median_filter_data_in  )
    );



    wire [23:0] data_out;
    wire data_valid;
    wire tx_ready;

    //Convolution computation
    median_filter_top MID_FILT (
        .clk       ( uart_samplig_clk       ),
        .resetn    ( resetn    ),

        .data_in   ( median_filter_data_in ),
        .ready_in  ( ready_out_control ),
        .valid_in  ( valid_out_control ),

        .pixel_out ( data_out),
        .valid_out ( data_valid ),
        .ready_out ( tx_ready )
    );




    
    uart_transmitter UART_TX(
        .uart_samplig_clk ( uart_samplig_clk ),
        .reset            ( resetn            ),
        .RsTx             ( RsTx             ),
        .valid            ( data_valid  ),
        .ready            ( tx_ready            ),
        .data_to_xmit     ( data_out[15:8]  )
    );


endmodule
