
library IEEE;
use IEEE.STD_LOGIC_1164.all;
library work;
use work.jtag_constants.all;



entity tap_controller is
    port (
        clk     	: in std_logic; -- clock signal
        tms     	: in std_logic; -- test mode select
		trst		: in std_logic; -- global reset, active low
		tstate  	: out std_logic_vector(3 downto 0); -- for debug ?
		reset		: out std_logic; -- active low
		tselect		: out std_logic; -- select for tdo mux
		enable		: out std_logic; -- enable tdo
		-- states output
		clkIR		: out std_logic; -- clock for IR
		captureIR	: out std_logic; -- capture IR 
		shiftIR		: out std_logic; -- shift IR
		updateIR	: out std_logic; -- update IR
		clkDR		: out std_logic; -- clock for DR
		captureDR	: out std_logic; -- capture DR
		shiftDR		: out std_logic; -- shift DR
		updateDR	: out std_logic -- update DR
    );
end entity;

architecture behaviour of tap_controller is
	type state is (tlreset, idle, seldr, capdr, shdr, ex1dr, pdr, ex2dr, updr, selir, capir, shir, ex1ir, pir, ex2ir, upir);
    signal state_current, state_next : state;
	signal timeout	: std_logic_vector(4 downto 0);
begin
    select_state_next : process(tms, state_current)
    begin
		if (tms = '0') then
			case state_current is
				when tlreset    => state_next <= idle; 
				when idle       => state_next <= idle; 
				when seldr      => state_next <= capdr; 
				when capdr      => state_next <= shdr; 
				when shdr       => state_next <= shdr; 
				when ex1dr      => state_next <= pdr; 
				when pdr        => state_next <= pdr;
				when ex2dr      => state_next <= shdr;
				when updr       => state_next <= idle;
				when selir      => state_next <= capir; 
				when capir      => state_next <= shir; 
				when shir       => state_next <= shir; 
				when ex1ir      => state_next <= pir; 
				when pir        => state_next <= pir;
				when ex2ir      => state_next <= shir;
				when upir       => state_next <= idle;
				when others     => state_next <= tlreset;
			end case;
		elsif (tms = '1') then -- undriven input shall respond identical to logic 1 e.g. by including a pull-up resistor in the input circuitry
			case state_current is
				when tlreset    => state_next <= tlreset; 
				when idle       => state_next <= seldr; 
				when seldr      => state_next <= selir; 
				when capdr      => state_next <= ex1dr; 
				when shdr       => state_next <= ex1dr; 
				when ex1dr      => state_next <= updr; 
				when pdr        => state_next <= ex2dr;
				when ex2dr      => state_next <= updr;
				when updr       => state_next <= seldr;
				when selir      => state_next <= tlreset; 
				when capir      => state_next <= ex1ir; 
				when shir       => state_next <= ex1ir; 
				when ex1ir      => state_next <= upir; 
				when pir        => state_next <= ex2ir;
				when ex2ir      => state_next <= upir;
				when upir       => state_next <= seldr;
				when others     => state_next <= tlreset;
			end case;
		else
			state_next <= state_current;
		end if;
    end process;
    
    tstate_output : process(state_current)
    begin
		case (state_current) is
			when tlreset    => tstate <= tlreset_c;
			when idle       => tstate <= idle_c;
			when seldr      => tstate <= selectdr_c;
			when capdr      => tstate <= capturedr_c;
			when shdr       => tstate <= shiftdr_c;
			when ex1dr      => tstate <= exit1dr_c;
			when pdr        => tstate <= pausedr_c;
			when ex2dr      => tstate <= exit2dr_c;
			when updr       => tstate <= updatedr_c;
			when selir      => tstate <= selectir_c;
			when capir      => tstate <= captureir_c;
			when shir       => tstate <= shiftir_c;
			when ex1ir      => tstate <= exit1ir_c;
			when pir        => tstate <= pauseir_c;
			when ex2ir      => tstate <= exit2ir_c;
			when upir       => tstate <= updateir_c;
			when others     => tstate <= tlreset_c;
		end case;
    end process;
    
	updateIR <= '1' when (state_current = upIR and clk = '0') else '0';
	updateDR <= '1' when (state_current = upDR and clk = '0') else '0';

	process(clk, trst)
	begin
		if (trst == '0') then
			state_current <= tlreset;
			timeout <= (others => '0');
		else 
			state_current <= state_next;
			timeout <= timeout(3 downto 0) & tms;
			if (timeout = "11111") then
				state_current <= tlreset;
				timeout <= (others => '0')
			end if;
		end if;
	end process;

	reset <= '0' when (state_current = tlreset) else trst;

	process(clk)
	begin
		if falling_edge(clk) then
			case (state_current) is
				when capIR 	=> (captureIR, shiftIR, captureDR, shiftDR) <= std_logic_vector'("1000");
				when shIR 	=> (captureIR, shiftIR, captureDR, shiftDR) <= std_logic_vector'("0100");
				when capDR 	=> (captureIR, shiftIR, captureDR, shiftDR) <= std_logic_vector'("0010");
				when shDR 	=> (captureIR, shiftIR, captureDR, shiftDR) <= std_logic_vector'("0001");
				when others => (captureIR, shiftIR, captureDR, shiftDR) <= std_logic_vector'("0000");
			end case;

			if (state_current = shIR or state_current = shDR) then
				enable <= '1';
			else 
				enable <= '0';
			end if;
		end if;
	end process;

	process(clk)
	begin
		if (tstate(3) = '1') then
			tselect <= '1';
		else 
			tselect <= '0';
		end if;

		
		if (state_current = shIR or state_current = capIR) then
			clkIR <= clk;
		else
			clkIR <= '1';
		end if;
		
		if (state_current = shDR or state_current = capDR) then
			clkDR <= clk;
		else
			clkDR <= '1';
		end if;
	end process;
end architecture;
