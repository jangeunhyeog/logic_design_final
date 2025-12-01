`timescale 1ns / 1ps

module tb_final();

    parameter WIDTH=64;
    parameter HEIGHT=64;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg [15:0] resetn_count = 16'd0;
    reg [23:0] input_img;

    wire valid;


    //Internal signals...
    reg [15:0] row_count;
    reg [15:0] col_count;

    integer fd, fo;
    integer file_ret;
    integer fo_idx;

    initial begin
        fd = $fopen("noisy_cat.bin", "rb");
        fo = $fopen("noisy_cat.bin.out", "wb");
    end

    //Clock generation
    always begin
        #5 clk = ~clk;
    end

    //reset for 10 clock cycles
    always @(posedge clk) begin
        if(resetn_count < 16'd10)
            resetn_count = resetn_count + 1;
        else begin
            resetn = 1'b1;
        end
    end

    // Modules
    // ------------------------------------------------------------
    reg rx_valid;
    wire rx_ready;
    reg [7:0] received_data;


    wire dwc_valid_out;
    wire dwc_ready_out;
    wire [23:0] dwc_data_out;
    
    data_width_converter DWC_8_to_24 (
        .clk       ( clk       ),
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
                .clk   ( clk   ),
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
        .clk         ( clk   ),
        .resetn      ( resetn      ),
        .valid_in    ( dwc_valid_out    ),
        .ready_in    ( dwc_ready_out    ),

        .mux_data_in ( blkram_read_data ),
        .valid_out   ( valid_out_control   ),
        .ready_out   ( ready_out_control ),

        .blkram_read_address (blkram_read_address),
        .blkram_write_address (blkram_write_address),
        .blkram_write_enable (blkram_write_enable),

        .mux_data_out  ( median_filter_data_in  )
    );




    wire [23:0] data_out;
    wire data_valid;
    wire data_ready;
    assign data_ready = 1'b1;

    //Convolution computation
    median_filter_top MID_FILT (
        .clk       ( clk       ),
        .resetn    ( resetn    ),

        .data_in   ( median_filter_data_in ),

        .ready_in  ( ready_out_control ),
        .valid_in  ( valid_out_control ),

        .pixel_out ( data_out),

        .ready_out ( data_ready  ),
        .valid_out ( data_valid  )
    );

    // ------------------------------------------------------------

    initial begin
        
    end

    reg [1:0] byte_sent;
    integer total_count;
    
    always @(*) begin
        case (byte_sent)
            2'd0: received_data = input_img[23:16];
            2'd1: received_data = input_img[15:8];
            2'd2: received_data = input_img[7:0];
            default: received_data = 8'dx;
        endcase
    end


    //Feed our image data to module with VGA format
    initial begin
        total_count = 0;
        byte_sent = 0;
        rx_valid = 0;
        #102;
        total_count = 0;
        byte_sent = 0;
        rx_valid = 1;
        file_ret = $fread(input_img, fd);
        forever begin
            if(~resetn) begin
                total_count = 0;
                byte_sent = 0;
                rx_valid = 1;
                //file_ret = $fread(input_img, fd);
            end
            else begin
                if (rx_valid && rx_ready) begin
                    if (byte_sent == 2'd2) begin
                        if (total_count == WIDTH*HEIGHT-1) begin
                            //END OF IMAGE!
                            rx_valid = 0;
                        end
                        else begin
                            total_count = total_count + 1;
                            byte_sent = 0;
                            file_ret = $fread(input_img, fd);
                        end
                        
                    end
                    else begin
                        byte_sent = byte_sent +1;
                    end
                end
            end
                
            #10;
        end
    end
   
    reg [23:0] output_img_save;
    reg valid_save;
    reg valid_delay;
    always @(*) begin
        valid_delay = #3 data_valid;
    end

    //Save Image to file
    always @(posedge clk ) begin
        if (~resetn) begin
            fo_idx <= 0;
        end
        else begin
            if(fo_idx == WIDTH*HEIGHT) begin
                $fclose(fd);
                $fclose(fo);
                #100;
                $stop;   //End of one image!!
            end

            if (valid_delay) begin
                //Write module outputs
                fo_idx <= fo_idx + 1;
                
                
                $fwrite(fo,"%c", data_out[23:16]);
                $fwrite(fo,"%c", data_out[15:8]);
                $fwrite(fo,"%c", data_out[7:0]);
            end
        end
        
    end

endmodule
