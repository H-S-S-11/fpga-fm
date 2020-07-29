module frequency_counter_tb();

logic clk_200M, input_frequency, reset_n_200M, reset_n_input_freq;
logic [15:0] compare_point;
logic comparison;

assign compare_point = 200;

frequency_counter #() dut1(.*);

always begin
    #2.5ns clk_200M = ~clk_200M;
end

always begin
    #101ns input_frequency = ~input_frequency;
end

initial begin
    clk_200M = 0;
    reset_n_200M = 1;
    #5ns reset_n_200M = 0;
    #5ns reset_n_200M = 1;
end

initial begin
    input_frequency = 0;
    reset_n_input_freq = 1;
    #200ns reset_n_input_freq = 0;
    #200ns reset_n_input_freq = 1;
end


endmodule