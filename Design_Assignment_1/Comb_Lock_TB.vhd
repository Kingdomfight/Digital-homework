library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Comb_Lock_TB is
end entity;

architecture Simulation of Comb_Lock_TB is

	constant c_CLKS_PER_DEBOUNCE : integer := 10;
	constant c_COMBINATION : integer := 1234;
	constant c_CLK_PERIOD : time := 20 ns;
	
	constant c_1 : std_logic_vector(5 downto 0) := "100001";
	constant c_2 : std_logic_vector(5 downto 0) := "010001";
	constant c_3 : std_logic_vector(5 downto 0) := "001001";
	constant c_4 : std_logic_vector(5 downto 0) := "100010";
	constant c_5 : std_logic_vector(5 downto 0) := "010010";
	constant c_6 : std_logic_vector(5 downto 0) := "001010";
	constant c_7 : std_logic_vector(5 downto 0) := "100100";
	constant c_8 : std_logic_vector(5 downto 0) := "010100";
	constant c_9 : std_logic_vector(5 downto 0) := "001100";
	
	signal r_CLK : std_logic := '0';
	signal w_Keypad : std_logic_vector(5 downto 0);
	signal w_Correct : std_logic;

begin

	r_CLK <= not r_CLK after c_CLK_PERIOD / 2;

	UUT_INST : entity work.Design_Assignment_1
		generic map (
			g_CLKS_PER_DEBOUNCE => c_CLKS_PER_DEBOUNCE,
			g_COMBINATION => c_COMBINATION
		)
		port map (
			i_CLK => r_CLK,
			i_Keypad => w_Keypad,
			o_Correct => w_Correct
		);
		
	process
	begin
		w_Keypad <= c_1;
		report "Pressed 1";
		wait for (c_CLKS_PER_DEBOUNCE + 2) * c_CLK_PERIOD;
		w_Keypad <= c_2;
		report "Pressed 2";
		wait for (c_CLKS_PER_DEBOUNCE + 2) * c_CLK_PERIOD;
		w_Keypad <= c_3;
		report "Pressed 3";
		wait for (c_CLKS_PER_DEBOUNCE + 2) * c_CLK_PERIOD;
		w_Keypad <= c_4;
		report "Pressed 4";
		wait for (c_CLKS_PER_DEBOUNCE + 2) * c_CLK_PERIOD;
		wait until w_Correct = '1';
		assert false report "Unlocked" severity failure;
	end process;

end architecture Simulation;