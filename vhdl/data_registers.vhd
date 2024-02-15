
library IEEE;
use IEEE.STD_LOGIC_1164.all;


entity reg_bypass is
	port (
		data_in 	: in std_logic;
		shiftDR		: in std_logic;
		clkDR		: in std_logic;
		data_out	: out std_logic
	);
end entity;

architecture behaviour of reg_bypass is
	signal s1	: std_logic;
begin
	s1 <= data_in and shiftDR;

	shift : process(clkDR)
	begin
		if rising_edge(clkDR) then
			data_out <= s1;
		end if;
	end process;
end architecture;


-- included again due to "no declaration for std_logic" error
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity id_cell is
    port (
        clkDR         	: in std_logic;
		shiftDR			: in std_logic;
        id_code_bit 	: in std_logic;
		prevCell		: in std_logic;
		nextCell		: out std_logic
    );
end entity;

architecture behaviour of id_cell is
	signal s1		: std_logic;
begin
	s1 <= id_code_bit when (shiftDR = '0') else prevCell;

	ff_id : process(clkDR)
	begin
		if rising_edge(clkDR) then
			nextCell <= s1;
		end if;
	end process;
end architecture;

-- included again due to "no declaration for std_logic" error
library IEEE;
use IEEE.STD_LOGIC_1164.all;
library work;
use work.jtag_constants.all;

-- MSB											   LSB
--  31	   28 27         12 11                    1  0
-- | version | part number | manufacturer identity | 1 |
--   4 bits      16 bits           11 bits

entity reg_id is
    port (
        clkDR       : in std_logic;
		shiftDR		: in std_logic;
        data_out    : out std_logic
    );
end entity;

architecture behaviour of reg_id is
	signal data			: std_logic_vector(32 downto 0);
begin
	data(32) <= '0';
	data_out <= data(0);

	gen_id_cells : for i in 0 to 31 generate
		idreg_cell : entity work.id_cell(behaviour) port map (
			clkDR		=> clkDR,
			shiftDR		=> shiftDR,
			id_code_bit	=> id_data(i),
			prevCell	=> data(i+1),
			nextCell 	=> data(i)
		);
	end generate;
end architecture;


-- included again due to "no declaration for std_logic" error
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity bsr_cell is -- BC_1 with reset and enable
	port (
		reset 		: in std_logic; -- active low
		enableIn	: in std_logic; -- '1' means enabled
		enableOut	: in std_logic; -- '1' means enabled
		mode 		: in std_logic; -- controlled according to the type of pin (input, output, etc.) and the specific instruction
		clkDR		: in std_logic;
		shiftDR		: in std_logic; -- select between serial (1) and parallel (0) input
		updateDR	: in std_logic;
		data_pin 	: in std_logic;
		prevCell	: in std_logic; -- serial input
		nextCell	: out std_logic; -- serial output
		data_pout	: out std_logic
	);
end entity;

architecture behaviour of bsr_cell is -- latched parallel output
	signal s1, s2, s3 : std_logic;
begin
	nextCell <= s2 when (reset = '1') else '0';
	
	-- select input for shift register stage
	s1 <= data_pin when (shiftDR = '0' and enableIn = '1') else prevCell;

	-- select input for parallel output
	data_pout 	<= 	data_pin when (mode = '0' and enableOut = '1') else
					s3 when (mode = '1' and enableOut = '1') else 'Z';

	serial : process(clkDR, reset)
	begin
		if falling_edge(reset) then
			s2 <= '0';
		elsif falling_edge(clkDR) then
			s2 <= s1;
		end if;
	end process;
	
	parallel : process(updateDR, reset)
	begin
		if falling_edge(reset) then
			s3 <= '0';
		elsif rising_edge(updateDR) then
			s3 <= s2;
		end if;
	end process;
end architecture;


-- included again due to "no declaration for std_logic" error
-- library IEEE;
-- use IEEE.STD_LOGIC_1164.all;

