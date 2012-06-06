-------------------------------------------------------------------------------
-- Title      : DMTD-based insertion delay calibrator
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_dmtd_insertion_calibrator.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-06-06
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Measures the In-out delay of the entire card using DDMTD
-- technique. The card is programmed to introduce a constant delay of, say,
-- 500 ns. The input is fed with a sequence of pulses of 1 MHz frequency,
-- which are sampled on the PCB at both the input and the output of the FD card
-- with a sequence of identical pulses, but slightly offset in frequency.
-- This allows to take an accurate measure of in-out delay.
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

-- FIXME: test and comment


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;
use work.genram_pkg.all;
use work.wishbone_pkg.all;
use work.fine_delay_pkg.all;
use work.fd_main_wbgen2_pkg.all;


entity fd_dmtd_insertion_calibrator is
  
  port (
    clk_ref_i  : in std_logic;
    clk_dmtd_i : in std_logic;
    clk_sys_i  : in std_logic;

    rst_n_sys_i : in std_logic;
    rst_n_ref_i : in std_logic;

    regs_i : in  t_fd_main_out_registers;
    regs_o : out t_fd_main_in_registers;

    -- Feedback from input and output channels
    dmtd_fb_in_i  : in std_logic;
    dmtd_fb_out_i : in std_logic;

    -- Sampling clock (to the calibration DFFs)
    dmtd_samp_o : out std_logic;

    -- DMTD Test pattern output (to TS3USB221 FPGA input)
    dmtd_pattern_o : out std_logic;

    dmtr_in_rd_ack_i  : in std_logic;
    dmtr_out_rd_ack_i : in std_logic;

    dbg_tag_in_o: out std_logic;
    dbg_tag_out_o: out std_logic
    );


end fd_dmtd_insertion_calibrator;

architecture rtl of fd_dmtd_insertion_calibrator is

  component fd_dmtd_with_deglitcher
    generic (
      g_tag_bits           : integer;
      g_deglitch_threshold : integer);
    port (
      clk_sys_i   : in  std_logic;
      clk_dmtd_i  : in  std_logic;
      rst_n_i     : in  std_logic;
      dmtd_fb_n_i : in  std_logic;
      tag_o       : out std_logic_vector(g_tag_bits-1 downto 0);
      tag_valid_o : out std_logic);
  end component;
  
  constant c_TAG_BITS                 : integer := 23;
  constant c_INPUT_DEGLITCH_THRESHOLD : integer := 30000;

  signal dmtd_cnt, trig_cnt          : unsigned(f_log2_size(c_FD_DMTD_CALIBRATION_PERIOD)-1 downto 0);
  signal dmtd_tick, trig_tick        : std_logic;
  signal tag_in, tag_out             : std_logic_vector(c_TAG_BITS-1 downto 0);
  signal tag_valid_in, tag_valid_out : std_logic;
  signal rst_n_dmtd : std_logic;
begin  -- rtl

   U_DMTD_Reset : gc_sync_ffs
    port map (
      clk_i    => clk_dmtd_i,
      rst_n_i  => '1',
      data_i   => rst_n_sys_i,
      synced_o => rst_n_dmtd);

  U_Input_DMTD : fd_dmtd_with_deglitcher
    generic map (
      g_tag_bits           => c_TAG_BITS,
      g_deglitch_threshold => c_INPUT_DEGLITCH_THRESHOLD)
    port map (
      clk_sys_i   => clk_sys_i,
      clk_dmtd_i  => clk_dmtd_i,
      rst_n_i     => regs_i.calr_cal_dmtd_o,
      dmtd_fb_n_i => dmtd_fb_in_i,
      tag_o       => tag_in,
      tag_valid_o => tag_valid_in);

  U_Output_DMTD : fd_dmtd_with_deglitcher
    generic map (
      g_tag_bits           => c_TAG_BITS,
      g_deglitch_threshold => c_INPUT_DEGLITCH_THRESHOLD)
    port map (
      clk_sys_i   => clk_sys_i,
      clk_dmtd_i  => clk_dmtd_i,
      rst_n_i     => regs_i.calr_cal_dmtd_o,
      dmtd_fb_n_i => dmtd_fb_out_i,
      tag_o       => tag_out,
      tag_valid_o => tag_valid_out);

  p_gen_dmtd_clock : process(clk_dmtd_i)
  begin
    if rising_edge(clk_dmtd_i) then
      if rst_n_dmtd = '0' then
        dmtd_cnt  <= (others => '0');
        dmtd_tick <= '0';
      else
        if(dmtd_cnt = c_FD_DMTD_CALIBRATION_PERIOD/2-1) then
          dmtd_tick <= '0';
          dmtd_cnt  <= (others => '0');
        elsif(dmtd_cnt = c_FD_DMTD_CALIBRATION_PERIOD/4-1) then
          dmtd_tick <= '1';
          dmtd_cnt  <= dmtd_cnt + 1;
        else
          dmtd_cnt <= dmtd_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  p_gen_trig_pattern : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_ref_i = '0' then
        trig_cnt  <= (others => '0');
        trig_tick <= '0';
      else
        if(trig_cnt = c_FD_DMTD_CALIBRATION_PERIOD-1) then
          trig_tick <= '1';
          trig_cnt  <= (others => '0');
        elsif(trig_cnt = c_FD_DMTD_CALIBRATION_PWIDTH) then
          trig_tick <= '0';
          trig_cnt  <= trig_cnt + 1;
        else
          trig_cnt <= trig_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  dmtd_samp_o    <= dmtd_tick;
  dmtd_pattern_o <= trig_tick;


  p_tag_output : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_sys_i = '0' then
        regs_o.dmtr_in_rdy_i  <= '0';
        regs_o.dmtr_out_rdy_i <= '0';
      else

        if(tag_valid_in = '1') then
          regs_o.dmtr_in_tag_i(c_TAG_BITS-1 downto 0) <= tag_in;
          regs_o.dmtr_in_rdy_i                        <= '1';
        elsif(dmtr_in_rd_ack_i = '1') then
          regs_o.dmtr_in_rdy_i <= '0';
        end if;

        if(tag_valid_out = '1') then
          regs_o.dmtr_out_tag_i(c_TAG_BITS-1 downto 0) <= tag_out;
          regs_o.dmtr_out_rdy_i                        <= '1';
        elsif(dmtr_out_rd_ack_i = '1') then
          regs_o.dmtr_out_rdy_i <= '0';
        end if;
      end if;
    end if;
  end process;

   
   U_E1 : gc_extend_pulse
    generic map (
      g_width => 10000)
    port map (
      clk_i      => clk_sys_i,
      rst_n_i    => rst_n_sys_i,
      pulse_i    => tag_valid_in,
      extended_o => dbg_tag_in_o);

   U_E2 : gc_extend_pulse
    generic map (
      g_width => 10000)
    port map (
      clk_i      => clk_sys_i,
      rst_n_i    => rst_n_sys_i,
      pulse_i    => tag_valid_out,
      extended_o => dbg_tag_out_o);


end rtl;
