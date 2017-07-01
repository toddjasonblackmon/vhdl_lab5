library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_textio.all;
use work.all;

entity spi_tb is
end entity spi_tb;

architecture sim of spi_tb is

	signal clk100 : std_logic := '0';
	signal reset : std_logic;
	
	signal id_ad, id_id, data_x, data_y, data_z : std_logic_vector (7 downto 0);
	
	signal ACL_CSN, ACL_MOSI, ACL_SCLK, ACL_MISO : std_logic;

    signal x_val, y_val, z_val : std_logic_vector (7 downto 0);
begin

	process
	begin
		clk100 <= not clk100;
		wait for 5 ns;
	end process;
	
	process
	begin
	   x_val <= X"12";
	   y_val <= X"34";
	   z_val <= X"56";
		reset <= '1';
		wait for 100 ns;
		reset <= '0';
		wait for 300 us;
		x_val <= X"A5";
		y_val <= X"B4";
		z_val <= X"C3";
		wait;
	end process;
	
	ACL_DUMMY : entity acl_model port map (
		rst => reset,
		ACL_CSN => ACL_CSN, 
		ACL_MOSI => ACL_MOSI,
		ACL_SCLK => ACL_SCLK,
		ACL_MISO => ACL_MISO,
		--- ACCEL VALUES ---
		X_VAL => x_val,
		Y_VAL => y_val,
		Z_VAL => z_val);
	
	ACEL_DUT : entity accel_spi_rw port map (
		clk => clk100,
		rst =>  reset,
		-- Values from accelerometer
		data_x => data_x,
		data_y => data_y,
		data_z => data_z,
		id_ad => id_ad,
		id_id => id_id,
		--SPI Signals
		csb => ACL_CSN,
		mosi => ACL_MOSI,
		sclk => ACL_SCLK,
		miso => ACL_MISO);

end sim;
