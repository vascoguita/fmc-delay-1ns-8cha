-----------------------------------------------------------------------------
-- Title      : SPI Bus Master with arbitration
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_spi_dac_arbiter.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2014-03-17
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: A simple SPI master with built-in arbitration mechanism for
-- multiplexing accesses between the FD software driver (host) and the SoftPLL
-- in the associated WR core controlling the oscillator tuning DAC.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2011 CERN / BE-CO-HT
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2011-08-24  1.0      twlostow        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.fd_main_wbgen2_pkg.all;



entity fd_spi_dac_arbiter is
  
  generic (
    g_div_ratio_log2 : integer := 2);

  port(
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    -- DAC value (valid when tm_dac_wr_i == 1)
    tm_dac_value_i : in std_logic_vector(31 downto 0);
    tm_dac_wr_i    : in std_logic;


    ---------------------------------------------------------------------------
    -- SPI Bus
    ---------------------------------------------------------------------------

    -- chip select for VCTCXO DAC
    spi_cs_dac_n_o : out std_logic;

    -- chip select for AD9516 PLL
    spi_cs_pll_n_o : out std_logic;

    -- chip select for MCP23S17 GPIO
    spi_cs_gpio_n_o : out std_logic;

    -- these are obvious
    spi_sclk_o : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic;

    regs_i : in  t_fd_main_out_registers;
    regs_o : out t_fd_main_in_registers
    );

end fd_spi_dac_arbiter;

architecture behavioral of fd_spi_dac_arbiter is

  component fd_spi_master
    generic (
      g_div_ratio_log2 : integer);
    port (
      clk_sys_i       : in  std_logic;
      rst_n_i         : in  std_logic;
      start_i         : in  std_logic;
      cpol_i          : in  std_logic;
      data_i          : in  std_logic_vector(23 downto 0);
      sel_dac_i       : in  std_logic;
      sel_pll_i       : in  std_logic;
      sel_gpio_i      : in  std_logic;
      ready_o         : out std_logic;
      data_o          : out std_logic_vector(23 downto 0);
      spi_cs_dac_n_o  : out std_logic;
      spi_cs_pll_n_o  : out std_logic;
      spi_cs_gpio_n_o : out std_logic;
      spi_sclk_o      : out std_logic;
      spi_mosi_o      : out std_logic;
      spi_miso_i      : in  std_logic);
  end component;

  signal s_start    : std_logic;
  signal s_data_in  : std_logic_vector(23 downto 0);
  signal s_data_out : std_logic_vector(23 downto 0);
  signal s_sel_dac  : std_logic;
  signal s_sel_pll  : std_logic;
  signal s_sel_gpio : std_logic;
  signal s_ready    : std_logic;

  type t_spi_request is
  record
    pending  : std_logic;
    granted  : std_logic;
    grant    : std_logic;
    done     : std_logic;
    data     : std_logic_vector(23 downto 0);
    sel_pll  : std_logic;
    sel_dac  : std_logic;
    sel_gpio : std_logic;
  end record;

  signal rq_host, rq_pll : t_spi_request;

  signal prev_rq : std_logic;

  type t_arb_state is (WAIT_RQ, SERVE_RQ);
  signal state   : t_arb_state;
  signal granted : std_logic_vector(1 downto 0);

  signal scr_data_in : std_logic_vector(23 downto 0);
begin  -- behavioral


  p_data_in : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        scr_data_in <= (others => '0');
      else
        if(regs_i.scr_data_load_o = '1') then
          scr_data_in <= regs_i.scr_data_o;
        end if;
      end if;
    end if;
  end process;

