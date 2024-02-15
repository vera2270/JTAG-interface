
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity instruction_register_cell is
	port (
		clkIR	: in std_logic; -- clock
		shIR	: in std_logic; -- shift IR state
		piData	: in std_logic; -- parallel input data
		preData	: in std_logic; -- data from previous cell
		dataNex	: out std_logic -- data to next cell
	);
end entity;

architecture behaviour of instruction_register_cell is
	signal s1	: std_logic;
begin
	with shIR select
		s1 <= 	piData when '0',
				preData when others;
	
	shift_data : process(clkIR)
	begin
		if falling_edge(clkIR) then
			dataNex <= s1;
		end if;
	end process;
end architecture;

-- included again due to "no declaration for std_logic" error
library IEEE;
use IEEE.STD_LOGIC_1164.all;
library work;
use work.jtag_constants.all;

entity instruction_register is
    generic(
        reg_length 	: natural := ireg_length; -- min 2
		instr_num	: natural := len_instruction -- min 4
    );
	port(
		clkIR	: in std_logic; -- clock
		upIR	: in std_logic; -- update IR state
		shIR	: in std_logic; -- shift IR state
		piData	: in std_logic_vector(reg_length-1 downto 0); -- parallel input data, low bits close to tdi
		tdi		: in std_logic; -- tap data in
		reset	: in std_logic; -- to apply BYPASS or IDCODE
		instrB	: out std_logic_vector(instr_num -1 downto 0); -- instruction Bits
		tdo_mux	: out std_logic; -- data to tdo MUX
		state	: in std_logic_vector(3 downto 0)
	);
end entity;

architecture behaviour of instruction_register is
    signal data 		: std_logic_vector(reg_length downto 0);
	signal instr_data	: std_logic_vector(instr_num-1 downto 0);
begin 
	data(0) <= tdi;
	tdo_mux <= data(data'high);
	
	gen_ireg_cells : for i in 0 to reg_length-1 generate
		ireg_cell : entity work.instruction_register_cell(behaviour) port map (
			clkIR	=> clkIR,
			shIR	=> shIR,
			piData	=> piData(i), -- to load 'x01' according to standard
			preData	=> data(i),
			dataNex	=> data(i+1)
		);
	end generate;

	decode : process(state) -- every possible input must have a defined outcome
	begin
		if (state = exit1ir_c) then -- exit1IR
			case data(data'high downto 1) is
				when "001" => instr_data <= idcode; -- IDCODE
				when "010" => instr_data <= sample_preload; -- SAMPLE or PRELOAD
				when "100" => instr_data <= extest; -- EXTEST
				when "101" => instr_data <= program; -- PROGRAM
				when "110" => instr_data <= intest; -- INTEST
				when others => instr_data <= bypass; -- BYPASS by default
			end case;
		end if;
	end process;
	
	-- clocked instruction bits output
	ir_output : process(reset, upIR)
	begin
		if (reset = '0') then -- active low
			instrB <= (others => '0');
			instrB(0) <= '1'; -- BYPASS or IDCODE
		else
			if falling_edge(upIR) then
				instrB <= instr_data;
			end if;
		end if;
	end process;
end architecture;