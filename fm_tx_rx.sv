//Use input of: 433791697 for 5.05MHz from NCO
//              425201762 for 4.95MHz from NCO
//              429496730 for 5MHz
//              858993459 for 10MHz

`default_nettype none

module fm_tx_rx(
    input logic clk_50M_i, reset_n_i,
	input logic [1:0] demod_i, 
	input logic [1:0]  freq_select_i,
	input logic freq_sample_bit_select_i,
	output logic comparison_o, output logic [5:0] freq_sample_o,
    output logic locked_o, intermediate_frequency_o, fm_o, clk_rf_o,
    output logic in_phase_95M_o, quad_phase_95M_o, demod_o
);

logic [9:0] nco_o;
logic [31:0] nco_freq_input;
logic async_p_reset, nco_valid, sync_reset_n_50M;
logic audio_square;

logic clk_95M;
logic [2:0] pll_locks;


reset_sync #(
	.INPUT_POLARITY(0),
	.OUTPUT_POLARITY(0))
reset_50M (
	.async_reset_i(reset_n_i),
	.clk(clk_50M_i),
	.sync_reset_o(sync_reset_n_50M)
);

fm_5M fm_gen (
	.clk       (clk_50M_i),       // clk.clk
	.reset_n   (sync_reset_n_50M),   // rst.reset_n
	.clken     (1),     //  in.clken
	.phi_inc_i (nco_freq_input), //    .phi_inc_i
	.fsin_o    (nco_o),    // out.fsin_o
	.out_valid (nco_valid)  //    .out_valid
);

medium_multi_pll	pll_95M (
	.areset ( async_p_reset ),
	.inclk0 ( clk_50M_i ),
	.c0 ( clk_95M ),
	.locked ( pll_locks[0] )
);

//16 division bits for about 400Hz with 50MHz clock
counternbit #(
    .OUTPUTWIDTH(1),
    .DIVISIONBITS(16))
count1(
    .clk(clk_50M_i),
    .n_reset(sync_reset_n_50M),
    .value(audio_square)
);

//The carrier is sent to two output pins for flexibility
assign intermediate_frequency_o = clk_95M;
assign clk_rf_o = clk_95M;

assign async_p_reset = ~reset_n_i;
assign fm_o = nco_o[9];	//The ~5MHz square wave
assign locked_o = &pll_locks;


//the actual frequency modulation
//assign nco_freq_input = audio_square ? 425201762 : 433791697;

always_comb begin
	if (freq_select_i[1]) begin
		nco_freq_input = freq_select_i[0] ? 425201762 : 433791697;
	end else begin
		nco_freq_input = audio_square ? 425201762 : 433791697;
	end
end


//-----------------------RX--------------------------


pll_95M_dual_phase	pll_95M_dual_phase_inst (
	.areset ( async_p_reset ),
	.inclk0 ( clk_50M_i ),
	.c0 ( in_phase_95M_o ),
	.c1 ( quad_phase_95M_o ),
	.locked ( pll_locks[1] )
	);

//c0: in phase
//c1: quadrature (90 degree phase shift)

logic received_fm;

assign demod_o = received_fm;

io_buffer	lvds_clkin (
	.datain ( demod_i[0] ),
	.datain_b ( demod_i[1] ),
	.dataout ( received_fm )
);

logic clk_200M, sync_reset_n_200M, sync_reset_n_rx_fm;

pll_200M	pll_200M_inst (
	.areset ( async_p_reset ),
	.inclk0 ( clk_50M_i ),
	.c0 ( clk_200M ),
	.locked ( pll_locks[2] )
);

logic [15:0] freq_sample;

frequency_counter freq_count1 (
	.clk_200M(clk_200M),
	.input_frequency(received_fm),
	.reset_n_200M(sync_reset_n_200M),
	.reset_n_input_freq(sync_reset_n_rx_fm),
	.compare_point_i(200),
	.last_sample_o(freq_sample), //A debug output
	.comparison_o(comparison_o)
);

assign freq_sample_o = freq_sample_bit_select_i ? freq_sample[5:0] : freq_sample[11:6];

reset_sync #(
	.INPUT_POLARITY(0),
	.OUTPUT_POLARITY(0))
reset_200M (
	.async_reset_i(reset_n_i),
	.clk(clk_200M),
	.sync_reset_o(sync_reset_n_200M)
);

reset_sync #(
	.INPUT_POLARITY(0),
	.OUTPUT_POLARITY(0))
reset_received_rf (
	.async_reset_i(reset_n_i),
	.clk(received_fm),
	.sync_reset_o(sync_reset_n_rx_fm)
);


 //-----------------------End RX--------------------------

/* Multiband PLL clocks in order
 * multi_pll:
 * 29.25MHz (up/down by up to 0.25MHz)
 * 51.5MHz (up by 0.5, down by 1MHz)

 * 95MHz (up/down by up to 5MHz) LOW POWER <50nW (commercial FM)
 * 145MHz (up/down by 1MHz  except for 144.4-144.49MHz) (ISS at 145.8MHz)
 * 435 MHz

 experiment range:
 * 434MHz (up by 6MHz, down by 4MHz except for 432.4-432.49MHz) (433.8-434.25MHz designated for "experiments")
*/



    
endmodule