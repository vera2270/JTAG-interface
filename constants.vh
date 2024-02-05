
parameter id_data = 32'h0000_0001;

parameter len_instruction = 5;
parameter ireg_length = 3;

parameter [len_instruction-1:0] bypass = 0;
parameter [len_instruction-1:0] idcode = 5'b00001;
parameter [len_instruction-1:0] sample_preload = 5'b00010;
parameter [len_instruction-1:0] extest = 5'b00100;
parameter [len_instruction-1:0] intest = 5'b01000;
parameter [len_instruction-1:0] program = 5'b10000;

parameter [3:0] tlreset_c 	= 4'hF;
parameter [3:0] idle_c 		= 4'hC;
parameter [3:0] selectdr_c 	= 4'h7;
parameter [3:0] capturedr_c = 4'h6;
parameter [3:0] shiftdr_c 	= 4'h2;
parameter [3:0] exit1dr_c 	= 4'h1;
parameter [3:0] pausedr_c 	= 4'h3;
parameter [3:0] exit2dr_c 	= 4'h0;
parameter [3:0] updatedr_c 	= 4'h5;
parameter [3:0] selectir_c 	= 4'h4;
parameter [3:0] captureir_c = 4'hE;
parameter [3:0] shiftir_c 	= 4'hA;
parameter [3:0] exit1ir_c 	= 4'h9;
parameter [3:0] pauseir_c 	= 4'hB;
parameter [3:0] exit2ir_c 	= 4'h8;
parameter [3:0] updateir_c 	= 4'hD;
