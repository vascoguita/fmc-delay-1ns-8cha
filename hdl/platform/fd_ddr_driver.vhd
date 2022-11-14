-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

-------------------------------------------------------------------------------
-- Title      : Xilinx DDR driver
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_ddr_driver.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-02-24
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Wrapper for Xilinx ODDR2 primitive. Configured to latch input
-- data at the rising edge of clk0_i.
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
-- 2012-02-10  1.0      twlostow        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity fd_ddr_driver is
  
  port (
    clk0_i : in  std_logic;
    clk1_i : in  std_logic;
    d0_i   : in  std_logic;
    d1_i   : in  std_logic;
    q_o    : out std_logic);

end fd_ddr_driver;

architecture wrapper of fd_ddr_driver is

  component ODDR2
    generic (
      DDR_ALIGNMENT : string := "C0";
      SRTYPE : string := "ASYNC");
    port (
      Q  : out std_ulogic;
      CE : in  std_ulogic := '1';
      R  : in  std_ulogic := '0';
      S  : in  std_ulogic := '0';
      C0 : in  std_ulogic;
      C1 : in  std_ulogic;
      D0 : in  std_ulogic;
      D1 : in  std_ulogic);
  end component;
  
begin  -- wrapper

  U_Wrapped_ODDR2 : ODDR2
    port map (
      Q  => q_o,
      C0 => clk0_i,
      C1 => clk1_i,
      D0 => d0_i,
      D1 => d1_i);

end wrapper;
