----------------------------------------------------------------------------------
--
-- Author: Todd Blackmon
--
-- Description:
-- Lab 5 top level for playing with timing constraints
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lab5_top is
    Port ( CLK100MHZ : in STD_LOGIC;
           SW : in STD_LOGIC;
           ACL_MISO : in STD_LOGIC;
           ACL_MOSI : out STD_LOGIC;
           ACL_SCLK : out STD_LOGIC;
           ACL_CSN : out STD_LOGIC;
           LED : out STD_LOGIC);
end lab5_top;

architecture Behavioral of lab5_top is
    signal clk, rst : std_logic;
    signal byte_cnt : unsigned (2 downto 0);
    signal spi_cnt : unsigned (6 downto 0);
    signal i_sclk : std_logic;    
begin
    -- For consistent internal names
    clk <= CLK100MHZ;
    rst <= SW;

    process (clk, rst)
    begin
        if (rst = '1') then
            spi_cnt <= to_unsigned(0,7);
            i_sclk <= '0';
            ACL_MOSI <= '0';
            ACL_CSN <= '1';
            LED <= '0';
            byte_cnt <= "000";
        elsif (rising_edge (clk)) then
            spi_cnt <= spi_cnt + 1;
            
            if (spi_cnt = to_unsigned(99,7)) then
                i_sclk <= '1';
                spi_cnt <= to_unsigned(0,7);
                LED <= ACL_MISO;            -- Latch the returned data on the rising edge.
                byte_cnt <= byte_cnt + 1;
                if (byte_cnt = "111") then
                    ACL_CSN <= '0';
                else
                    ACL_CSN <= '1';
                end if;
                
            elsif (spi_cnt = to_unsigned(49,7)) then
                ACL_MOSI <= byte_cnt(0);   -- Change the sent data on the falling edge.
                i_sclk <= '0';
            end if;
        end if;
    end process;

    ACL_SCLK <= i_sclk;

end Behavioral;
