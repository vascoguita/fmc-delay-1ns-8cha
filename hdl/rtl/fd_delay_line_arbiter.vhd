-----------------------------------------------------------------------------
-- Title      : SY89295U 4-input arbitration unit
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_delay_line_arbiter.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-02-26
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
  signal arb_sreg : std_logic_vector(4*3 - 1 downto 0);

  type t_dly_array is array (integer range <>) of std_logic_vector(9 downto 0);

  signal done_reg      : std_logic_vector(3 downto 0);
  signal delay_vec     : t_dly_array(0 to 3);
  signal delay_len_reg : std_logic_vector(3 downto 0);
  signal delay_val_reg : std_logic_vector(9 downto 0);
  
begin  -- behavioral

  delay_vec(0) <= delay_val0_i;
  delay_vec(1) <= delay_val1_i;
  delay_vec(2) <= delay_val2_i;
  delay_vec(3) <= delay_val3_i;


  p_arbitrate : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        delay_len_reg <= (others => '1');
        delay_val_reg <= (others => '0');
        -- done_reg      <= (others => '0');
        done_o        <= (others => '0');
        arb_sreg      <= std_logic_vector(to_unsigned(1, arb_sreg'length));
      else
        arb_sreg <= arb_sreg(arb_sreg'left-1 downto 0) & arb_sreg(arb_sreg'left);

        for i in 0 to 3 loop
          if(arb_sreg(3*i) = '1' and load_i(i) = '1') then
            delay_val_reg    <= delay_vec(i);
            delay_len_reg(i) <= '0';
            done_o(i)        <= '1';
          end if;


          if(arb_sreg(3*i+1) = '1') then
            delay_val_reg <= delay_vec(i);
            done_o(i)     <= '0';
          end if;


          if(arb_sreg(3*i+2) = '1') then
            delay_val_reg    <= delay_vec(i);
            delay_len_reg(i) <= '1';
            done_o(i)        <= '0';
          end if;

        end loop;  -- i in 0 to 3

        delay_len_o <= delay_len_reg;
        delay_val_o <= delay_val_reg;
      end if;
    end if;
  end process;

  
end behavioral;
