library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_textio.all;
use work.all;

entity delay_tb is
end entity delay_tb;

architecture sim of delay_tb is

	signal clk100 : std_logic := '0';
	signal reset : std_logic;
	signal dly_start, dly_done : std_logic;
	
begin

	process
	begin
		clk100 <= not clk100;
		wait for 5 ns;
	end process;
	
	process
	begin
	   dly_start <= '0';
		reset <= '1';
		wait for 100 ns;
		reset <= '0';
        wait for 10 ns;
        dly_start <= '1';
        wait for 10 ns;
        dly_start <= '0';
        wait for 490 ns;
        dly_start <= '1';
        wait for 10 ns;
        dly_start <= '0';
        wait for 500 ns;
        dly_start <= '1';
        wait for 10 ns;
        dly_start <= '0';
        
		wait;
	end process;

	
    dly_dut : entity delay port map (
        clk => clk100,
        rst => reset,
        dly_start => dly_start,
        dly_done => dly_done);

end sim;
