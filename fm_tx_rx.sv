//Use input of: 433791697 for 5.05MHz from NCO
//              425201762 for 4.95MHz from NCO
//              429496730 for 5MHz
//              858993459 for 10MHz

`default_nettype none

module fm_tx_rx(
    input logic clk_50M_i, reset_n,
	input logic [1:0] demod_i, 
    output logic locked_o, intermediate_frequency_o, fm_o, clk_rf_o,
    output logic in_phase_95M_o, quad_phase_95M_o, demod_o
);

logic [9:0] nco_o;
logic [31:0] nco_freq_input;
logic p_reset, nco_valid;
logic audio_square;

logic clk_95M;
logic [1:0] pll_locks;
assign intermediate_frequency_o = clk_95M;
assign clk_rf_o = clk_95M;
assign p_reset = ~reset_n;
assign fm_o = nco_o[9];
assign locked_o = &pll_locks;

assign demod_o = received_fm;

assign nco_freq_input = audio_square ? 425201762 : 433791697;

fm_5M fm_gen (
	.clk       (clk_50M_i),       // clk.clk
	.reset_n   (reset_n),   // rst.reset_n
	.clken     (1),     //  in.clken
	.phi_inc_i (nco_freq_input), //    .phi_inc_i
	.fsin_o    (nco_o),    // out.fsin_o
	.out_valid (nco_valid)  //    .out_valid
);





medium_multi_pll	pll_95M (
	.areset ( p_reset ),
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
    .n_reset(reset_n),
    .value(audio_square)
);

//-----------------------RX--------------------------


pll_95M_dual_phase	pll_95M_dual_phase_inst (
	.areset ( p_reset ),
	.inclk0 ( clk_50M_i ),
	.c0 ( in_phase_95M_o ),
	.c1 ( quad_phase_95M_o ),
	.locked ( pll_locks[1] )
	);

//c0: in phase
//c1: quadrature (90 degree phase shift)

logic received_fm;

io_buffer	lvds_clkin (
	.datain ( demod_i[0] ),
	.datain_b ( demod_i[1] ),
	.dataout ( received_fm )
);


frequency_counter freq_count1 (
	.clk_200M(),
	.input_frequency(),
	.reset_n_200M(),
	.reset_n_input_freq(),
	.compare_point_i(),
	.last_sample_o(),
	.comparison_o()
)


 //-----------------------RX--------------------------

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