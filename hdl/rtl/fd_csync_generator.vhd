-------------------------------------------------------------------------------
-- Title      : Counter Sync signal generator
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_csync_generator.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-11-26
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Generates the internal time base used to synchronize the TDC
-- and programmable pulse generators to an internal or WR-provided timescale.
-- Also interfaces the FD core with an optional White Rabbit PTP core.
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
-- 2012-02-16  1.1      twlostow        built-in WR sync FSM (untested)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.genram_pkg.all;
use work.gencores_pkg.all;
use work.fine_delay_pkg.all;
use work.fd_main_wbgen2_pkg.all;

entity fd_csync_generator is

  generic (
    -- when true, reduces some timeouts to speed up simulations
    g_simulation   : boolean;
    g_with_wr_core : boolean);
  port(
    clk_ref_i   : in std_logic;
    clk_sys_i   : in std_logic;
    rst_n_sys_i : in std_logic;
    rst_n_ref_i : in std_logic;

    -------------------------------------------------------------------------------
    -- White Rabbit Counter sync input
    -------------------------------------------------------------------------------
    
    wr_link_up_i         : in  std_logic;

    -- when HI, wr_utc_i and wr_coarse_i contain a valid time value and
    -- clk_ref_i is in-phase with the remote WR master
    wr_time_valid_i      : in  std_logic;

    -- 1: tells the WR core to lock the FMC's local oscillator to the WR
    -- reference clock. 0: keep the oscillator free running.
    wr_clk_aux_lock_en_o : out std_logic;

    -- 1: FMC's Local oscillator locked to WR reference 
    wr_clk_aux_locked_i  : in  std_logic;

    -- 1: Carrier's DMTD clock is locked (to WR reference or local FMC oscillator)
    wr_clk_dmtd_locked_i : in  std_logic;

    -- Timecode input
    wr_utc_i             : in  std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
    wr_coarse_i          : in  std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);

    -- Counter sync output. HI Pulse = load internal counter with values from
    -- csync_utc_o and csync_coarse_o.
    csync_p1_o     : out std_logic;
    csync_utc_o    : out std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
    csync_coarse_o : out std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);

    -- Wishbone regs
    regs_i : in  t_fd_main_out_registers;
    regs_o : out t_fd_main_in_registers;

    csync_pps_o: out std_logic;
    
    -- read ack of TCR register, implements clear-on-read functionality
    tcr_rd_ack_i : in std_logic;

    -- WR status change interrupt
    irq_sync_o : out std_logic         
    );

end fd_csync_generator;

architecture behavioral of fd_csync_generator is

  impure function f_eval_timeout return integer is
  begin
    if(g_simulation) then
      return 100;
    else
      return c_SYS_CLK_FREQ/1000;       -- 1ms state timeout
    end if;
  end f_eval_timeout;

  constant c_ADDER_PIPELINE_DELAY : integer := 4;
  constant c_WR_STATE_TIMEOUT     : integer := f_eval_timeout;

  signal coarse, coarse_sys : unsigned(c_TIMESTAMP_COARSE_BITS-1 downto 0);
  signal utc, utc_sys       : unsigned(c_TIMESTAMP_UTC_BITS-1 downto 0);

  signal csync_int : std_logic;
  signal csync_wr  : std_logic;

  signal tmo_restart, tmo_hit : std_logic;

  signal tmo_cntr : unsigned(f_log2_size(c_WR_STATE_TIMEOUT)-1 downto 0);

  type   t_wr_sync_state is (WR_CORE_OFFLINE, WR_WAIT_READY, WR_SYNCING, WR_SYNCED);
  signal wr_state         : t_wr_sync_state;
  signal wr_state_changed : std_logic;

  signal csync_wr_refclk : std_logic;
  signal csync_wr_sysclk : std_logic;
  signal dmtd_locked_d0  : std_logic;
  signal dmtd_stat       : std_logic;
  
  signal pps_p1 : std_logic;
  
