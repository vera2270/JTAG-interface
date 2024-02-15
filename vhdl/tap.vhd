
library IEEE;
use IEEE.STD_LOGIC_1164.all;
library work;
use work.jtag_constants.all;

entity tap is
	generic (
		bsregInLen	: natural := 4;
		bsregOutLen	: natural := 4
	);
	port(
		tck		: in std_logic; -- clock signal
		tms		: in std_logic; -- test mode select
		tdi		: in std_logic; -- test data in, shall be sampled on rising edge of tck
		trst	: in std_logic; -- reset
		tdo		: out std_logic; -- test data out

		pins_in	: in std_logic_vector(bsregInLen-1 downto 0);
		pins_out: out std_logic_vector(bsregOutLen-1 downto 0);

		logic_pins_in	: out std_logic_vector(bsregInLen-1 downto 0);
		logic_pins_out	: in std_logic_vector(bsregOutLen-1 downto 0);

		active			: out std_logic;
		config_data		: out std_logic_vector(31 downto 0);
		config_strobe	: out std_logic
	);
end entity;

architecture behaviour of tap is
	signal tstate		: std_logic_vector(3 downto 0);
	signal reset		: std_logic;
	signal tselect		: std_logic;
	signal enable 		: std_logic;
	signal clkIR		: std_logic;
	signal captureIR	: std_logic;
	signal shiftIR		: std_logic;
	signal updateIR		: std_logic;
	signal clkDR		: std_logic;
	signal captureDR	: std_logic;
	signal shiftDR		: std_logic;
	signal updateDR		: std_logic;
	
	signal IRdata_pin	: std_logic_vector(irRegLen -1 downto 0);
	signal IRtdi 		: std_logic;
	signal IRout		: std_logic_vector(instr_num -1 downto 0);
	signal ir_tdo_mux	: std_logic;

	signal shiftBSR			: std_logic;
	signal updateBSR		: std_logic;
	signal BSRIndata_pin	: std_logic_vector(bsregInLen -1 downto 0);
	signal bsrInEnableIn	: std_logic;
	signal bsrInEnableOut	: std_logic;
	signal bsrIn_mode		: std_logic;
	signal BSRIntdi 		: std_logic;
	signal BSRIntdo 		: std_logic;

	signal BSROutdata_pout	: std_logic_vector(bsregOutLen -1 downto 0);
	signal bsrOutEnableIn	: std_logic;
	signal bsrOutEnableOut	: std_logic;
	signal bsrOut_mode		: std_logic;
	signal BSROuttdi 		: std_logic;
	signal BSROuttdo 		: std_logic;

	signal shiftBP		: std_logic;
	signal captureBP	: std_logic;
	signal BPdata_in	: std_logic;
	signal BPdata_out	: std_logic;

	signal shiftID		: std_logic;
	signal id_out		: std_logic;
	
	signal dr_tdo_mux	: std_logic;

	signal clkConfig		: std_logic;
	signal resetConfig		: std_logic;
	signal dataInConfig		: std_logic;
	signal dataOutConfig	: std_logic_vector(31 downto 0);
	signal strobeConfig		: std_logic;
	signal configFinished	: std_logic;
	signal jtag_active		: std_logic; -- for config select
