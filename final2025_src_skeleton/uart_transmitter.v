module uart_transmitter (
    input uart_samplig_clk,
    input reset,

    output reg RsTx,

    //Basic valid & ready handshake
    input valid,
    output ready,

    input [7:0] data_to_xmit
);

    reg [1:0] state;

    reg [7:0] data_shift_register;
    reg [2:0] tx_data_count;
    
    reg [3:0] sampling_phase;

    parameter IDLE = 2'd0;
    parameter XMIT = 2'd1; 
    parameter END_XMIT = 2'd2;
    parameter STOP_BIT = 2'd3;

    assign ready = state == IDLE;
    

    always @(posedge uart_samplig_clk ) begin
        if (~reset) begin
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE : begin
                    if (valid && ready) begin
                        state <= XMIT;
                        data_shift_register <= data_to_xmit;
                        tx_data_count <= 3'd0;

                        sampling_phase <= 4'd1;

                        RsTx <= 1'd0;
                    end
                    else 
                        RsTx <= 1'd1;
                end

                XMIT : begin
                    if (sampling_phase == 4'd0) begin
                        if (tx_data_count == 3'd7) begin
                            state <= END_XMIT;
                            data_shift_register <= {1'd1,data_shift_register[7:1]};
                            RsTx <= data_shift_register[0];
                            sampling_phase <= 4'd1;
                        end
                        else begin
                            data_shift_register <= {1'd1,data_shift_register[7:1]};
                            RsTx <= data_shift_register[0];
    
                            tx_data_count <= tx_data_count + 3'd1;
                        end
                    
                    end

                    sampling_phase <= sampling_phase + 1'd1;
                    
                end
                
                END_XMIT : begin
                    if (sampling_phase == 4'd0) begin
                        state <= STOP_BIT;
                        RsTx <= 1'd1;
                    end
                    sampling_phase <= sampling_phase + 1'd1;
                end

                STOP_BIT : begin
                    if (sampling_phase == 4'd0) begin
                        state <= IDLE;
                        RsTx <= 1'd1;
                    end
                    sampling_phase <= sampling_phase + 1'd1;
                end

            endcase
        end
    end

    
endmodule