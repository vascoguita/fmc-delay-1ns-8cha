-----------------------------------------------------------------------------
-- Title      : SY89295U 4-input arbitration unit
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_delay_line_arbiter.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2014-03-24
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Multiplexes access from 4 delay generators to a single shared
-- bus driving the SY89295U fine delay line chips.
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


entity fd_delay_line_arbiter is
  
  port (
    clk_ref_i : in std_logic;
    rst_n_i   : in std_logic;

    -- when load_i(X) == 1, delay_valX_i contains a new setpoint for delay line
    -- X and requests reprogramming the delay line
    load_i : in  std_logic_vector(3 downto 0);
    -- 1: acknowledge of the request above
    done_o : out std_logic_vector(3 downto 0);

    -- tap delay values for all channels
    delay_val0_i : in std_logic_vector(9 downto 0);
    delay_val1_i : in std_logic_vector(9 downto 0);
    delay_val2_i : in std_logic_vector(9 downto 0);
    delay_val3_i : in std_logic_vector(9 downto 0);

    -- SY89295U outputs: delay value ...
    delay_val_o : out std_logic_vector(9 downto 0);
    -- ... and latch enable (active low).
    delay_len_o : out std_logic_vector(3 downto 0)

    );
end fd_delay_line_arbiter;

architecture behavioral of fd_delay_line_arbiter is
  
  type t_dly_array is array (integer range <>) of std_logic_vector(9 downto 0);

  signal cntr : unsigned(1 downto 0);

  signal delay_vec     : t_dly_array(0 to 3);
  signal delay_len_reg : std_logic_vector(3 downto 0);
  signal delay_val_reg : std_logic_vector(9 downto 0);
  signal pending_req   : std_logic_vector(3 downto 0);
  
begin  -- behavioral

  delay_vec(0) <= delay_val0_i;
  delay_vec(1) <= delay_val1_i;
  delay_vec(2) <= delay_val2_i;
  delay_vec(3) <= delay_val3_i;

  p_arb_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        cntr <= (others => '0');
      else
        cntr <= cntr + 1;
      end if;
    end if;
  end process;

  p_req_done : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        pending_req <= (others => '0');
        done_o      <= (others => '0');
      else
        
        for i in 0 to 3 loop
          if load_i(i) = '1' then
            pending_req(i) <= '1';
            done_o(i)      <= '0';
          elsif (cntr = i) then
            pending_req(i) <= '0';
            done_o(i)      <= pending_req(i);
          else
            done_o(i) <= '0';
          end if;
        end loop;
      end if;
    end if;
  end process;

  p_drive_delays : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        delay_len_reg <= (others => '0');
        delay_val_reg <= (others => '0');
      else
        delay_val_reg <= delay_vec(to_integer (cntr));

        for i in 0 to 3 loop
          if(cntr = i) then
            delay_len_reg (i) <= not pending_req(i);
          else
            delay_len_reg (i) <= '1';
          end if;
        end loop;  -- i
        
      end if;
    end if;
  end process;


  p_reg_outputs : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      delay_val_o <= delay_val_reg;
    end if;
  end process;

  p_reg_len : process(clk_ref_i)
  begin
    -- we latch the LEN signal on the falling edge, so the L->H transition (which
    -- latches the delay word in the '295 gets right in the middle of the data
    -- window.
    if falling_edge(clk_ref_i) then
      delay_len_o <= delay_len_reg;
    end if;
  end process;

  
end behavioral;