begin
	tcontroller : entity work.tap_controller(behaviour) port map (
		clk 		=> tck,
		tms			=> tms,
		trst		=> trst,
		tstate  	=> tstate,
		reset		=> reset,
		tselect		=> tselect,
		enable 		=> enable,
		-- states
		clkIR		=> clkIR,
		captureIR	=> captureIR,
		shiftIR		=> shiftIR,
		updateIR	=> updateIR,
		clkDR		=> clkDR,
		captureDR	=> captureDR,
		shiftDR		=> shiftDR,
		updateDR	=> updateDR
	);

	IRdata_pin(irRegLen-1 downto 1) <= (others => '0');
	IRdata_pin(0) <= '1';
	ir : entity work.instruction_register(behaviour) 
	generic map (
		reg_length 	=> irRegLen,
		instr_num 	=> instr_num
	)
	port map (
		clkIR	=> clkIR,
		upIR	=> updateIR,
		shIR	=> shiftIR,
		piData	=> IRdata_pin,
		tdi		=> IRtdi,
		reset	=> reset,
		instrB	=> IRout,
		tdo_mux	=> ir_tdo_mux,
		state	=> tstate
	);
	
	bsr_in : entity work.bsreg(behaviour) -- connected to system input pins
	generic map (
		len	=> bsregInLen
	)
	port map (
		tck 		=> tck,
		reset		=> reset,
		enableIn 	=> bsrInEnableIn,
		enableOut	=> bsrInEnableout,
		mode		=> bsrIn_mode,
		clkDR 		=> clkDR,
		shiftDR 	=> shiftBSR,
		updateDR 	=> updateBSR,
		data_pin 	=> pins_in,
		tdi 		=> BSRIntdi,
		tdo 		=> BSRIntdo,
		data_pout 	=> logic_pins_in
	);

	bsr_out : entity work.bsreg(behaviour) -- connected to system output pins
	generic map (
		len	=> bsregOutLen
	)
	port map (
		tck 		=> tck,
		reset		=> reset,
		enableIn 	=> bsrOutEnableIn,
		enableOut	=> bsrOutEnableout,
		mode		=> bsrOut_mode,
		clkDR 		=> clkDR,
		shiftDR 	=> shiftBSR,
		updateDR 	=> updateBSR,
		data_pin 	=> logic_pins_out,
		tdi 		=> BSRIntdo,
		tdo 		=> BSROuttdo,
		data_pout 	=> pins_out
	);

	reg_bypass_i : entity work.reg_bypass(behaviour)
	port map (
		data_in 	=> BPdata_in,
		shiftDR		=> shiftBP,
		clkDR 		=> clkDR,
		data_out	=> BPdata_out
	);

	reg_id_i : entity work.reg_id(behaviour)
	port map (
		clkDR		=> clkDR,
		shiftDR		=> shiftID,
		data_out	=> id_out
	);

	-- configuration logic
	config : entity work.config_jtag(behaviour)
	port map (
		clk 		=> clkConfig,
		reset		=> resetConfig,
		data_in		=> dataInConfig,
		finished	=> configFinished,
		data_out	=> dataOutConfig,
		strobe		=> strobeConfig
	);
	active <= jtag_active;
	config_data <= dataOutConfig;
	config_strobe <= strobeConfig;


	shiftBSR 	<= shiftDR when (IRout = sample_preload or IRout = extest or IRout = intest) else '1';
	updateBSR 	<= updateDR when (IRout = sample_preload or IRout = extest or IRout = intest) else '1';

	shiftBP 	<= shiftDR when (IRout = bypass) else '1';
	captureBP 	<= captureDR when (IRout = bypass) else '1';

	shiftID 	<= shiftDR when (IRout = idcode) else '1';

	jtag_active <= '1' when (configFinished = '0' and tstate = idle_c and IRout = program) else '0';
	clkConfig <= tck when (IRout = program and tstate = idle_c) else '1';
	dataInConfig <= tdi when (IRout = program) else '1';

	process(tstate, trst) 
	begin
		if (falling_edge(trst) or tstate = selectdr_c) then
			resetConfig <= '0';
		else 
			resetConfig <= '1';
		end if;
	end process;
	
	-- tdo mux
	tdo <= 	ir_tdo_mux when (enable = '1' and tselect = '1') else
			dr_tdo_mux when (enable = '1' and tselect = '0') else '0';

	IRtdi <= tdi when (tselect = '1') else '0';

	BPdata_in 		<= 	tdi when tselect = '0' and (IRout = bypass) else '0'; -- BYPASS
	BSRIntdi		<= 	tdi when tselect = '0' and (IRout = sample_preload or IRout = extest or IRout = intest) else '0'; -- SAMPLE/PRELOAD or EXTEST or INTEST
	dr_tdo_mux 		<= 	BPdata_out when tselect = '0' and (IRout = bypass) else -- BYPASS
						id_out when tselect = '0' and (IRout = idcode) else -- IDCODE
						BSROuttdo when tselect = '0' and (IRout = sample_preload or IRout = extest or IRout = intest) else '0'; -- SAMPLE/PRELOAD or EXTEST or INTEST
	bsrIn_mode 		<=	'0' when tselect = '0' and (IRout = bypass or IRout = idcode or IRout = sample_preload) else -- BYPASS or IDCODE or SAMPLE/PRELOAD pi
						'1' when tselect = '0' and (IRout = extest or IRout = intest) else '0'; -- EXTEST si or INTEST
	bsrOut_mode		<=	'0' when tselect = '0' and (IRout = bypass or IRout = idcode or IRout = sample_preload) else -- BYPASS or IDCODE or SAMPLE/PRELOAD po
						'1' when tselect = '0' and (IRout = extest or IRout = intest) else '0'; -- EXTEST so or INTEST
	bsrInEnableIn	<=	'1' when tselect = '0' and (IRout = bypass or IRout = idcode or IRout = sample_preload or IRout = extest) else -- BYPASS or IDCODE or SAMPLE/PRELOAD or EXTEST
						'0' when tselect='0' and (IRout = intest) else '1'; -- INTEST
	bsrInEnableOut	<=	'1' when tselect = '0' and (IRout = bypass or IRout = idcode or IRout = sample_preload or IRout = intest) else -- BYPASS or IDCODE or SAMPLE/PRELOAD or INTEST
						'0' when tselect = '0' and (IRout = extest) else '1'; -- EXTEST
	bsrOutEnableIn	<=	'1' when tselect = '0' and (IRout = bypass or IRout = idcode or IRout = sample_preload or IRout = intest) else -- BYPASS or IDCODE or SAMPLE/PRELOAD or INTEST
						'0' when tselect = '0' and (IRout = extest) else '1'; -- EXTEST
	bsrOutEnableOut	<=	'1' when tselect = '0' and (IRout = bypass or IRout = idcode or IRout = sample_preload or IRout = extest or IRout = intest) else '1'; -- BYPASS or IDCODE or SAMPLE/PRELOAD or EXTEST or INTEST
end architecture;
