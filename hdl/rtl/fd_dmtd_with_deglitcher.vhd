-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

-------------------------------------------------------------------------------
-- Title      : Digital DMTD Edge Tagger
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : fd_dmtd_with_deglitcher.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-Co-HT
-- Created    : 2010-02-25
-- Last update: 2012-06-04
-- Platform   : FPGA-generic
-- Standard   : VHDL '93
-------------------------------------------------------------------------------
-- Description: Single-channel DDMTD phase tagger with integrated bit-median
-- deglitcher. Contains a DDMTD detector, which output signal is deglitched and
-- tagged with a counter running in DMTD offset clock domain. Phase tags are
-- generated for each rising edge in DDMTD output with an internal counter
-------------------------------------------------------------------------------
--
-- Copyright (c) 2009 - 2011 CERN
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
-- 2009-01-24  1.0      twlostow        Created
-- 2011-18-04  1.1      twlostow        Bit-median type deglitcher, comments
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

entity fd_dmtd_with_deglitcher is
  generic(
    -- Size of the phase tag counter. Must be big enough to cover at least one
    -- full period of the DDMTD detector output. Given the frequencies of clk_in_i
    -- and clk_dmtd_i are respectively f_in an f_dmtd, it can be calculated with
    -- the following formula:
    g_tag_bits           : integer;
    g_deglitch_threshold : integer);

  port(
    clk_sys_i  : in std_logic;
    clk_dmtd_i : in std_logic;

    rst_n_i : in std_logic;

    dmtd_fb_n_i : in std_logic;

    tag_o       : out std_logic_vector(g_tag_bits-1 downto 0);
    tag_valid_o : out std_logic);

end fd_dmtd_with_deglitcher;

architecture rtl of fd_dmtd_with_deglitcher is

  -- DMTD Deglitcher stuff
  type   t_state is (WAIT_STABLE_0, WAIT_EDGE, GOT_EDGE);
  signal state         : t_state;
  signal stab_cntr     : unsigned(g_tag_bits-1 downto 0);
  signal free_cntr     : unsigned(g_tag_bits-1 downto 0);
  signal new_edge_sreg : std_logic_vector(5 downto 0);
  signal new_edge_p    : std_logic;
  signal tag_int       : unsigned(g_tag_bits-1 downto 0);
  signal rst_n_dmtd    : std_logic;
  signal dmtd_fb_synced : std_logic;
  
begin  -- rtl

  U_DMTD_Reset : gc_sync_ffs
    port map (
      clk_i    => clk_dmtd_i,
      rst_n_i  => '1',
      data_i   => rst_n_i,
      synced_o => rst_n_dmtd);

  U_Sync_in : gc_sync_ffs
    port map (
      clk_i    => clk_dmtd_i,
      rst_n_i  => '1',
      data_i   => dmtd_fb_n_i,
      synced_o => dmtd_fb_synced);

  -- just a copy from dmtd_with_deglitcher.vhd

  p_deglitch : process (clk_dmtd_i)
  begin  -- process deglitch

    if rising_edge(clk_dmtd_i) then     -- rising clock edge

      if (rst_n_dmtd = '0') then        -- synchronous reset (active low)
        stab_cntr     <= (others => '0');
        state         <= WAIT_STABLE_0;
        free_cntr     <= (others => '0');
        new_edge_sreg <= (others => '0');
      else
        
        free_cntr <= free_cntr + 1;

        case state is
          when WAIT_STABLE_0 =>         -- out-of-sync
            new_edge_sreg <= '0' & new_edge_sreg(new_edge_sreg'length-1 downto 1);

            if dmtd_fb_synced /= '0' then
              stab_cntr <= (others => '0');
            else
              stab_cntr <= stab_cntr + 1;
            end if;

            -- DMTD output stable counter hit the LOW level threshold?
            if stab_cntr = g_deglitch_threshold then
              state <= WAIT_EDGE;
            end if;

          when WAIT_EDGE =>
            if (dmtd_fb_synced /= '0') then  -- got a glitch?
              state     <= GOT_EDGE;
              tag_int   <= free_cntr;
              stab_cntr <= (others => '0');
            end if;

          when GOT_EDGE =>
            if (dmtd_fb_synced = '0') then
              tag_int <= tag_int + 1;
            end if;

            if stab_cntr = g_deglitch_threshold then
              state         <= WAIT_STABLE_0;
              --tag_int       <= std_logic_vector(tag_int);
              new_edge_sreg <= (others => '1');
              stab_cntr     <= (others => '0');
            elsif (dmtd_fb_synced = '0') then
              stab_cntr <= (others => '0');
            else
              stab_cntr <= stab_cntr + 1;
            end if;
        end case;
      end if;
    end if;
  end process p_deglitch;



  U_sync_tag_strobe : gc_sync_ffs
    port map (
      clk_i    => clk_sys_i,
      rst_n_i  => rst_n_i,
      data_i   => new_edge_sreg(0),
      synced_o => open,
      npulse_o => open,
      ppulse_o => tag_valid_o);

  tag_o <= std_logic_vector(tag_int);
end rtl;
