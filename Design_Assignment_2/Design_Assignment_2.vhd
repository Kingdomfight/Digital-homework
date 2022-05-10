library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Design_Assignment_2 is
	port(
		CLK	  : in std_logic;
		RST	  : in std_logic;
		
		i_valid : in std_logic;
		i_rdy   : out std_logic;
		
		o_valid : out std_logic;
		o_rdy   : in std_logic;
		
		d_in	  : in signed(7 downto 0);
		d_out   : out signed(7 downto 0)
	);
end entity Design_Assignment_2;

architecture RTL of Design_Assignment_2 is

	constant c_DATAPATH_DELAY : integer := 5;

	signal r_avail : std_logic := '0';
	signal r_cpd   : std_logic := '0';
	signal r_C1_State : integer range 0 to 3 := 0;
	signal r_C2_State : integer range 0 to 3 := 0;
	signal r_Process : std_logic := '0';
	signal r_Load : std_logic := '0';
	signal r_Done : std_logic := '0';

begin

	p_Controller_1 : process(CLK, RST)
	begin
		if RST = '1' then
			r_C1_State <= 0;
			i_rdy <= '0';
			r_avail <= '0';
			r_Load <= '0';
		elsif rising_edge(CLK) then
			case r_C1_State is
				when 0 =>
					i_rdy <= '0';
					r_avail <= '0';
					r_Load <= '0';
					if i_valid = '1' and r_cpd = '0' then
						r_C1_State <= 1;
					end if;
				
				when 1 =>
					i_rdy <= '0';
					r_avail <= '0';
					r_Load <= '1';
					r_C1_State <= 2;
					
				when 2 =>
					i_rdy <= '1';
					r_avail <= '0';
					r_Load <= '0';
					if i_valid = '0' then
						r_C1_State <= 3;
					end if;
					
				when 3 =>
					i_rdy <= '0';
					r_avail <= '1';
					r_Load <= '0';
					r_C1_State <= 0;
			end case;
		end if;
	end process p_Controller_1;
	
	p_Controller_2 : process(CLK, RST)
	begin
		if RST = '1' then
			r_C2_State <= 0;
			o_valid <= '0';
			r_cpd <= '0';
			r_Process <= '0';
		elsif rising_edge(CLK) then
			case r_C2_State is
				when 0 =>
					o_valid <= '0';
					r_cpd <= '0';
					r_Process <= '0';
					if r_avail = '1' then
						r_C2_State <= 1;
					end if;
					
				when 1 =>
					o_valid <= '0';
					r_cpd <= '1';
					r_Process <= '1';
					if r_Done = '1' then
						r_C2_State <= 2;
					end if;
				when 2 =>
					o_valid <= '1';
					r_cpd <= '1';
					r_Process <= '1';
					if o_rdy = '1' then
						r_C2_State <= 3;
					end if;
					
				when 3 =>
					o_valid <= '0';
					r_cpd <= '1';
					r_Process <= '0';
					if o_rdy = '0' then
						r_C2_State <= 0;
					end if;
			end case;
		end if;
	end process p_Controller_2;
	
--	This process is for verrifying the behaviour of the controllers.
--	It is not meant to behave like the FIR filter
	p_Datapath : process(CLK, RST)
		variable Data_In : signed(7 downto 0);
		variable Counter : integer range 0 to c_DATAPATH_DELAY-1;
	begin
		if RST = '1' then
			d_out <= (others => '0');
			r_Done <= '0';
		elsif rising_edge(CLK) then
			if r_Load = '1' then
				Data_In := d_in;
			end if;
			
			if r_Process = '1' then
				if Counter < c_DATAPATH_DELAY-1 then
					Counter := Counter+1;
					d_out <= (others => '0');
					r_Done <= '0';
				else
					d_out(7) <= Data_In(7);
					d_out(6 downto 1) <= Data_In(5 downto 0);
					d_out(0) <= Data_In(6);
					r_Done <= '1';
				end if;
			else
				Counter := 0;
				d_out <= (others => '0');
				r_Done <= '0';
			end if;
		end if;
	end process p_Datapath;

end architecture RTL;