library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Comb_Lock_TB is
end entity;

architecture Simulation of Comb_Lock_TB is

	constant c_CLK_PERIOD : time := 20 ns;				--50 MHz clock
	constant c_CLKS_PER_DEBOUNCE : integer := 25E5;	--50ms debounce time
	constant c_COMBINATION : integer := 1234;
	
	--Used to convert integer input to std_logic input
	type t_Int_To_Key is array (1 to 9) of std_logic_vector(5 downto 0);
	constant c_INT_TO_KEY : t_Int_To_Key := (1 => "100001",
														  2 => "010001",
														  3 => "001001",
														  4 => "100010",
														  5 => "010010",
														  6 => "001010",
														  7 => "100100",
														  8 => "010100",
														  9 => "001100");
														  
	signal r_CLK : std_logic := '0';
	signal w_Keypad : std_logic_vector(5 downto 0);
	signal w_Correct : std_logic;

	--Simulates a bouncing button being pressed and unpressed
	--Total sequence takes 160ms
	procedure Press_Key(constant KEY : in integer;
							  signal Keypad : out std_logic_vector(5 downto 0)) is
	begin
		Keypad <= c_INT_TO_KEY(KEY);
		for i in 1 to 3 loop
			wait for 5 ms;
			Keypad <= (others => '0');
			wait for 5 ms;
			Keypad <= c_INT_TO_KEY(KEY);
		end loop;
		wait for c_CLKS_PER_DEBOUNCE * c_CLK_PERIOD * 2;
		report "Pressed " & integer'image(KEY);
		Keypad <= (others => '0');
		for i in 1 to 3 loop
			wait for 5 ms;
			Keypad <= c_INT_TO_KEY(KEY);
			wait for 5 ms;
			Keypad <= (others => '0');
		end loop;
	end procedure Press_Key;
	
begin

	r_CLK <= not r_CLK after c_CLK_PERIOD / 2;

	--Instance of the code lock design
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
		Press_Key(1, w_Keypad);
		wait for 10 ms;
		Press_Key(2, w_Keypad);
		wait for 10 ms;
		Press_Key(3, w_Keypad);
		wait for 10 ms;
		Press_Key(4, w_Keypad);
		assert false severity failure;
	end process;
	
	process
	begin
		wait until w_Correct = '1';
		report "Unlocked";
		wait;
	end process;

end architecture Simulation;