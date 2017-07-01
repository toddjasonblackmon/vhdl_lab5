----------------------------------------------------------------------------------
--
-- Author: Todd Blackmon
--
-- Description:
-- Lab 5 top level displays a green & blue checkerboard pattern using VGA while
-- adding a movable red cursor block. The 7 segment controller provides another
-- view of the location of the cursor. In addition some switch settings are
-- available to make the red cursor block controllable via push buttons or by
-- the tilt of the on-board accelerometer.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utility.all;
use work.all;

entity lab5_top is
    generic (debounce_limit: natural := 5000000);
    Port ( CLK100MHZ : in STD_LOGIC;
           RST_PIN : in STD_LOGIC;
           CTRL_SW : in STD_LOGIC;
           DISP_SW : in STD_LOGIC_VECTOR (1 downto 0);
           BTNU : in STD_LOGIC;
           BTNL : in STD_LOGIC;
           BTND : in STD_LOGIC;
           BTNR : in STD_LOGIC;
           VGA_R : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_G : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_B : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_HS : out STD_LOGIC;
           VGA_VS : out STD_LOGIC;
           AN : out STD_LOGIC_VECTOR (7 downto 0);
           SEG7_CATH : out STD_LOGIC_VECTOR (7 downto 0);
           ACL_MISO : in STD_LOGIC;
           ACL_MOSI : out STD_LOGIC;
           ACL_SCLK : out STD_LOGIC;
           ACL_CSN : out STD_LOGIC);

end lab5_top;

architecture Behavioral of lab5_top is
    signal clk : std_logic;
    signal rst : std_logic;
    signal cursor_row : std_logic_vector (3 downto 0);
    signal cursor_col : std_logic_vector (4 downto 0);
    signal seg7_disp_value : std_logic_vector (31 downto 0);
    signal up, down, left, right : std_logic;
    signal btn_up, btn_down, btn_left, btn_right : std_logic;
    signal accel_up, accel_down, accel_left, accel_right : std_logic;
    signal rst_s1 : std_logic;
    
    signal pix_r, pix_g, pix_b : std_logic_vector (3 downto 0);
    signal row : std_logic_vector (8 downto 0);
    signal col : std_logic_vector (9 downto 0);

    signal data_x, data_y, data_z : std_logic_vector (7 downto 0);
    signal id_ad, id_id : std_logic_vector (7 downto 0);

begin
    -- Internal signal rename
    clk <= CLK100MHZ;

    -- Async enable reset, synchronous disable
    -- Purpose is to ensure that all flops come out 
    -- of reset on same clock.
    process (clk, RST_PIN)
    begin
        if RST_PIN = '1' then
            rst_s1 <= '1';
            rst <= '1';
        elsif rising_edge(clk) then
            rst_s1 <= '0';
            rst <= rst_s1;
        end if;
    end process; 

    -- Button debounce
    dbnc_u : entity debounce
        generic map (debounce_limit => debounce_limit) 
        port map (clk => clk, rst => rst, btn => BTNU, pulse => btn_up);
        
    dbnc_d : entity debounce
        generic map (debounce_limit => debounce_limit)
        port map (clk => clk, rst => rst, btn => BTND, pulse => btn_down);
        
    dbnc_l : entity debounce
        generic map (debounce_limit => debounce_limit)
        port map (clk => clk, rst => rst, btn => BTNL, pulse => btn_left);
        
    dbnc_r : entity debounce
        generic map (debounce_limit => debounce_limit) 
        port map (clk => clk, rst => rst, btn => BTNR, pulse => btn_right);

    up <= btn_up when CTRL_SW = '0' else accel_up;
    down <= btn_down when CTRL_SW = '0' else accel_down;
    left <= btn_left when CTRL_SW = '0' else accel_left;
    right <= btn_right when CTRL_SW = '0' else accel_right;

    -- This block handles cursor location adjustment
    c_adj : entity cursor_adjust port map (
        clk => clk,
        rst => rst,
        up => up,
        down => down,
        left => left,
        right => right,
        col => cursor_col,
        row => cursor_row
    );

    -- The first 2 bytes are selected with DISP_SW
    -- The third byte is the cursor column.
    -- The last byte is the cursor row.
    with DISP_SW select
        seg7_disp_value(31 downto 16) <= 
            (id_id & id_ad) when "00",
            (X"00" & data_x) when "01",
            (X"00" & data_y) when "10",
            (X"00" & data_z) when "11";
    
    seg7_disp_value(15 downto 8) <= "000" & std_logic_vector(cursor_col);
    seg7_disp_value(7 downto 0) <= "0000" & std_logic_vector(cursor_row);

    -- The 7 segment controller displays the cursor position
    s7_ctrl : entity seg7_controller port map (
        clk => CLK100MHZ,
        rst => rst,
        display_value => seg7_disp_value, 
        an => AN,
        cath => SEG7_CATH
    );

    -- Pixel generator
    process (row, col, cursor_col, cursor_row)
    begin
        pix_r <= "0000";
        pix_g <= "0000";
        pix_b <= "0000";
    
        -- The cursor is given priority
        -- The cursor position is in grid units, so some slicing is needed.
        if ((row(8 downto 5) = cursor_row) and 
            (col(9 downto 5) = cursor_col)) then
            pix_r <= "1111";
            
        -- Otherwise do a 32-pixel green-blue checkerboard pattern.            
        elsif ((row(5) xor col(5)) = '1') then
            pix_b <= "1111";
        else
            pix_g <= "1111";
        end if;
    end process;

    -- VGA controller
    vga : entity vga_controller port map (
        clk => CLK100MHZ,
        rst => rst,
        pix_r => pix_r, pix_g => pix_g, pix_b => pix_b,
        row => row, col => col,
        RED => VGA_R, GRN => VGA_G, BLU => VGA_B,
        VSYNC => VGA_VS, HSYNC => VGA_HS);

     accel : entity accel_spi_rw port map (
        clk => clk,
        rst => rst,
        data_x => data_x, 
        data_y => data_y,
        data_z => data_z,
        id_ad => id_ad,
        id_id => id_id,
        csb => ACL_CSN,
        mosi => ACL_MOSI,
        sclk => ACL_SCLK,
        miso => ACL_MISO);

    tilt : entity tilt_adjust port map (
        clk => clk,
        rst => rst,
        data_x => data_x,
        data_y => data_y,
        up => accel_up,
        down => accel_down,
        left => accel_left,
        right => accel_right);

end Behavioral;


