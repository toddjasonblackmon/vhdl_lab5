----------------------------------------------------------------------------------
--
-- Author: Todd Blackmon
--
-- Description:
-- Testbench module for the spi_controller module.
--
----------------------------------------------------------------------------------


library IEEE;
library utility;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.all;
use work.utility.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity spi_controller_tb is
end spi_controller_tb;

architecture testbench of spi_controller_tb is
    signal clk : std_logic;
    signal rst : std_logic;
    signal spi_req : std_logic;
    signal spi_done : std_logic;
    signal rwb : std_logic;
    signal addr : std_logic_vector (7 downto 0);
    signal din : std_logic_vector (7 downto 0);
    signal dout : std_logic_vector (7 downto 0);
    signal miso : std_logic;
    signal mosi : std_logic;
    signal sclk : std_logic;
    signal csb : std_logic;
    signal acl_enabled : std_logic;
    
    signal sim_run : std_logic := '1';
begin

    process
    begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        
        if (sim_run = '0') then
            wait;
        end if;
        
    end process;

    process
        file data_fp : text open read_mode is "spi_tb.dat";
        variable sample : line;
        variable t : time;
        variable rst_var : std_logic;
        variable out_valid : std_logic;
        variable spi_req_var, rwb_var : std_logic;
        variable addr_var, din_var : std_logic_vector (7 downto 0);   
        variable acl_en_var : std_logic;    
        variable dout_var : std_logic_vector (7 downto 0);
    begin
        while not endfile (data_fp) loop
            readline (data_fp, sample);
            read (sample, t);
            read (sample, rst_var);
            read (sample, spi_req_var);
            read (sample, rwb_var);
            hread (sample, addr_var);
            hread (sample, din_var);
            read (sample, out_valid);
            if (out_valid = '1') then
                read (sample, acl_en_var);
                hread (sample, dout_var);
            end if;
            
            wait for t;
            
            -- Drive inputs
            rst <= rst_var;
            spi_req <= spi_req_var;
            rwb <= rwb_var;
            addr <= addr_var;
            din <= din_var;
            
            if (out_valid = '1') then   
                assert acl_enabled = acl_en_var report "acl_enabled does not match" severity Error;
                assert dout = dout_var report "dout does not match" severity Error;
            end if;
        end loop;
        sim_run <= '0';
        report "Simulation successful"; 
        wait;
   end process;
    
    ACL_DUMMY : entity acl_model port map (
        rst => rst,
        ACL_CSN => csb, 
        ACL_MOSI => mosi,
        ACL_SCLK => sclk,
        ACL_MISO => miso,
        --- ACCEL VALUES ---
        X_VAL => x"12",
        Y_VAL => x"34",
        Z_VAL => x"AB",
        --- ACCEL STATE ---
        acl_enabled => acl_enabled
        );

    CUT: entity spi_controller port map (
            clk, rst, spi_req, spi_done, 
            rwb, addr, din, dout,
            miso, mosi, sclk, csb);

end testbench;
