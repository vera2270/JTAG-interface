-- containing resources for configuration of a fpga 
-- https://en.wikipedia.org/wiki/Data_strobe_encoding


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity config_jtag is
	port (
		clk 		: in std_logic;
		reset		: in std_logic;
		data_in 	: in std_logic;

		finished 	: out std_logic;
		data_out 	: out std_logic_vector(31 downto 0);
		strobe		: out std_logic
	);
end entity;

architecture behaviour of config_jtag is
	signal data			: std_logic_vector(47 downto 0);
	signal local_strobe : std_logic;
	signal active		: std_logic;
	constant time_until_send	: unsigned(5 downto 0) := b"110001";
	signal time_send	: unsigned(5 downto 0) := time_until_send;
	signal config_end	: std_logic;
begin
	finished <= config_end;

	process(clk, reset)
	begin
		if (reset = '0') then
			active <= '0';
		elsif (falling_edge(clk) and config_end = '0') then
			active <= '1' when (data(15 downto 0) = x"FAB2") else '0';
		end if;
	end process;

	process(clk, reset)
	begin
		if (reset = '0') then
			config_end <= '0';
		elsif (rising_edge(clk) and config_end = '0') then
			config_end <= '1' when (data(15 downto 0) = x"FAB3" or time_send = 0) else '0';
		end if;
	end process;

	process(clk, reset)
	begin
		if (reset = '0') then
			data <= (others => '0');
		elsif (rising_edge(clk) and config_end = '0') then
			data <= data(46 downto 0) & data_in;
		end if;
	end process;

	process(clk, reset)
	begin
		if (reset = '0') then
			strobe 		<= '0';
			local_strobe <= '0';
			time_send	<= time_until_send +1;
		elsif (rising_edge(clk) and config_end = '0') then
			local_strobe <= '0';
			if (active = '1' or time_send = 2) then
				data_out <= data(47 downto 16);
				local_strobe <= '1';
			else 
				local_strobe <= '0';
			end if;
			strobe <= local_strobe;

			if (active = '1') then
				time_send <= time_until_send;
			elsif (time_send > 0) then
				time_send <= time_send - 1;
			end if;
		end if;
	end process;
end architecture;