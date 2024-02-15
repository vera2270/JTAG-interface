
module tap #(
	parameter bsregInLen = 4,
	parameter bsregOutLen = 4
) (
	input 	tck,
			tms,
			tdi,
	input   trst,
	output	tdo,
	input [bsregInLen-1:0] pins_in,
	output [bsregOutLen-1:0] pins_out,
	input [bsregOutLen-1:0] logic_pins_out,
	output [bsregInLen-1:0] logic_pins_in,
	output 	active,
			config_strobe,
	output [31:0] config_data
);
	`include "constants.vh"

	wire [3:0] tstate;
	wire reset, tselect, enable, clkIR, captureIR, shiftIR, updateIR, clkDR, captureDR, shiftDR, updateDR;

	wire [ireg_length-1:0] IRdata_pin;
	wire [len_instruction-1:0] IRout;
	wire IRtdi;
	wire ir_tdo_mux;

	wire shiftBSR, updateBSR, BSRIntdo;
	wire bsrInEnableIn, bsrInEnableOut, bsrInMode, BSRIntdi;
	wire [bsregInLen-1:0] BSRIndataPin;
	wire bsrOutEnableIn, bsrOutEnableOut, bsrOutMode;
	wire BSROuttdi, BSROuttdo;
	wire [bsregOutLen-1:0] BSROutdataPout;

	wire shiftBP, captureBP, BPdataOut;
	wire BPdataIn;
	wire shiftID, idOut;
	wire drTdoMux;

	wire clkConfig, dataInConfig, configFinished, strobeConfig, jtagActive;
	reg resetConfig;
	wire [31:0] dataOutConfig;


	tap_controller tap_controller_I (
		.clk (tck),
		.tms (tms),
		.trst (trst),
		.tstate (tstate),
		.reset (reset),
		.tselect (tselect),
		.enable (enable),
		.clkIR (clkIR),
		.captureIR (captureIR),
		.shiftIR (shiftIR),
		.updateIR (updateIR),
		.clkDR (clkDR),
		.captureDR (captureDR),
		.shiftDR (shiftDR),
		.updateDR (updateDR)
	);

	assign IRdata_pin[ireg_length-1:1] = 0;
	assign IRdata_pin[0] = 1'b1;
	instruction_register #(.reg_len(ireg_length), .instr_num(len_instruction)) ir_I (
		.clkIR (clkIR),
		.upIR (updateIR),
		.shIR (shiftIR),
		.piData (IRdata_pin),
		.tdi (IRtdi),
		.reset (reset),
		.instrB (IRout),
		.tdo_mux (ir_tdo_mux),
		.state (tstate)
	);

	bsreg #(.len (bsregInLen)) bsr_in (
		.tck (tck),
		.reset (reset),
		.enableIn (bsrInEnableIn),
		.enableOut (bsrInEnableOut),
		.mode (bsrInMode),
		.clkDR (clkDR),
		.shiftDR (shiftBSR),
		.updateDR (updateBSR),
		.data_pin (pins_in),
		.tdi (BSRIntdi),
		.tdo (BSRIntdo),
		.data_pout (logic_pins_in)
	);

	bsreg #(.len (bsregOutLen)) bsr_out (
		.tck (tck),
		.reset (reset),
		.enableIn (bsrOutEnableIn),
		.enableOut (bsrOutEnableOut),
		.mode (bsrOutMode),
		.clkDR (clkDR),
		.shiftDR (shiftBSR),
		.updateDR (updateBSR),
		.data_pin (logic_pins_out),
		.tdi (BSRIntdo),
		.tdo (BSROuttdo),
		.data_pout (pins_out)
	);

	reg_bypass reg_bypass_I (
		.data_in (BPdataIn),
		.shiftDR (shiftBP),
		.clkDR (clkDR),
		.data_out (BPdataOut)
	);

	reg_id reg_id_I (
		.clkDR (clkDR),
		.shiftDR (shiftID),
		.data_out (idOut)
	);

	assign active = jtagActive;
	assign config_data = dataOutConfig;
	assign config_strobe = strobeConfig;
	config_jtag config_I (
		.clk (clkConfig),
		.reset (resetConfig),
		.data_in (dataInConfig),
		.finished (configFinished),
		.data_out (dataOutConfig),
		.strobe (strobeConfig)
	);

	assign shiftBSR 	= (IRout == sample_preload | IRout == extest | IRout == intest) ? shiftDR : 1'b1;
	assign updateBSR 	= (IRout == sample_preload | IRout == extest | IRout == intest) ? updateDR : 1'b1;

	assign shiftBP 		= (IRout == bypass) ? shiftDR : 1'b1;
	assign captureBP 	= (IRout == bypass) ? captureDR : 1'b1;

	assign shiftID 		= (IRout == idcode) ? shiftDR : 1'b1;

	assign jtagActive 	= (configFinished == 1'b0 & tstate == idle_c & IRout == program) ? 1'b1 : 1'b0;
	assign clkConfig 	= (IRout == program & tstate == idle_c) ? tck : 1'b1;
	assign dataInConfig = (IRout == program) ? tdi : 1'b1;
	
	always @(tstate, trst) begin
		if (~trst | tstate == selectdr_c)
			resetConfig <= 1'b0;
	    else
			resetConfig <= 1'b1;
	end

	// tdo mux
	assign tdo = (enable == 1'b1 & tselect == 1'b1) ? ir_tdo_mux : 
					(enable == 1'b1 & tselect == 1'b0) ? drTdoMux : 1'b0;

	assign IRtdi = (tselect == 1'b1) ? tdi : 1'b0;

	assign BPdataIn = (tselect == 1'b0 & IRout == bypass) ? tdi : 1'b0;
	assign BSRIntdi = (tselect == 1'b0 & (IRout == sample_preload | IRout == extest | IRout == intest)) ? tdi : 1'b0;

	assign drTdoMux = (tselect == 1'b0 & IRout == bypass) ? BPdataOut : 
						(tselect == 1'b0 & IRout == idcode) ? idOut :
						(tselect == 1'b0 & (IRout == sample_preload | IRout == extest | IRout == intest)) ? BSROuttdo : 1'b0;

	assign bsrInMode = (tselect == 1'b0 & (IRout == bypass | IRout == idcode | IRout == sample_preload)) ? 1'b0 : 
						(tselect == 1'b0 & (IRout == extest | IRout == intest)) ? 1'b1 : 1'b0;
	
	assign bsrOutMode = (tselect == 1'b0 & (IRout == bypass | IRout == idcode | IRout == sample_preload)) ? 1'b0 : 
						(tselect == 1'b0 & (IRout == extest | IRout == intest)) ? 1'b1 : 1'b0;

	assign bsrInEnableIn = (tselect == 1'b0 & (IRout == bypass | IRout == idcode | IRout == sample_preload | IRout == extest)) ? 1'b1 : 
							(tselect == 1'b0 & IRout == intest) ? 1'b0 : 1'b1;

	assign bsrInEnableOut = (tselect == 1'b0 & (IRout == bypass | IRout == idcode | IRout == sample_preload | IRout == intest)) ? 1'b1 : 
							(tselect == 1'b0 & IRout == extest) ? 1'b0 : 1'b1;

	assign bsrOutEnableIn = (tselect == 1'b0 & (IRout == bypass | IRout == idcode | IRout == sample_preload | IRout == intest)) ? 1'b1 : 
							(tselect == 1'b0 & IRout == extest) ? 1'b0 : 1'b1;

	assign bsrOutEnableOut = (tselect == 1'b0 & (IRout == bypass | IRout == idcode | IRout == sample_preload | IRout == extest | IRout == intest)) ? 1'b1 : 1'b1;

endmodule