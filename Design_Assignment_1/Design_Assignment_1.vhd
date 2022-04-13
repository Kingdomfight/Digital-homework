--Design for code lock to be used with a 3x3 keypad. Debounce is implemented in the design.
--The following keypad layout is assumed:			1	2	3
--																4	5	6
--																7	8	9
--
--g_CLKS_PER_DEBOUNCE: amount of clock cycles the signal needs to be stable high for an input to be registered
--
--g_COMBINATION: 4 digit combination that needs to be entered for the o_Correct signal to go high.
--					  combination can't include any 0's.
--
--i_CLK: the input is sampled every rising edge of the clock
--
--i_Keypad: 6 bit input, one bit for every row and column
--				when no button is depressed, all the input's should be logical low
--				When a button is depressed, the corresponding row and column input should be logical high
--				When more than one button is pressed, no input is registered
--			 	bit 0: top row
--			  	bit 1: middle row
--			  	bit 2: bottom row
--			  	bit 3: right column
--			  	bit 4: middle column
--			  	bit 5: left column
--
--o_Correct: '1' for one clock cycle after the correct combination has been put in


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Design_Assignment_1 is
	generic(
		g_CLKS_PER_DEBOUNCE	: positive := 5;
		g_COMBINATION			: integer range 1 to 9999 := 1234
		);
	port(
		i_CLK     : in std_logic;
		i_Keypad  : in std_logic_vector(5 downto 0);
		o_Correct : out std_logic
	);
end entity Design_Assignment_1;

architecture RTL of Design_Assignment_1 is

	type t_Combination is array (3 downto 0) of integer range 0 to 9;		--0's are used when no input is button is pressed
	type t_Counter is array (0 to 5) of integer range 0 to g_CLKS_PER_DEBOUNCE;
	
	constant c_CORRECT_COMB : t_Combination := (g_COMBINATION / 1000,
															  (g_COMBINATION mod 1000) / 100,
															  (g_COMBINATION mod 100) / 10,
															  g_COMBINATION mod 10);
															  
	signal r_Prev_Input : std_logic_vector(5 downto 0) := (others => '0');
	signal r_Counter : t_Counter := (others => g_CLKS_PER_DEBOUNCE);
	signal r_Debounced_Input : std_logic_vector(5 downto 0) := (others => '0');
	signal r_Pressed_Button : integer range 0 to 9 := 0;
	signal r_Prev_Pressed_Button : integer range 0 to 9 := 0;
	signal r_User_Input : t_Combination := (others => 0);

begin

	--Determines debounced input state r_Debounced_Input
	p_Debounce : process(i_CLK)
	begin
		if rising_edge(i_CLK) then
			for i in 0 to 5 loop		--Repeat logic for every input
				r_Prev_Input(i) <= i_Keypad(i);
				--Input has changed
				if i_Keypad(i) /= r_Prev_Input(i) then
					r_Counter(i) <= 0;
				--Waiting for debounce delay
				elsif r_Counter(i) < g_CLKS_PER_DEBOUNCE then
					r_Counter(i) <= r_Counter(i) + 1;
				--Input is debounced
				else
					r_Debounced_Input(i) <= i_Keypad(i);
				end if;
			end loop;
		end if;
	end process p_Debounce;
	
	--Determines which button is pressed down based on debounced input state
	p_Keypad : process(r_Debounced_Input)
	begin
		case r_Debounced_Input(2 downto 0) is
			--Top row
			when "001" =>
				case r_Debounced_Input(5 downto 3) is
					when "001" => r_Pressed_Button <= 3;
					when "010" => r_Pressed_Button <= 2;
					when "100" => r_Pressed_Button <= 1;
					when others => r_Pressed_Button <= 0;
				end case;
			--Middle row
			when "010" =>
				case r_Debounced_Input(5 downto 3) is
					when "001" => r_Pressed_Button <= 6;
					when "010" => r_Pressed_Button <= 5;
					when "100" => r_Pressed_Button <= 4;
					when others => r_Pressed_Button <= 0;
				end case;
			--Bottom row
			when "100" =>
				case r_Debounced_Input(5 downto 3) is
					when "001" => r_Pressed_Button <= 9;
					when "010" => r_Pressed_Button <= 8;
					when "100" => r_Pressed_Button <= 7;
					when others => r_Pressed_Button <= 0;
				end case;
			when others => r_Pressed_Button <= 0;
		end case;
	end process p_Keypad;
	
	--Keeps track of previous button presses and determines output correct signal
	p_Shift_Register : process(i_CLK)
	begin
		if rising_edge(i_CLK) then
			r_Prev_Pressed_Button <= r_Pressed_Button;
			--Only track when button state goes from unpressed to depressed
			if r_Pressed_Button /= 0 and r_Pressed_Button /= r_Prev_Pressed_Button then
				r_User_Input <= r_User_Input(2 downto 0) & r_Pressed_Button;	--Shift left
			end if;
			--Check if correct combination has been entered
			if r_User_Input = c_CORRECT_COMB then
				o_Correct <= '1';
				r_User_Input <= (others => 0);
			else
				o_Correct <= '0';
			end if;
		end if;
	end process p_Shift_Register;
end architecture RTL;