-- FIXME: this could be probably rewritten in a more elegant way
  p_rq_host : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        rq_host.pending    <= '0';
        rq_host.data       <= (others => '0');
        rq_host.sel_dac    <= '0';
        rq_host.sel_pll    <= '0';
        rq_host.sel_gpio   <= '0';
       regs_o.scr_ready_i <= '1';
        
     else
       if(regs_i.scr_start_o = '1' and rq_host.pending = '0') then
         rq_host.pending    <= '1';
         rq_host.data       <= scr_data_in;
         rq_host.sel_pll    <= regs_i.scr_sel_pll_o;
         rq_host.sel_dac    <= regs_i.scr_sel_dac_o;
         rq_host.sel_gpio   <= regs_i.scr_sel_gpio_o;
         regs_o.scr_ready_i <= '0';
       elsif(rq_host.done = '1') then
         regs_o.scr_ready_i <= '1';
         rq_host.pending    <= '0';
       end if;
     end if;
   end if;
  end process;

  rq_pll.sel_gpio <= '0';
  rq_pll.sel_dac  <= '1';
  rq_pll.sel_pll  <= '0';

  p_rq_pll : process(clk_sys_i)
  begin
   if rising_edge(clk_sys_i) then
     if rst_n_i = '0' then
       rq_pll.pending <= '0';
       rq_pll.data    <= (others => '0');
     else
       if(tm_dac_wr_i = '1' and regs_i.tcr_wr_enable_o = '1' and rq_pll.pending = '0') then
         rq_pll.pending <= '1';
         rq_pll.data    <= tm_dac_value_i(23 downto 0);
       elsif(rq_pll.done = '1') then
         rq_pll.pending <= '0';
       end if;
     end if;
   end if;
  end process;

  p_grant : process(prev_rq, rq_pll, rq_host)
  begin
   if(rq_pll.pending = '1' and rq_host.pending = '0') then
     rq_pll.grant  <= '1' and not rq_pll.done;
     rq_host.grant <= '0';
   elsif (rq_pll.pending = '0' and rq_host.pending = '1') then
     rq_pll.grant  <= '0';
     rq_host.grant <= '1' and not rq_host.done;
   elsif (rq_pll.pending = '1' and rq_host.pending = '1') then
     rq_pll.grant  <= prev_rq and not rq_pll.done;
     rq_host.grant <= not prev_rq and not rq_host.done;
   else
     rq_pll.grant  <= '0';
     rq_host.grant <= '0';
   end if;
  end process;

  p_arbitrate : process(clk_sys_i)
  begin
   if rising_edge(clk_sys_i) then
     if rst_n_i = '0' then
        
       state      <= WAIT_RQ;
       s_start    <= '0';
       s_data_in  <= (others => '0');
       s_sel_gpio <= '0';
       s_sel_pll  <= '0';
       s_sel_dac  <= '0';
              regs_o.scr_data_i  <= (others => '0');

     else
       case state is
         when WAIT_RQ =>
           rq_pll.done  <= '0';
           rq_host.done <= '0';

           rq_pll.granted  <= rq_pll.grant;
           rq_host.granted <= rq_host.grant;


           if(rq_pll.grant = '1')then
             prev_rq    <= '0';
             s_start    <= '1';
             s_data_in  <= rq_pll.data;
             s_sel_dac  <= rq_pll.sel_dac;
             s_sel_pll  <= rq_pll.sel_pll;
             s_sel_gpio <= rq_pll.sel_gpio;
             state      <= SERVE_RQ;
           elsif(rq_host.grant = '1') then
             prev_rq    <= '1';
             s_start    <= '1';
             s_data_in  <= rq_host.data;
             s_sel_dac  <= rq_host.sel_dac;
             s_sel_pll  <= rq_host.sel_pll;
             s_sel_gpio <= rq_host.sel_gpio;
             state      <= SERVE_RQ;
           end if;

         when SERVE_RQ =>

           if(s_ready = '1' and s_start = '0') then
             state        <= WAIT_RQ;
             rq_host.done <= rq_host.granted;
             rq_pll.done  <= rq_pll.granted;
             if(rq_host.granted = '1') then
               regs_o.scr_data_i <= s_data_out;
             end if;
           end if;
           s_start <= '0';

       end case;
     end if;
    end if;

  end process;

  U_SPI_Master : fd_spi_master
    generic map (
      g_div_ratio_log2 => g_div_ratio_log2)
    port map (
      clk_sys_i       => clk_sys_i,
      rst_n_i         => rst_n_i,
      start_i         => s_start,
      cpol_i          => regs_i.scr_cpol_o,
      data_i          => s_data_in,
      sel_dac_i       => s_sel_dac,
      sel_pll_i       => s_sel_pll,
      sel_gpio_i      => s_sel_gpio,
      ready_o         => s_ready,
      data_o          => s_data_out,
      spi_cs_dac_n_o  => spi_cs_dac_n_o,
      spi_cs_pll_n_o  => spi_cs_pll_n_o,
      spi_cs_gpio_n_o => spi_cs_gpio_n_o,
      spi_sclk_o      => spi_sclk_o,
      spi_mosi_o      => spi_mosi_o,
      spi_miso_i      => spi_miso_i);


end behavioral;

