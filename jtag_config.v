module config_jtag (
	input 	clk,
			reset,
			tms,
			data_in,
	output reg resetOut,
			strobe,
	output reg [31:0] data_out
);

	reg [31:0] data = 0;
	reg [15:0] tms_sample = 0;
	reg local_strobe;
	reg active;
	parameter [5:0] time_until_send = 6'b100010;
	reg [5:0] time_send = time_until_send;

	always @(reset) begin
		if (reset == 1'b0) begin
			active <= 1'b0;
			resetOut <= 1'b1;
			data <= 32'b0;
			tms_sample <= 16'b0;
			strobe <= 1'b0;
			local_strobe <= 1'b0;
			time_send <= time_until_send;
		end
	end

	always @(negedge clk) begin
		active <= (tms_sample == 16'hFAB1) ? 1'b1 : 1'b0;
	end

	always @(posedge clk) begin
		resetOut <= (tms_sample == 16'hFAB0 | time_send == 0) ? 1'b1 : 1'b0; 

		data <= {data[30:0], data_in};
		tms_sample <= {tms_sample[14:0], tms};

		local_strobe <= 1'b0;
		if (active == 1'b1 | time_send == 2) begin
			data_out <= data;
			local_strobe <= 1'b1;
		end else 
			local_strobe <= 1'b0;
		strobe <= local_strobe;

		if (active == 1'b1) 
			time_send <= time_until_send;
		else if (time_send > 0)
			time_send <= time_send -1;
	end
endmodule