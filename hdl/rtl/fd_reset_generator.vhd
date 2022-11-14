-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

-----------------------------------------------------------------------------
-- Title      : Reset unit.
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_reset_generator.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-02-26
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Provides host-driven reset signals for the FD Core and the FMC
-- board.
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
use work.gencores_pkg.all;

entity fd_reset_generator is
  
  port (
    clk_sys_i : in std_logic;
    clk_ref_i : in std_logic;

    -- Master reset input, including Wishbone logic
    rst_n_i : in std_logic;

    -- Reset output (system clock domain EXCLUDING Wishbone)
    rst_n_sys_o : out std_logic;

    -- Reset output (reference clock domain)
    rst_n_ref_o : out std_logic;

    -- FMC Reset line
    ext_rst_n_o : out std_logic;       
    regs_i      : in  t_fd_main_out_registers);

end fd_reset_generator;

architecture behavioral of fd_reset_generator is

  constant c_RSTR_TRIGGER_VALUE : std_logic_vector(15 downto 0) := x"dead";

  signal rstn_host_sysclk : std_logic;
  signal rstn_host_refclk : std_logic;
  signal rstn_host_d0     : std_logic;
  signal rstn_host_d1     : std_logic;

  signal rst_fmc          : std_logic;
  signal rst_fmc_extended : std_logic;
  

begin  -- behavioral

  
  p_soft_reset : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if(rst_n_i = '0') then
        rstn_host_sysclk <= '0';
        ext_rst_n_o      <= '0';
      else
        -- protection against accidental write
        if(regs_i.rstr_lock_wr_o = '1' and regs_i.rstr_lock_o = c_RSTR_TRIGGER_VALUE) then
          rstn_host_sysclk <= regs_i.rstr_rst_core_o;
          ext_rst_n_o      <= regs_i.rstr_rst_fmc_o;
        end if;
      end if;
    end if;
  end process;

  p_sync_reset_refclk : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      rstn_host_refclk <= rst_n_i and rstn_host_sysclk;
      rstn_host_d0     <= rstn_host_sysclk;
      rstn_host_d1     <= rstn_host_d0;
      rstn_host_refclk <= rstn_host_d1;
    end if;
  end process;

  rst_n_ref_o <= rstn_host_refclk;
  rst_n_sys_o <= rstn_host_sysclk;

end behavioral;
