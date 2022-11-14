-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

-----------------------------------------------------------------------------
-- Title      : SPI Bus Master
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_spi_master.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-02-26
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Just a simple SPI master.
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
use ieee.numeric_std.all;

entity fd_spi_master is
  generic(
    -- clock division ratio (SCLK = clk_sys_i / (2 ** g_div_ratio_log2).
    g_div_ratio_log2 : integer := 2);
  port (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    -- 1: start next transfer (using CPOL, DATA and SEL from the inputs below)
    start_i    : in  std_logic;
    -- Clock polarity: 1: slave clocks in the data on rising SCLK edge, 0: ...
    -- on falling SCLK edge
    cpol_i     : in  std_logic;
    -- TX Data input (fixed to 24 bits)
    data_i     : in  std_logic_vector(23 downto 0);
    -- Peripheral selects (VCTCXO DAC, AD9516 PLL, MCP23S17 GPIO)
    sel_dac_i  : in  std_logic;
    sel_pll_i  : in  std_logic;
    sel_gpio_i : in  std_logic;
    ready_o    : out std_logic;

    -- data read from selected slave, valid when ready_o == 1.
    data_o     : out std_logic_vector(23 downto 0);


    -- chip select for VCTCXO DAC
    spi_cs_dac_n_o : out std_logic;

    -- chip select for AD9516 PLL
    spi_cs_pll_n_o : out std_logic;

    -- chip select for MCP23S17 GPIO
    spi_cs_gpio_n_o : out std_logic;

    -- these are obvious
    spi_sclk_o : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic
    );

end fd_spi_master;

architecture behavioral of fd_spi_master is

  signal busy : std_logic;

  signal divider       : unsigned(11 downto 0);
  signal divider_muxed : std_logic;

  signal sreg    : std_logic_vector(23 downto 0);
  signal rx_sreg : std_logic_vector(23 downto 0);

  type   t_state is (IDLE, TX_CS, TX_DAT1, TX_DAT2, TX_SCK1, TX_SCK2, TX_CS2, TX_GAP, TX_DUMMY_CK1, TX_DUMMY_CK2);
  signal state : t_state;
  signal sclk  : std_logic;

  signal counter : unsigned(4 downto 0);
  
begin  -- rtl

  process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        divider <= (others => '0');
      else
        if(start_i = '1' or divider_muxed = '1') then
          divider <= (others => '0');
        else
          divider <= divider + 1;
        end if;
      end if;
    end if;
  end process;

  divider_muxed <= divider(g_div_ratio_log2);  -- sclk = clk_i/64


  process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        state           <= IDLE;
        sclk            <= '0';
        spi_cs_gpio_n_o <= '1';
        spi_cs_pll_n_o  <= '1';
        spi_cs_dac_n_o  <= '1';
        sreg            <= (others => '0');
        rx_sreg         <= (others => '0');
        spi_mosi_o      <= '0';
        counter         <= (others => '0');
      else
        case state is
          when IDLE =>
            sclk    <= '0';
            counter <= (others => '0');
            if(start_i = '1') then
              sreg            <= data_i;
              state           <= TX_CS;
              spi_cs_dac_n_o  <= not sel_dac_i;
              spi_cs_pll_n_o  <= not sel_pll_i;
              spi_cs_gpio_n_o <= not sel_gpio_i;
              spi_mosi_o      <= data_i(sreg'high);
            end if;

          when TX_CS =>
            if divider_muxed = '1' then
              state <= TX_DAT1;
            end if;

          when TX_DAT1 =>
            if(divider_muxed = '1') then
              spi_mosi_o <= sreg(sreg'high);
              sreg       <= sreg(sreg'high-1 downto 0) & '0';
              state      <= TX_SCK1;
            end if;
            
          when TX_SCK1 =>
            if(divider_muxed = '1') then
              sclk    <= not sclk;
              counter <= counter + 1;
              state   <= TX_DAT2;
            end if;

          when TX_DAT2 =>

            if(divider_muxed = '1') then
              rx_sreg <= rx_sreg(rx_sreg'high-1 downto 0) & spi_miso_i;
              state   <= TX_SCK2;
            end if;
            
          when TX_SCK2 =>
            if(divider_muxed = '1') then
              sclk <= not sclk;
              if(counter = 24) then
                state <= TX_CS2;
              else
                state <= TX_DAT1;
              end if;
            end if;

          when TX_CS2 =>
            if(divider_muxed = '1') then
              state           <= TX_DUMMY_CK1;
              spi_cs_gpio_n_o <= '1';
              spi_cs_pll_n_o  <= '1';
              spi_cs_dac_n_o  <= '1';
              data_o          <= rx_sreg;
            end if;

          when TX_DUMMY_CK1 =>
            if(divider_muxed = '1') then
              sclk  <= not sclk;
              state <= TX_DUMMY_CK2;
            end if;
            
          when TX_DUMMY_CK2 =>
            if(divider_muxed = '1') then
              sclk  <= not sclk;
              state <= TX_GAP;
            end if;

          when TX_GAP =>
            if (divider_muxed = '1') then
              state <= IDLE;
            end if;
        end case;
      end if;
    end if;
  end process;

  ready_o    <= '1' when state = IDLE else '0';
  spi_sclk_o <= sclk xor cpol_i;
  
end behavioral;

