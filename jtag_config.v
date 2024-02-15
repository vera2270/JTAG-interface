module config_jtag (
	input 	clk,
			reset,
			data_in,
	output	finished,   
	output reg strobe,
	output reg [31:0] data_out
);

	reg [47:0] data; // holds data and FAB2 or FAB3
	reg local_strobe;
	reg active;
	parameter [5:0] time_until_send = 6'b110001;
	reg [5:0] time_send;
	reg config_end;

	assign finished = config_end;

	always @(negedge reset, negedge clk) begin
		if (reset == 1'b0)
			active <= 1'b0;
		else if (config_end == 1'b0)
			active <= (data[15:0] == 16'hFAB2) ? 1'b1 : 1'b0;
	end

	always @(negedge reset, posedge clk) begin
		if (reset == 1'b0)
			config_end <= 1'b0;
		else if (config_end == 1'b0)
			config_end <= (data[15:0] == 16'hFAB3 | time_send == 0) ? 1'b1 : 1'b0; 
	end

	always @(negedge reset, posedge clk) begin
		if (reset == 1'b0)
			data <= 0;
		else if (config_end == 1'b0)
			data <= {data[46:0], data_in};
	end

	always @(negedge reset, posedge clk) begin
		if (reset == 1'b0) begin
			strobe 		<= 1'b0;
			local_strobe <= 1'b0;
			time_send 	<= time_until_send +1;
		end
		else if (config_end == 1'b0) begin
            local_strobe <= 1'b0;
            if (active == 1'b1 | time_send == 2) begin
                data_out <= data[47:16];
                local_strobe <= 1'b1;
            end else 
                local_strobe <= 1'b0;
            strobe <= local_strobe;
    
            if (active == 1'b1) 
                time_send <= time_until_send;
            else if (time_send > 0)
                time_send <= time_send -1;
		end
	end
endmodule