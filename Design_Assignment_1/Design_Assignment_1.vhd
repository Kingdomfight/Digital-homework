--i_Keypad bit 0: top row
--			  bit 1: middle row
--			  bit 2: bottom row
--			  bit 3: right column
--			  bit 4: middle column
--			  bit 5: left column

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

	type t_Combination is array (3 downto 0) of integer range 0 to 9;
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

	p_Debounce : process(i_CLK)
	begin
		if rising_edge(i_CLK) then
			for i in 0 to 5 loop
				r_Prev_Input(i) <= i_Keypad(i);
				r_Debounced_Input(i) <= '0';
				if i_Keypad(i) /= r_Prev_Input(i) then
					r_Counter(i) <= 0;
					r_Counter(i) <= 0;
				elsif r_Counter(i) < g_CLKS_PER_DEBOUNCE then
					r_Counter(i) <= r_Counter(i) + 1;
				else
					r_Debounced_Input(i) <= i_Keypad(i);
				end if;
			end loop;
		end if;
	end process p_Debounce;
	
	p_Keypad : process(r_Debounced_Input)
	begin
		case r_Debounced_Input(2 downto 0) is
			when "001" =>
				case r_Debounced_Input(5 downto 3) is
					when "001" => r_Pressed_Button <= 3;
					when "010" => r_Pressed_Button <= 2;
					when "100" => r_Pressed_Button <= 1;
					when others => r_Pressed_Button <= 0;
				end case;
			when "010" =>
				case r_Debounced_Input(5 downto 3) is
					when "001" => r_Pressed_Button <= 6;
					when "010" => r_Pressed_Button <= 5;
					when "100" => r_Pressed_Button <= 4;
					when others => r_Pressed_Button <= 0;
				end case;
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
	
	p_State_Machine : process(i_CLK)
	begin
		if rising_edge(i_CLK) then
			r_Prev_Pressed_Button <= r_Pressed_Button;
			if r_Pressed_Button /= 0 and r_Pressed_Button /= r_Prev_Pressed_Button then
				r_User_Input <= r_User_Input(2 downto 0) & r_Pressed_Button;
			end if;
			if r_User_Input = c_CORRECT_COMB then
				o_Correct <= '1';
				r_User_Input <= (others => 0);
			else
				o_Correct <= '0';
			end if;
		end if;
	end process p_State_Machine;
end architecture RTL;