-- entity bsr_cell_io is -- BC_2 control and BC_7 data for bidirectional pin
-- 	port (
-- 		output_en	: in std_logic;
-- 		output_data	: in std_logic; -- from system logic
-- 		prev_cell	: in std_logic;
-- 		mode_2		: in std_logic;
-- 		mode_5		: in std_logic;
-- 		mode_6 		: in std_logic;
-- 		shiftDR		: in std_logic;
-- 		clockDR		: in std_logic;
-- 		updateDR	: in std_logic;

-- 		input_data	: out std_logic; -- to system logic
-- 		next_cell	: out std_logic;
-- 		system_pin	: inout std_logic
-- 	);
-- end entity;

-- architecture behaviour of bsr_cell_io is
-- 	signal c_en1		: std_logic;
-- 	signal c_en2		: std_logic;
-- 	signal c_en 		: std_logic;
-- 	signal c_in			: std_logic;
-- 	signal c_next_Cell	: std_logic;

-- 	signal d_out		: std_logic;
-- 	signal d_out2		: std_logic;
-- 	signal d_sel1		: std_logic;
-- 	signal d_s1			: std_logic;
-- 	signal d_s2			: std_logic;
-- 	signal d_s3			: std_logic;
-- 	signal d_sys_in		: std_logic;
-- begin
-- 	-- control cell
-- 	c_en1 	<= output_en when mode_5 = '0' else  c_en2;
-- 	c_en 	<= c_en1 and mode_6;
-- 	c_in	<= c_en1 when shiftDR = '0' else d_s3;
	
-- 	next_cell <= c_next_Cell;
-- 	process(clockDR)
-- 	begin
-- 		if rising_edge(clockDR) then
-- 			c_next_Cell <= c_in;
-- 		end if;
-- 	end process;

-- 	process(updateDR)
-- 	begin
-- 		if rising_edge(updateDR) then
-- 			c_en2 <= c_next_Cell;
-- 		end if;
-- 	end process;

-- 	-- combined input and output cell
-- 	d_out 		<= output_data when mode_5 = '0' else d_out2;
-- 	d_sys_in 	<= system_pin when mode_2 = '0' else d_out2;
-- 	d_sel1 		<= c_en1 and not mode_5;
-- 	d_s1		<= d_sys_in when d_sel1 = '0' else d_out;
-- 	d_s2 		<= d_s1 when shiftDR = '0' else prev_cell;

-- 	process(clockDR)
-- 	begin
-- 		if rising_edge(clockDR) then
-- 			d_s3 <= d_s2;
-- 		end if;
-- 	end process;

-- 	process(updateDR)
-- 	begin
-- 		if rising_edge(updateDR) then
-- 			d_out2 <= d_s3;
-- 		end if;
-- 	end process;

-- 	input_data 	<= d_sys_in;

-- 	-- enable output
-- 	system_pin <= d_out when c_en = '1' else 'Z';
-- end architecture;


-- included again due to "no declaration for std_logic" error
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity bsreg is 
	generic (
		len : natural := 4
	);
	port (
		tck			: in std_logic;
		reset 		: in std_logic;
		enableIn	: in std_logic;
		enableOut	: in std_logic;
		mode 		: in std_logic;
		clkDR		: in std_logic;
		shiftDR		: in std_logic; -- select between serial (1) and parallel (0) input
		updateDr	: in std_logic;
		data_pin 	: in std_logic_vector(len-1 downto 0); -- low bits are closer to tdi, high bits closer to tdo
		tdi			: in std_logic; -- serial input
		tdo			: out std_logic; -- serial output
		data_pout	: out std_logic_vector(len-1 downto 0)
	);
end entity;

architecture behaviour of bsreg is
	signal data : std_logic_vector(len downto 0);
begin
	data(0) <= tdi;
	tdo 	<= data(len); 
	
	gen_bsr_cells : for i in 0 to len-1 generate
		bsreg_cell : entity work.bsr_cell(behaviour) port map (
			reset 		=> reset,
			enableIn 	=> enableIn,
			enableOut 	=> enableOut,
			mode 		=> mode,
			clkDR		=> clkDR,
			shiftDR		=> shiftDR,
			updateDR	=> updateDR,
			data_pin	=> data_pin(i), 
			prevCell	=> data(i),
			nextCell	=> data(i+1),
			data_pout	=> data_pout(i)
		);
	end generate;
end architecture;