begin  -- behavioral

  p_timeout_counter : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_sys_i = '0' or tmo_restart = '1' or tmo_hit = '1' then
        tmo_cntr <= (others => '0');
        tmo_hit  <= '0';
      else
        tmo_cntr <= tmo_cntr + 1;
        if(tmo_cntr = c_WR_STATE_TIMEOUT) then
          tmo_hit <= '1';
        end if;
      end if;
    end if;
  end process;

  -- keep the csync output 1 cycle ahead the wr_utc/coarse_i
  U_Timescale_Adjust : fd_ts_adder
    generic map (
      g_frac_bits => 2)
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_n_ref_i,
      valid_i    => csync_int,
      a_utc_i    => std_logic_vector(utc),
      a_coarse_i => std_logic_vector(coarse),
      a_frac_i   => (others => '0'),
      b_utc_i    => (others => '0'),
      b_coarse_i => std_logic_vector(to_signed(c_ADDER_PIPELINE_DELAY+1, coarse'length)),
      b_frac_i   => (others => '0'),
      valid_o    => csync_p1_o,
      q_utc_o    => csync_utc_o,
      q_coarse_o => csync_coarse_o,
      q_frac_o   => open);


  p_sys_time_registers : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if regs_i.tcr_cap_time_o = '1' then
        -- fixme: keep the sizes scalable
        regs_o.tm_sech_i   <= std_logic_vector(utc(39 downto 32));
        regs_o.tm_secl_i   <= std_logic_vector(utc(31 downto 0));
        regs_o.tm_cycles_i <= std_logic_vector(coarse);
      end if;

      if regs_i.tm_sech_load_o = '1' then
        utc_sys(39 downto 32) <= unsigned(regs_i.tm_sech_o);
      end if;

      if regs_i.tm_secl_load_o = '1' then
        utc_sys(31 downto 0) <= unsigned(regs_i.tm_secl_o);
      end if;

      if(regs_i.tm_cycles_load_o = '1') then
        coarse_sys <= unsigned(regs_i.tm_cycles_o);
      end if;
    end if;
  end process;


  p_master_timebase_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if((csync_wr_refclk = '1') and g_with_wr_core) then
        utc       <= unsigned(wr_utc_i);
        coarse    <= unsigned(wr_coarse_i) + 1;
        csync_int <= '1';
      elsif(regs_i.tcr_set_time_o = '1') then
        utc       <= utc_sys;
        coarse    <= coarse_sys;
        csync_int <= '1';
      elsif(coarse = c_REF_CLK_FREQ) then  -- unlike, but may happen after WR csync
        coarse    <= to_unsigned(1, coarse'length);
        utc       <= utc + 1;
        csync_int <= '0';
      elsif(coarse = c_REF_CLK_FREQ-1) then
        coarse    <= (others => '0');
        utc       <= utc + 1;
        csync_int <= '0';
      else
        coarse    <= coarse + 1;
        csync_int <= '0';
      end if;
    end if;
  end process;

  U_Sync_WR_Csync : gc_pulse_synchronizer
    port map (
      clk_in_i  => clk_sys_i,
      clk_out_i => clk_ref_i,
      rst_n_i   => rst_n_ref_i,
      d_p_i     => csync_wr_sysclk,
      q_p_o     => csync_wr_refclk);


  tmo_restart <= wr_state_changed;

  gen_with_wr_core : if(g_with_wr_core) generate
    p_whiterabbit_fsm : process(clk_sys_i)
    begin
      if rising_edge(clk_sys_i) then
        if rst_n_sys_i = '0' then
          csync_wr_sysclk      <= '0';
          wr_clk_aux_lock_en_o <= '0';
          wr_state             <= WR_CORE_OFFLINE;
          wr_state_changed     <= '0';
        else
          case wr_state is
            when WR_CORE_OFFLINE =>
              wr_clk_aux_lock_en_o <= '0';

              if(wr_link_up_i = '1' and tmo_hit = '1') then
                wr_state         <= WR_WAIT_READY;
                wr_state_changed <= '1';
              else
                wr_state_changed <= '0';
              end if;

            when WR_WAIT_READY =>
              wr_clk_aux_lock_en_o <= '0';

              if(wr_link_up_i = '0') then
                wr_state         <= WR_CORE_OFFLINE;
                wr_state_changed <= '1';
              elsif(wr_time_valid_i = '1' and tmo_hit = '1' and regs_i.tcr_wr_enable_o = '1') then
                wr_state_changed <= '1';
                wr_state         <= WR_SYNCING;
              else
                wr_state_changed <= '0';
              end if;

            when WR_SYNCING =>
              wr_clk_aux_lock_en_o <= '1';

              if(wr_time_valid_i = '0' or regs_i.tcr_wr_enable_o = '0') then
                wr_state         <= WR_WAIT_READY;
                wr_state_changed <= '1';
              elsif(wr_clk_aux_locked_i = '1' and tmo_hit = '1') then
                wr_state         <= WR_SYNCED;
                csync_wr_sysclk  <= '1';
                wr_state_changed <= '1';
              else
                wr_state_changed <= '0';
              end if;

            when WR_SYNCED =>
              csync_wr_sysclk <= '0';

              if(wr_time_valid_i = '0' or regs_i.tcr_wr_enable_o = '0' or wr_clk_aux_locked_i = '0') then
                wr_state         <= WR_SYNCING;
                wr_state_changed <= '1';
              else
                wr_state_changed <= '0';
              end if;
          end case;
        end if;
      end if;
    end process;

    p_gen_dmtd_stat : process(clk_sys_i)
    begin
      if rising_edge(clk_sys_i) then
        if rst_n_sys_i = '0' then
          dmtd_stat <= '0';
          dmtd_locked_d0         <= '0';
        else
          dmtd_locked_d0 <= wr_clk_dmtd_locked_i;

          if(tcr_rd_ack_i = '1') then
            dmtd_stat <= wr_clk_dmtd_locked_i;
          elsif(wr_clk_dmtd_locked_i = '0') then
            dmtd_stat <= '0';
          end if;
        end if;
      end if;
    end process;

    regs_o.tcr_dmtd_stat_i <= dmtd_stat;
    regs_o.tcr_wr_locked_i <= '1' when wr_state = WR_SYNCED                            else '0';
    regs_o.tcr_wr_ready_i  <= '1' when (wr_state = WR_SYNCING or wr_state = WR_SYNCED) else '0';
    regs_o.tcr_wr_link_i   <= wr_link_up_i;
  end generate gen_with_wr_core;

  -- debug/calibration PPS output
  p_gen_pps: process(clk_ref_i)
    begin
      if rising_edge(clk_ref_i) then
        if(coarse = c_REF_CLK_FREQ-3) then
          pps_p1 <= '1';
        else
          pps_p1 <= '0';
        end if;
      end if;
    end process;

  U_Extend_Test_PPS: gc_extend_pulse
      generic map (
        g_width => 3)
      port map (
        clk_i      => clk_ref_i,
        rst_n_i    => rst_n_ref_i,
        pulse_i    => pps_p1,
        extended_o => csync_pps_o);


  irq_sync_o              <= '0' when (g_with_wr_core = false or rst_n_sys_i = '0') else (wr_state_changed and regs_i.tcr_wr_enable_o);
  
  regs_o.tcr_wr_present_i <= '1' when (g_with_wr_core)         else '0';
end behavioral;
