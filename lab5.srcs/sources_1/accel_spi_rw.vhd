----------------------------------------------------------------------------------
--
-- Author: Todd Blackmon
--
-- Description:
-- Accelerometer access module using SPI
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.all;

entity accel_spi_rw is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        -- Values from accelerometer used for movement and display
        data_x : out STD_LOGIC_VECTOR (7 downto 0);
        data_y : out STD_LOGIC_VECTOR (7 downto 0);
        data_z : out STD_LOGIC_VECTOR (7 downto 0);
        id_ad  : out STD_LOGIC_VECTOR (7 downto 0);
        id_id  : out STD_LOGIC_VECTOR (7 downto 0);
        -- SPI signals between FPGA and accelerometer
        csb  : out STD_LOGIC;
        mosi : out STD_LOGIC;
        sclk : out STD_LOGIC;
        miso : in STD_LOGIC);
end accel_spi_rw;

architecture Behavioral of accel_spi_rw is
    type state_type is (INIT, WR_PWR_CTL, RD_ID_AD, RD_ID_ID, RD_XDATA, RD_YDATA, RD_ZDATA);
    signal state : state_type;
    
    signal spi_req, spi_done : std_logic;
    signal rwb : std_logic;
    signal addr : std_logic_vector (7 downto 0);
    signal din : std_logic_vector (7 downto 0);
    signal dout : std_logic_vector (7 downto 0);
begin

    process (clk, rst)
    begin
        if rst = '1' then
            state <= INIT;
            spi_req <= '0';
            data_x <= X"00";                
            data_y <= X"00";
            data_z <= X"00";
            id_ad <= X"00";
            id_id <= X"00";
        elsif rising_edge (clk) then
            spi_req <= '0'; -- This makes the pulse only one clock wide.

            -- We always immediately start the next after the last finishes     
            if spi_done = '1' then
                spi_req <= '1';
            end if;
        
            case state is
            when INIT =>
                -- Setup next transaction
                rwb <= '0';
                addr <= X"2D";
                din <= X"02";
                -- Start the transaction
                spi_req <= '1'; -- First transaction
                state <= WR_PWR_CTL;
            when WR_PWR_CTL =>
                if spi_done = '1' then
                    rwb <= '1';
                    addr <= X"00";
                    din <= X"00";
                    state <= RD_ID_AD;
                end if;
            when RD_ID_AD =>
                if spi_done = '1' then
                    id_ad <= dout;
                    addr <= X"01";
                    state <= RD_ID_ID;
                end if;
            when RD_ID_ID =>
                if spi_done = '1' then
                    id_id <= dout;
                    addr <= X"08";
                    state <= RD_XDATA;
                end if;
            when RD_XDATA =>
                if spi_done = '1' then
                    data_x <= dout;
                    addr <= X"09";
                    state <= RD_YDATA;
                end if;
            when RD_YDATA =>
                if spi_done = '1' then
                    data_y <= dout;
                    addr <= X"0A";
                    state <= RD_ZDATA;
                end if;
            when RD_ZDATA =>
                if spi_done = '1' then
                    data_z <= dout;
                    addr <= X"00";
                    state <= RD_ID_AD;
                end if;
            end case;
        end if;
    end process;

    -- SPI controller actually performs transactions
    spi: entity spi_controller port map (
        clk => clk, rst => rst, 
        spi_req => spi_req, spi_done => spi_done, 
        rwb => rwb, addr => addr, din => din,
        dout => dout,
        miso => miso, mosi => mosi, sclk => sclk, csb => csb);


end Behavioral;
