----------------------------------------------------------------------------------
--
-- Author: Todd Blackmon
--
-- Description:
-- Spi master bus controller
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.all;

entity spi_controller is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           spi_req : in STD_LOGIC;                   -- Pulse to start spi transaction
           spi_done : out STD_LOGIC;                 -- Pulse to indicate completion
           rwb : in STD_LOGIC;                       -- 1 = read, 0 = write, valid during spi_req
           addr : in STD_LOGIC_VECTOR (7 downto 0);  -- addr of transaction, valid during spi_req
           din : in STD_LOGIC_VECTOR (7 downto 0);   -- data to write, valid during spi_req
           dout : out STD_LOGIC_VECTOR (7 downto 0); -- data read, valid during spi_done
           -- SPI BUS
           miso : in STD_LOGIC;
           mosi : out STD_LOGIC;
           sclk : out STD_LOGIC;
           csb : out STD_LOGIC);
end spi_controller;

architecture Behavioral of spi_controller is
    constant RD_CMD : std_logic_vector (7 downto 0) := X"0B";
    constant WR_CMD : std_logic_vector (7 downto 0) := X"0A";
    type state_type is (INIT, CS_FALL, CS_RISE, SCLK_FALL, SCLK_LOW, SCLK_RISE, SCLK_HIGH);
    signal state : state_type;
    signal dly_start, dly_done : std_logic;
    signal i_dout : std_logic_vector (7 downto 0);
    signal count : unsigned (4 downto 0);
    signal dat : std_logic_vector (23 downto 0);
begin

    dly : entity delay port map (
            clk => clk,
            rst => rst,
            dly_start => dly_start,
            dly_done => dly_done);

    process (clk, rst) 
    begin
        if rst = '1' then
            state <= INIT;
            spi_done <= '0';
            dly_start <= '0';
            csb <= '1';
            sclk <= '0';
            mosi <= '0';
            i_dout <= X"00";
            count <= (others => '0');
            dat <= (others => '0');
        elsif rising_edge (clk) then
            dly_start <= '0';   -- This makes dly_start a one-clock wide pulse.
            
            case state is
            when INIT =>    -- Waiting for spi_req to start transaction
                spi_done <= '0'; 
                count <= to_unsigned (24, 5);
                if rwb = '1' then   -- Read
                    dat <= RD_CMD & addr & X"00";
                else -- Write
                    dat <= WR_CMD & addr & din;
                end if;                
            
                if spi_req = '1' then
                    state <= CS_FALL;   -- Drop the CS immediately
                    dly_start <= '1';   -- Start the timer as we enter the state.
                end if; 

            when CS_FALL => -- Lower the CS signal
                csb <= '0';
                
                if dly_done = '1' then
                    state <= SCLK_FALL;
                    dly_start <= '1';
                end if;
                        
            -- On first time, the sclk is already low, but MOSI data is needed.
            -- On last time, MOSI is driven to a 0 that was shifted in.
            when SCLK_FALL =>
                sclk <= '0';
                mosi <= dat(23);
                dat <= dat (22 downto 0) & '0';
                state <= SCLK_LOW;

            -- Waiting for timer before rising edge
            when SCLK_LOW =>
                if dly_done = '1' then
                    if count = to_unsigned (0, 5) then
                        state <= CS_RISE;   -- On last cycle raise csn instead.
                                            -- No dly needed here. We're done!
                    else
                        state <= SCLK_RISE; -- On others raise the sclk.
                        dly_start <= '1';
                    end if;
                end if;

            when SCLK_RISE =>
                sclk <= '1';
                i_dout <= i_dout (6 downto 0) & miso;   -- Latch miso on rising edge.
                count <= count - 1;                     -- Only the last 7 bits (data) are saved.
                state <= SCLK_HIGH;
                
            -- Waiting for timer before falling edge
            when SCLK_HIGH =>
                if dly_done = '1' then
                    state <= SCLK_FALL;
                    dly_start <= '1';
                end if;

            when CS_RISE =>
                csb <= '1';         -- Set the CS.
                spi_done <= '1';    -- One clock width pulse started.
                state <= INIT;      -- Back to waiting.
            end case;
        end if;
    end process;
    
    dout <= i_dout;
    
end Behavioral;
