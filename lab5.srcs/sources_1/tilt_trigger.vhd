----------------------------------------------------------------------------------
--
-- Author: Todd Blackmon
--
-- Description:
-- This entity generates up, down, left, right pulses from the X,Y axis tilt
-- measurements.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tilt_adjust is
    Port ( clk : in std_logic;
           rst : in std_logic;
           data_x : in std_logic_vector (7 downto 0);
           data_y : in std_logic_vector (7 downto 0);
           up : out std_logic;
           down : out std_logic;
           left : out std_logic;
           right : out std_logic);
end tilt_adjust;

architecture Behavioral of tilt_adjust is
    constant thresh : integer := 24;        -- Threshold from 0 to adjust
    constant hyst : integer := 8;           -- Hysteresis to avoid double pulsing.

    -- Internal state of the row and col
    signal i_row : unsigned (3 downto 0);
    signal i_col : unsigned (4 downto 0);
    
    -- Current tilted state
    signal up_st : std_logic;
    signal down_st : std_logic;
    signal left_st : std_logic;
    signal right_st : std_logic;

    -- So we don't have to cast to signed so much.
    signal sx : signed (7 downto 0);
    signal sy : signed (7 downto 0);


begin
    sx <= signed (data_x);
    sy <= signed (data_y);

    process (clk, rst)
    begin
        if rst = '1' then
            up_st <= '0';
            down_st <= '0';
            left_st <= '0';
            right_st <= '0';
        elsif rising_edge(clk) then
            up <= '0';
            down <= '0';
            left <= '0';
            right <= '0';

            -- Up (is negative X on accelerometer)
            if sx < to_signed (-thresh, 8) then
                up_st <= '1';
                up <= not up_st;
            elsif sx > to_signed (-thresh+hyst, 8) then
                up_st <= '0';
            end if;

            -- Down (is positive X on accelerometer)
            if sx > to_signed (thresh, 8) then
                down_st <= '1';
                down <= not down_st;
            elsif sx < to_signed (thresh-hyst, 8) then
                down_st <= '0';
            end if;

            -- Left (is positive Y on accelerometer)
            if sy > to_signed (thresh, 8) then
                left_st <= '1';
                left <= not left_st;
            elsif sy < to_signed (thresh-hyst, 8) then
                left_st <= '0';
            end if;

            -- Right (is negative Y on accelerometer)
            if sy < to_signed (-thresh, 8) then
                right_st <= '1';
                right <= not right_st;
            elsif sy > to_signed (-thresh+hyst, 8) then
                right_st <= '0';
            end if;
        end if;
    end process;

end Behavioral;
