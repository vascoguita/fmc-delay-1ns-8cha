-------------------------------------------------------------------------------
-- Title      : DMTD-based insertion delay calibrator
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_dmtd_insertion_calibrator.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-02-26
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
  
  generic (

    g_with_wr_core : boolean);

  port (
    clk_ref_i  : in std_logic;
    clk_dmtd_i : in std_logic;
    clk_sys_i  : in std_logic;

    rst_n_sys_i : in std_logic;
    rst_n_ref_i : in std_logic;

    regs_i : in  t_fd_main_out_registers;
    regs_o : out t_fd_main_in_registers;

    -- Feedback from input and output channels
    dmtd_fb_in_i   : in  std_logic;
    dmtd_fb_out_i  : in  std_logic;
    
    -- Sampling clock (to the calibration DFFs)
    dmtd_samp_o    : out std_logic;
    
    -- DMTD Test pattern output (to TS3USB221 FPGA input)
    dmtd_pattern_o : out std_logic;

    calr_rd_ack_i  : in std_logic;
    spllr_rd_ack_i : in std_logic;

    wr_clk_dmtd_locked_i : in std_logic;

    dmtd_dac_value_o : out std_logic_vector(23 downto 0);
    dmtd_dac_wr_o    : out std_logic
    );


end fd_dmtd_insertion_calibrator;

architecture rtl of fd_dmtd_insertion_calibrator is

  constant c_TAG_BITS                 : integer := 24;
  constant c_INPUT_DEGLITCH_THRESHOLD : integer := 200;


  component fd_hpll_period_detect
    generic (
      g_freq_err_frac_bits : integer);
    port (
      clk_ref_i            : in  std_logic;
      clk_fbck_i           : in  std_logic;
      clk_sys_i            : in  std_logic;
      rst_n_refclk_i       : in  std_logic;
      rst_n_fbck_i         : in  std_logic;
      rst_n_sysclk_i       : in  std_logic;
      freq_err_o           : out std_logic_vector(11 downto 0);
      freq_err_stb_p_o     : out std_logic;
      hpll_fbcr_fd_gate_i  : in  std_logic_vector(2 downto 0);
      hpll_fbcr_ferr_set_i : in  std_logic_vector(11 downto 0));
  end component;

  component fd_dmtd_with_deglitcher
    generic (
      g_counter_bits : natural;
      g_chipscope    : boolean := false);
    port (
      rst_n_dmtdclk_i      : in  std_logic;
      rst_n_sysclk_i       : in  std_logic;
      clk_in_i             : in  std_logic;
      clk_dmtd_i           : in  std_logic;
      clk_sys_i            : in  std_logic;
      clk_dmtd_en_i        : in  std_logic := '1';
      shift_en_i           : in  std_logic := '0';
      shift_dir_i          : in  std_logic := '0';
      deglitch_threshold_i : in  std_logic_vector(15 downto 0);
      dbg_dmtdout_o        : out std_logic;
      tag_o                : out std_logic_vector(g_counter_bits-1 downto 0);
      tag_stb_p1_o         : out std_logic);
  end component;

  signal rst_n_dmtd : std_logic;

  signal dmtd_cnt, trig_cnt   : unsigned(f_log2_size(c_FD_DMTD_CALIBRATION_PERIOD)-1 downto 0);
  signal dmtd_tick, trig_tick : std_logic;

  signal freq_err   : std_logic_vector(11 downto 0);
  signal freq_err_p : std_logic;
  signal tag_spll   : std_logic_vector(19 downto 0);
  signal tag_spll_p : std_logic;

  signal dmtd_fb, dmtd_fb_synced : std_logic;

  -- DMTD Deglitcher stuff
  type   t_state is (WAIT_STABLE_0, WAIT_EDGE, GOT_EDGE);
  signal state         : t_state;
  signal stab_cntr     : unsigned(15 downto 0);
  signal free_cntr     : unsigned(c_TAG_BITS-1 downto 0);
  signal new_edge_sreg : std_logic_vector(5 downto 0);
  signal new_edge_p    : std_logic;
  signal tag_int       : unsigned(c_TAG_BITS-1 downto 0);
  
