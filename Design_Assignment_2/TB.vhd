library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB is
end entity TB;

architecture sim of TB is

	signal CLK : std_logic := '0';
	signal i_valid : std_logic := '0';
	signal i_rdy : std_logic;
	signal o_valid : std_logic;
	signal o_rdy : std_logic := '0';
	signal d_in : signed(7 downto 0) := "01010101";
	
begin

	CLK <= not CLK after 20 ns;

	UUT : entity work.Design_Assignment_2(RTL)
		port map (
			CLK => CLK,
			RST => '0',
			i_valid => i_valid,
			i_rdy => i_rdy,
			o_valid => o_valid,
			o_rdy => o_rdy,
			d_in => d_in,
			d_out => open);
			
	input : process(CLK)
		variable state : integer range 0 to 1 := 0;
	begin
		if falling_edge(CLK) then
			case state is
				when 0 =>
					if i_rdy = '0' then
						d_in <= d_in(0) & d_in(7 downto 1);
						i_valid <= '1';
						state := 1;
					end if;
					
				when 1 =>
					if i_rdy = '1' then
						i_valid <= '0';
						state := 0;
					end if;
			end case;
		end if;
	end process input;
	
	output : process(CLK)
		variable state : integer range 0 to 1 := 0;
	begin
		if falling_edge(CLK) then
			case state is
				when 0 =>
					if o_valid = '1' then
						o_rdy <= '1';
						state := 1;
					end if;
					
				when 1 =>
					if o_valid = '0' then
						o_rdy <= '0';
						state := 0;
					end if;
			end case;
		end if;
	end process output;
		
end architecture sim;