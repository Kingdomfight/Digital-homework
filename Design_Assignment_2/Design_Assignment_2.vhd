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
	signal r_C1_State		: integer range 0 to 3 := 0;
	signal r_avail			: std_logic := '0';	--Indicate to C2 when data is available
	signal r_LD_Delay 	: integer range 0 to 4 := 0;	--Counter to wait on input loading
	signal r_LD_Active	: std_logic := '0';	--Tell datapath to load data
	
	--p_Controller_2 signals
	signal r_C2_State		: integer range 0 to 3 := 0;
	signal r_cpd			: std_logic := '0';	--Tell C1 and datapath to process and register data
	signal r_out			: std_logic := '0';	--Tell datapath to output the data on d_out
	
	--p_Datapath signals
	type t_Data is array(0 to 4) of signed(7 downto 0);
	signal r_Data			: t_Data := (others => x"00");
	signal r_Data_Out		: signed(7 downto 0) := x"00";
	
begin

	--Controller 1 handles the input interface
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
						--Start loading data
						r_LD_Active <= '1';
						r_LD_Delay <= 4;
						r_avail <= '0';
						r_C1_State <= 1;
					end if;
				
				--Load new data
				when 1 =>
					if r_LD_Delay > 0 then
						r_LD_Delay <= r_LD_Delay - 1;
					else
						--Loading finished
						r_LD_Active <= '0';
						r_avail <= '1';	--New data available
						i_rdy <= '1';
						r_C1_State <= 2;
					end if;
				
				--Put i_rdy low when i_valid goes low, make sure the datapath has started processing
				when 2 =>
					if i_valid = '0' then
						i_rdy <= '0';
					end if;
					if r_cpd = '1' then
						r_C1_State <= 3;
					end if;
					
				--Put i_rdy low when i_valid goes low, wait until processing is done and user is ready for new input
				when 3 =>
					if i_valid = '0' then
						i_rdy <= '0';
					end if;
					if r_cpd = '0' and i_rdy = '0' then
						r_C1_State <= 0;
					end if;
				
			end case;
		end if;
	end process p_Controller_1;
	
	--Controller 2 handles the output interface
	p_Controller_2 : process(CLK, RST)
		variable v_avail : std_logic;	--Keeps track whether r_avail has gone low to indicate that new data is available instead of the old data
	begin
		if RST = '1' then
			r_C2_State <= 0;
			o_valid <= '0';
			r_cpd <= '0';
			r_out <= '0';
		elsif rising_edge(CLK) then
			case r_C2_State is
				--Wait for data and receiver to be ready
				when 0 =>
					o_valid <= '0';
					v_avail := '1';
					if o_rdy = '0' and r_avail = '1' then
						--Start processing
						r_cpd <= '1';
						r_C2_State <= 1;
					end if;
					
				--Output data
				when 1 =>
					r_cpd <= '0';
					r_out <= '1';
					r_C2_State <= 2;
				
				--Delay o_valid for one clk period
				when 2 =>
					o_valid <= '1';
					r_C2_State <= 3;
				
				--Wait for ready signal
				when 3 =>
					--Make sure that new data is available
					if r_avail = '0' then
						v_avail := '0';	--v_avail can only go low in this state, indicating that new data is ready
					end if;
					
					if o_rdy = '1' then
						r_out <= '0';
						o_valid <= '0';
						if v_avail = '0' then	--Make sure that new data is ready instead of old data
							r_C2_State <= 0;
						end if;
					end if;
					
			end case;
		end if;
	end process p_Controller_2;
	
	--The datapath is the FIR filter
	p_Datapath : process(CLK, RST)
		variable v_Out : signed(7 downto 0);
	begin
		if RST = '1' then
			r_Data <= (others => x"00");
			d_out <= (others => 'Z');
		elsif rising_edge(CLK) then
			if r_LD_Active = '1' then
				--arithmetic shift
				r_Data(0)(7) <= d_in(7);
				r_Data(0)(6) <= '0';
				r_Data(0)(5 downto 0) <= d_in(6 downto 1);
				
				--arithmetic shift
				r_Data(1)(7) <= r_Data(0)(7);
				r_Data(1)(6) <= '0';
				r_Data(1)(5 downto 0) <= r_Data(0)(6 downto 1);
				
				r_Data(2) <= r_Data(1);
				r_Data(3) <= r_Data(2);
				r_Data(4) <= not(r_Data(3)) + x"01";	--Negate
			end if;
			
			--Sum r_Data into v_Out
			v_Out := x"00";
			for i in 0 to 4 loop
					v_Out := v_Out + r_Data(i);
			end loop;
			--Register v_Out
			if r_cpd = '1' then
				r_Data_Out <= v_Out;
			end if;
			
			--Output registered data
			if r_out = '1' then
				d_out <= r_Data_Out;
			else
				d_out <= (others => 'Z');
			end if;
		end if;
	end process p_Datapath;
	
end architecture RTL;