begin  -- rtl

  U_DMTD_Reset : gc_sync_ffs
    port map (
      clk_i    => clk_dmtd_i,
      rst_n_i  => '1',
      data_i   => rst_n_sys_i,
      synced_o => rst_n_dmtd);

  gen_without_wr_core : if(g_with_wr_core = false) generate
    U_Period_Detect : fd_hpll_period_detect
      generic map (
        g_freq_err_frac_bits => 0)
      port map (
        clk_ref_i            => clk_ref_i,
        clk_fbck_i           => clk_dmtd_i,
        clk_sys_i            => clk_sys_i,
        rst_n_refclk_i       => rst_n_ref_i,
        rst_n_fbck_i         => rst_n_dmtd,
        rst_n_sysclk_i       => rst_n_sys_i,
        freq_err_o           => freq_err,
        freq_err_stb_p_o     => freq_err_p,
        hpll_fbcr_fd_gate_i  => "011",  -- Gate = 131072
        hpll_fbcr_ferr_set_i => x"000"  -- no error setpoint, we can do that in software
        );

    U_SoftPLL_DMTD : fd_dmtd_with_deglitcher
      generic map (
        g_counter_bits => 20,
        g_chipscope    => false)
      port map (
        rst_n_dmtdclk_i      => rst_n_dmtd,
        rst_n_sysclk_i       => rst_n_sys_i,
        clk_in_i             => clk_ref_i,
        clk_dmtd_i           => clk_dmtd_i,
        clk_sys_i            => clk_sys_i,
        deglitch_threshold_i => std_logic_vector(to_unsigned(2000, 16)),
        dbg_dmtdout_o        => open,
        tag_o                => tag_spll,
        tag_stb_p1_o         => tag_spll_p);

    p_spll_output : process(clk_sys_i)
    begin
      if rising_edge(clk_sys_i) then
        if rst_n_sys_i = '0' then
          regs_o.spllr_tag_rdy_i <= '0';
        else
          if(regs_i.spllr_mode_o = '0' and freq_err_p = '1') then
            regs_o.spllr_tag_i(11 downto 0)  <= freq_err;
            regs_o.spllr_tag_i(19 downto 12) <= (others => '0');
            regs_o.spllr_tag_rdy_i           <= '1';
          elsif(regs_i.spllr_mode_o = '1' and tag_spll_p = '1') then
            regs_o.spllr_tag_i     <= tag_spll;
            regs_o.spllr_tag_rdy_i <= '1';
          elsif(spllr_rd_ack_i = '1') then
            regs_o.spllr_tag_rdy_i <= '0';
          end if;
        end if;
      end if;
    end process;

    dmtd_dac_value_o <= x"00" & regs_i.sdacr_dac_val_o;
    dmtd_dac_wr_o    <= regs_i.sdacr_dac_val_wr_o;
    
  end generate gen_without_wr_core;

  p_gen_dmtd_clock : process(clk_dmtd_i)
  begin
    if rising_edge(clk_dmtd_i) then
      if rst_n_dmtd = '0' then
        dmtd_cnt  <= (others => '0');
        dmtd_tick <= '0';
      else
        if(dmtd_cnt = c_FD_DMTD_CALIBRATION_PERIOD-1) then
          dmtd_tick <= '0';
          dmtd_cnt  <= (others => '0');
        elsif(dmtd_cnt = c_FD_DMTD_CALIBRATION_PERIOD/2-1) then
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
          trig_tick <= '0';
          trig_cnt  <= (others => '0');
        elsif(trig_cnt = c_FD_DMTD_CALIBRATION_PERIOD/2-1) then
          trig_tick <= '1';
          trig_cnt  <= trig_cnt + 1;
        else
          trig_cnt <= trig_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  dmtd_samp_o    <= dmtd_tick;
  dmtd_pattern_o <= trig_tick;


  dmtd_fb <= dmtd_fb_in_i when (regs_i.calr_dmtd_fbsel_o = '0') else dmtd_fb_out_i;

  U_Sync_FB : gc_sync_ffs
    port map (
      clk_i    => clk_dmtd_i,
      rst_n_i  => '1',
      data_i   => dmtd_fb,
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
            if stab_cntr = c_INPUT_DEGLITCH_THRESHOLD then
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

            if stab_cntr = c_INPUT_DEGLITCH_THRESHOLD then
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
      rst_n_i  => rst_n_sys_i,
      data_i   => new_edge_sreg(0),
      synced_o => open,
      npulse_o => open,
      ppulse_o => new_edge_p);

  p_tag_output : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_sys_i = '0' then
        regs_o.calr_dmtd_tag_rdy_i <= '0';
      else
        if(new_edge_p = '1') then
          regs_o.calr_dmtd_tag_i     <= std_logic_vector(tag_int(22 downto 0));
          regs_o.calr_dmtd_tag_rdy_i <= '1';
        elsif(calr_rd_ack_i = '1') then
          regs_o.calr_dmtd_tag_rdy_i <= '0';
        end if;
      end if;
    end if;
  end process;

end rtl;
