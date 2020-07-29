module frequency_counter #(
    parameter OUTPUT_BITS=1,
    parameter INPUT_PERIODS=5,
    parameter NUM_FREQUENCIES=(2**OUTPUT_BITS)
)(
    input logic clk_200M, input_frequency, reset_n_200M, reset_n_input_freq,
    input logic [15:0] compare_point,
    output logic [OUTPUT_BITS-1:0] comparison
);
        
//input frequency should be around 5MHz.
//One period at this frequency is approximately 40 periods at 200MHz
//Or 20 periods at 100MHz (higher reference clock should give more accurate results)

//By waiting five periods of the input frequency with a reference clock timer running,
//the input frequency can be sampled at 1MSPS. If the large timer is greater than 200,
//then input frequency is less than 5MHz. If it is less than 200, input frequency is greater than 5MHz.
//Lower reference clock eg 100MHz means it is necessary to wait longer to get a sample.

//This example (large timer counting to 200) is designed for a transmission at 5MHz with 0.05 (1%) modulation
//Greater modulation would allow for faster sampling


//Fast clock domain
logic [15:0] large_counter, last_sample;
logic restart_sample; 
logic [2:0] run_large_counter_sync;

//Slow clock domain
logic [7:0] small_counter;
logic run_large_counter;

//Slow clock domain ---------------------------------------

always_ff @(posedge input_frequency, negedge reset_n_input_freq) begin
    if (~reset_n_input_freq) begin
        small_counter <= 0;
    end else begin
        if (small_counter == INPUT_PERIODS) begin
            small_counter <= 0;
        end else begin
            small_counter <= small_counter + 1;
        end
    end
end

assign run_large_counter = (small_counter != 0);

//--------------------------------------------------------


//Fast clock domain -------------------------------------

always_ff @(posedge clk_200M, negedge reset_n_input_freq) begin
    if (~reset_n_200M) begin
        large_counter <= 0;
        last_sample <= 0;
        run_large_counter_sync <= 3'b000;
    end else begin
        run_large_counter_sync <= {run_large_counter, run_large_counter_sync[2:1]};
        if (restart_sample) begin
            last_sample <= large_counter + 1; //This compensates for the last period not being counted
            large_counter <= 0;
        end else begin
            large_counter <= large_counter + 1;
        end
    end    
end

assign restart_sample = (run_large_counter_sync[1] & ~run_large_counter_sync[0]);

assign comparison = ~(last_sample >= compare_point); //High means input is above the middle frequency

//----------------------------------------------------

endmodule