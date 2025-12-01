module uart_receiver (
    input uart_samplig_clk,
    input reset,

    input RsRx,

    //Basic valid & ready handshake
    output valid,
    input ready,

    output reg [7:0] received_data
);

    reg [2:0] data_count;


    reg [3:0] sampling_phase_counter;
    reg [3:0] sampling_phase;

    reg [1:0] state;

    parameter IDLE = 2'd0;
    parameter RECEIVE = 2'd1;
    parameter WAIT_FOR_END = 2'd2;
    parameter WAIT = 2'd3;

    assign valid = state == WAIT;

    

    always @(posedge uart_samplig_clk ) begin
        if (~reset) begin
            sampling_phase_counter <= 4'd0;
        end
        else begin
            sampling_phase_counter <= sampling_phase_counter + 4'd1;
        end
    end

    
    always @(posedge uart_samplig_clk ) begin
        if (~reset) begin
            data_count <= 4'd0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE : begin
                    //Start bit detected
                    if (RsRx == 1'd0) begin
                        sampling_phase <= sampling_phase_counter;
                        state <= RECEIVE;
                        data_count <= 4'd0; 
                    end
                    else begin
                        state <= IDLE;
                    end
                end

                RECEIVE : begin
                    if (sampling_phase == sampling_phase_counter) begin
                        if (data_count != 3'd7) begin
                            data_count <= data_count + 1'd1; 
                            received_data <= {RsRx, received_data[7:1]};
                        end
                        //Finished receiving
                        else begin
                            received_data <= {RsRx, received_data[7:1]};
                            state <= WAIT_FOR_END;
                        end
                    end
                end
                
                WAIT_FOR_END : begin
                    if (sampling_phase == sampling_phase_counter) begin
                        if(RsRx == 1'b1)
                            state <= WAIT;
                    end
                end

                WAIT : begin
                    if (valid && ready) begin
                        state <= IDLE;
                    end
                end

            endcase

        end
    end
    
endmodule