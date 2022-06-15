library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Design_Assignment_2 is
	port(
		--Controll signals
		CLK		: in 	std_logic;
		RST		: in 	std_logic;
	
		--Input interface
		i_valid	: in	std_logic;
		i_rdy		: out	std_logic;
		
		--Output interface
		o_valid	: out	std_logic;
		o_rdy		: in	std_logic;
		
		--Datapath interface
		d_in		: in	signed(7 downto 0);
		d_out		: out	signed(7 downto 0)
	);
end entity Design_Assignment_2;

architecture RTL of Design_Assignment_2 is
	
	--p_Controller_1 signals
	signal r_C1_State		: integer range 0 to 2 := 0;
	signal r_avail			: std_logic := '0';
	signal r_LD_Delay 	: integer range 0 to 4 := 0;
	signal r_LD_Active	: std_logic := '0';
	
	--p_Controller_2 signals
	signal r_C2_State		: integer range 0 to 3 := 0;
	signal r_cpd			: std_logic := '0';
	
	--p_Datapath signals
	type t_Data is array(0 to 4) of signed(7 downto 0);
	signal r_Data			: t_Data := (others => x"00");
	
begin

	--Controller 1 handles the input interface and data processing
	p_Controller_1 : process(CLK, RST)
	begin
		if RST = '1' then
			r_C1_State <= 0;
			i_rdy <= '0';
			r_avail <= '0';
		elsif rising_edge(CLK) then
			case r_C1_State is
				--Wait for new input
				when 0 =>
					i_rdy <= '0';
					r_LD_Active <= '0';
					if i_valid = '1' then
						r_LD_Active <= '1';
						r_C1_State <= 1;
						r_LD_Delay <= 4;
						r_avail <= '0';
					end if;
				
				--Load new data
				when 1 =>
					if r_LD_Delay > 0 then
						r_LD_Delay <= r_LD_Delay - 1;
					else
						r_LD_Active <= '0';
						r_avail <= '1';
						r_C1_State <= 2;
						i_rdy <= '1';
					end if;
				
				--Wait until sender and datapath are ready
				when 2 =>
					if i_valid = '0' and r_cpd = '0' then
						i_rdy <= '0';
						r_C1_State <= 0;
					end if;
				
			end case;
		end if;
	end process p_Controller_1;
	
	--Controller 2 handles the output interface
	p_Controller_2 : process(CLK, RST)
	begin
		if RST = '1' then
			r_C2_State <= 0;
			o_valid <= '0';
			r_cpd <= '0';
		elsif rising_edge(CLK) then
			case r_C2_State is
				--Wait for data and receiver to be ready
				when 0 =>
					o_valid <= '0';
					if o_rdy = '0' and r_avail = '1' then
						r_cpd <= '1';
						r_C2_State <= 1;
					end if;
					
				--Delay o_valid for one clk period
				when 1 =>
					o_valid <= '1';
					r_C2_State <= 2;
				
				--Wait for ready signal
				when 2 =>
					if o_rdy = '1' then
						r_cpd <= '0';
						r_C2_State <= 3;
					end if;
				
				--Delay o_valid for one clk period
				when 3 =>
					o_valid <= '0';
					r_C2_State <= 0;
					
			end case;
		end if;
	end process p_Controller_2;
	
	--The datapath is the FIR filter
	p_Datapath : process(CLK, RST)
		variable v_Out : signed(7 downto 0);
	begin
		if RST = '1' then
			r_Data <= (others => x"00");
		elsif rising_edge(CLK) then
			if r_LD_Active = '1' then
				r_Data(0)(7) <= d_in(7);
				r_Data(0)(6) <= '0';
				r_Data(0)(5 downto 0) <= d_in(6 downto 1);
				
				r_Data(1)(7) <= r_Data(0)(7);
				r_Data(1)(6) <= '0';
				r_Data(1)(5 downto 0) <= r_Data(0)(6 downto 1);
				
				r_Data(2) <= r_Data(1);
				r_Data(3) <= r_Data(2);
				r_Data(4) <= r_Data(3);
			end if;
			
			if r_cpd = '1' then
				v_Out := x"00";
				for i in 0 to 4 loop
					v_Out := v_Out + r_Data(i);
				end loop;
				d_out <= v_Out;
			else
				d_out <= (others => 'Z');
			end if;
		end if;
	end process p_Datapath;
	
end architecture RTL;