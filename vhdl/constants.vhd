library IEEE;
use IEEE.STD_LOGIC_1164.all;

package jtag_constants is
	constant id_data : std_logic_vector(31 downto 0) := x"0000_0001"; -- LSB must be 1

	constant len_instruction	: natural := 5;
	constant ireg_length		: natural := 3;

	constant bypass : std_logic_vector(len_instruction-1 downto 0) := (others => '0');
	constant idcode : std_logic_vector(len_instruction-1 downto 0) := "00001";
	constant sample_preload : std_logic_vector(len_instruction-1 downto 0) := "00010";
	constant extest : std_logic_vector(len_instruction-1 downto 0) := "00100";
	constant intest : std_logic_vector(len_instruction-1 downto 0) := "01000";
	constant program : std_logic_vector(len_instruction-1 downto 0) := "10000";

	constant tlreset_c 		: std_logic_vector(3 downto 0) := x"F";
	constant idle_c 		: std_logic_vector(3 downto 0) := x"C";
	constant selectdr_c 	: std_logic_vector(3 downto 0) := x"7";
	constant capturedr_c	: std_logic_vector(3 downto 0) := x"6";
	constant shiftdr_c 		: std_logic_vector(3 downto 0) := x"2";
	constant exit1dr_c 		: std_logic_vector(3 downto 0) := x"1";
	constant pausedr_c 		: std_logic_vector(3 downto 0) := x"3";
	constant exit2dr_c 		: std_logic_vector(3 downto 0) := x"0";
	constant updatedr_c 	: std_logic_vector(3 downto 0) := x"5";
	constant selectir_c 	: std_logic_vector(3 downto 0) := x"4";
	constant captureir_c	: std_logic_vector(3 downto 0) := x"E";
	constant shiftir_c 		: std_logic_vector(3 downto 0) := x"A";
	constant exit1ir_c 		: std_logic_vector(3 downto 0) := x"9";
	constant pauseir_c 		: std_logic_vector(3 downto 0) := x"B";
	constant exit2ir_c 		: std_logic_vector(3 downto 0) := x"8";
	constant updateir_c 	: std_logic_vector(3 downto 0) := x"D";
end package;

