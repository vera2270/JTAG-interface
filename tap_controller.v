
module tap_controller (
	input 	clk,
			tms,
			tap_por,
			enableIn,
	output reg [3:0] tstate,
	output reg	enable,
			reset,
			tselect,
			captureIR,
			shiftIR,
			captureDR,
			shiftDR,
			clkIR,
			clkDR,
	output	updateIR,
			updateDR	
);
	`include "constants.vh"

	// States
	localparam tlreset 	= 4'd0;
	localparam idle 	= 4'd1;
	localparam seldr 	= 4'd2;
	localparam capdr 	= 4'd3;
	localparam shdr 	= 4'd4;
	localparam ex1dr 	= 4'd5;
	localparam pdr 		= 4'd6;
	localparam ex2dr 	= 4'd7;
	localparam updr 	= 4'd8;
	localparam selir 	= 4'd9;
	localparam capir	= 4'd10;
	localparam shir 	= 4'd11;
	localparam ex1ir 	= 4'd12;
	localparam pir 		= 4'd13;
	localparam ex2ir 	= 4'd14;
	localparam upir 	= 4'd15;

	reg [3:0] state_current; 
	reg [3:0] state_next;

	initial begin
		tstate = tlreset;
	end

	always @(tms, state_current) begin
		if (enableIn) begin
			if (tms == 1'b0) begin
				case (state_current)
					tlreset : state_next <= idle; 
					idle 	: state_next <= idle; 
					seldr 	: state_next <= capdr; 
					capdr 	: state_next <= shdr; 
					shdr 	: state_next <= shdr; 
					ex1dr 	: state_next <= pdr; 
					pdr 	: state_next <= pdr;
					ex2dr 	: state_next <= shdr;
					updr 	: state_next <= idle;
					selir 	: state_next <= capir; 
					capir	: state_next <= shir; 
					shir 	: state_next <= shir; 
					ex1ir 	: state_next <= pir; 
					pir 	: state_next <= pir;
					ex2ir 	: state_next <= shir;
					upir 	: state_next <= idle;
					default : state_next <= tlreset;
				endcase
			end else if (tms == 1'b1) begin
				case (state_current)
					tlreset : state_next <= tlreset; 
					idle 	: state_next <= seldr; 
					seldr 	: state_next <= selir; 
					capdr 	: state_next <= ex1dr; 
					shdr 	: state_next <= ex1dr; 
					ex1dr 	: state_next <= updr; 
					pdr 	: state_next <= ex2dr;
					ex2dr 	: state_next <= updr;
					updr 	: state_next <= seldr;
					selir 	: state_next <= tlreset; 
					capir	: state_next <= ex1ir; 
					shir 	: state_next <= ex1ir; 
					ex1ir 	: state_next <= upir; 
					pir 	: state_next <= ex2ir;
					ex2ir 	: state_next <= upir;
					upir 	: state_next <= seldr;
					default : state_next <= tlreset;
				endcase
			end else 
				state_next <= state_current;
		end
	end

	always @(state_current) begin
		if (enableIn) begin
			case (state_current)
				tlreset : tstate <= tlreset_c;
				idle 	: tstate <= idle_c;
				seldr 	: tstate <= selectdr_c;
				capdr 	: tstate <= capturedr_c;
				shdr 	: tstate <= shiftdr_c;
				ex1dr 	: tstate <= exit1dr_c;
				pdr 	: tstate <= pausedr_c;
				ex2dr 	: tstate <= exit2dr_c;
				updr 	: tstate <= updatedr_c;
				selir 	: tstate <= selectir_c;
				capir	: tstate <= captureir_c;
				shir 	: tstate <= shiftir_c;
				ex1ir 	: tstate <= exit1ir_c;
				pir 	: tstate <= pauseir_c;
				ex2ir 	: tstate <= exit2ir_c;
				upir 	: tstate <= updateir_c;
				default : tstate <= tlreset_c;
			endcase
		end
	end

	assign updateIR = (state_current == upir & clk == 1'b0) ? 1'b1 : 1'b0;
	assign updateDR = (state_current == updr & clk == 1'b0) ? 1'b1 : 1'b0;

	always @(posedge clk) begin
		if (enableIn) begin
			// global reset
			if (tap_por == 1'b0)
				state_current <= tlreset;
			else
				state_current <= state_next;
		end
	end

	always @(negedge clk) begin
		if (enableIn == 1'b1) begin
			case (state_current)
				capir : {captureIR, shiftIR, captureDR, shiftDR} <= 4'b1000;
				shir : {captureIR, shiftIR, captureDR, shiftDR} <= 4'b0100;
				capdr : {captureIR, shiftIR, captureDR, shiftDR} <= 4'b0010;
				shdr : {captureIR, shiftIR, captureDR, shiftDR} <= 4'b0001;
				default: {captureIR, shiftIR, captureDR, shiftDR} <= 4'b0000;
			endcase

			if (state_current == shir | state_current == shdr) 
				enable <= 1'b1;
			else
				enable <= 1'b0;
		end
	end

	always @(clk) begin
		if (enableIn == 1'b1) begin
			if (state_current == tlreset)
				reset <= 1'b0;
			else
				reset <= 1'b1;

			if (tstate[3] == 1'b1)
				tselect <= 1'b1;
			else 
				tselect <= 1'b0;

			if (state_current == shir | state_current == capir)
				clkIR <= clk;
			else
				clkIR <= 1'b1;

			if (state_current == shdr | state_current == capdr)
				clkDR <= clk;
			else
				clkDR <= 1'b1;
		end
	end
endmodule