----------------------------------------------------------------------------------
--
-- Author: Todd Blackmon
--
-- Description:
-- Delay module accepts a pulse and produces a delayed version after dly_clks.
--              |<------ dly_clks ------->|
--             _                          |
-- dly_start _| |___________//____       _|
-- dly_done  _______________//__________| |_____
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity delay is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        dly_start : in STD_LOGIC;
        dly_done : out STD_LOGIC);
end delay;

architecture Behavioral of delay is
    constant dly_clks : natural := 49;
    signal count : unsigned (5 downto 0);
    signal run : std_logic;
begin

    process (clk, rst)
    begin
        if (rst = '1') then
            dly_done <= '0';
            run <= '0';
            count <= (others => '0');
        elsif (rising_edge (clk)) then
            dly_done <= '0';
        
            if dly_start = '1' then
                run <= '1';
                count <= (others => '0');
            end if;
            
            -- We count if 'running'
            if run = '1' then
                count <= count + 1;
            end if;
            
            -- Pulse done after correct number of clocks.
            -- Count 0 to dly - 1 for dly_clks, but
            -- counts one less to account for pulse detection delay.
            if count = to_unsigned(dly_clks - 2, 6) then
                run <= '0';
                dly_done <= '1';
            end if;
        end if;
    end process;

end Behavioral;
