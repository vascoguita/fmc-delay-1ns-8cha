-------------------------------------------------------------------------------
-- Title      : ACAM TDC-GPX Timestamper
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_acam_timestamper.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-04-03
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: A complete sub-nanosecond pulse timestamper using ACAM's
-- TDC-GPX chip for fine delay measurement and a FPGA-internal counter to
-- capture the coarse part. See comments inside the RTL code for the details.
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

use work.gencores_pkg.all;
use work.fine_delay_pkg.all;
use work.fd_main_wbgen2_pkg.all;        -- for Wishbone regs

entity fd_acam_timestamper is
  generic(
    -- minimum input pulse width in clk_ref_i cycles
    g_min_pulse_width : natural := 3;
    -- clk_ref_i frequency in Hz
    g_clk_ref_freq    : integer := 125000000;
    -- size of the fractional (< 8 ns) part of the timestamp
    g_frac_bits       : integer := 12
    );
  port (

-------------------------------------------------------------------------------
-- Clocks / Resets / Triggers
-------------------------------------------------------------------------------

-- System reference clock (125 MHz coming from the FMC PLL)
    clk_ref_i : in std_logic;

-- reset, active LOW
    rst_n_i  : in std_logic;
-- Inverted ACAM trigger input
    trig_a_i : in std_logic;

-- TDC Start singnal (i.e. 125/16 = 7.8125 MHz slow clock synchronous to clk_ref_i)
    tdc_start_i : in std_logic;

-------------------------------------------------------------------------------
-- ACAM TDC-GPX interface (asynchronous, but all generated/sampled within
-- clk_ref_i domain)
-------------------------------------------------------------------------------

-- ACAM data bus (normally tri-state, but ISE does not allow having tristate drivers
-- except directly in the top level entity.

    acam_d_o    : out std_logic_vector(27 downto 0);
    acam_d_i    : in  std_logic_vector(27 downto 0);
    acam_d_oe_o : out std_logic;

-- ACAM read and write enables (all active LOW - CS is tied to GND onboard)
    acam_rd_n_o : out std_logic;
    acam_wr_n_o : out std_logic;

-- ACAM FIFO empty flag
    acam_ef_i : in std_logic;

-- ACAM start & stop disable pins. Stop/start inputs are DISABLED when
-- stop/start_dis_o is 1.
    acam_stop_dis_o  : out std_logic;
    acam_start_dis_o : out std_logic;

-- ACAM Master reset (connected to AluTrig pin)
    acam_alutrigger_o : out std_logic;

-------------------------------------------------------------------------------
-- Time tag I/O (clk_ref_i domain). Timestamps are not normalized!
-------------------------------------------------------------------------------

-- fractional part of the time tag (0..8 ns range rescaled to 0..2**g_frac_bits-1)
    tag_frac_o : out std_logic_vector(g_frac_bits-1 downto 0);

-- coarse part of the time tag (in clk_ref_i cycles)
    tag_coarse_o : out std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);

-- UTC part of the time tag (in seconds)
    tag_utc_o : out std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);

-- re-arm input. After tagging a pulse, the timestamper automatically disables the
-- trigger input until a positive pulse is delivered to tag_rearm_p1_i. If we want
-- the timestamps to be produced continously, tag_rearm_p1_i should be
-- peramamently driven to 1.
    tag_rearm_p1_i : in std_logic;

-- single-cycle pulse indicates presence of a valid time tag on the tag_xxx_o lines.
    tag_valid_o : out std_logic;

-------------------------------------------------------------------------------
-- Time base synchronization/alignment (clk_ref_i domain). Must not be used
-- when the timestamper input is enabled, as it will lead to broken timestamps
-- during resynchronization.
-------------------------------------------------------------------------------

-- New value of the coarse counter (125 MHz ticks)
    csync_coarse_i : in std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);

-- New value of the UTC counter
    csync_utc_i : in std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);

-- Single-cycle pulse aligns the local timebase counter with csync_coarse_i and
-- csync_utc_i.
    csync_p1_i : in std_logic;

---------------------------------------------------------------------------
-- Wishbone registers
---------------------------------------------------------------------------

    regs_i : in  t_fd_main_out_registers;
    regs_o : out t_fd_main_in_registers;

    -- debug output (for connecting oscilloscope, etc.)
    dbg_o : out std_logic_vector(3 downto 0)
    );

end fd_acam_timestamper;

architecture behavioral of fd_acam_timestamper is

  component fd_acam_timestamp_postprocessor
    generic (
      g_frac_bits : integer);
    port (
      clk_ref_i              : in  std_logic;
      rst_n_i                : in  std_logic;
      raw_valid_i            : in  std_logic;
      raw_utc_i              : in  std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
      raw_coarse_i           : in  std_logic_vector(c_TIMESTAMP_COARSE_BITS-4-1 downto 0);
      raw_frac_i             : in  std_logic_vector(22 downto 0);
      raw_start_offset_i     : in  std_logic_vector(3 downto 0);
      acam_subcycle_offset_i : in  std_logic_vector(4 downto 0);
      tag_valid_o            : out std_logic;
      tag_utc_o              : out std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
      tag_coarse_o           : out std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
      tag_frac_o             : out std_logic_vector(g_frac_bits-1 downto 0);
      regs_i                 : in  t_fd_main_out_registers);
  end component;

  component fd_timestamper_stat_unit
    port (
      clk_ref_i       : in  std_logic;
      rst_n_i         : in  std_logic;
      trig_pulse_i    : in  std_logic;
      raw_tag_valid_i : in  std_logic;
      regs_i          : in  t_fd_main_out_registers;
      regs_o          : out t_fd_main_in_registers);
  end component;

  -- maximum time (in clk_ref_i cycles) between the input pulse and the presence
  -- of its timestamp in ACAM's output FIFO.
  constant c_ACAM_TIMEOUT : integer                       := 60;
  constant c_ones         : std_logic_vector(31 downto 0) := x"ffffffff";

  -- states of the main ACAM FSM reading/writing data from/to the TDC
  type t_acam_fsm_state is (IDLE, R_ADDR, R_PULSE, R_READ, R_EXTEND_R_PULSE1, R_END_CYCLE, R_ADDR2, W_DATA_ADDR, W_PULSE, W_WAIT,
                            RMODE_PURGE_FIFO,
                            RMODE_PURGE_WAIT,
                            RMODE_PURGE_WAIT2,
                            RMODE_PURGE_CHECK_EMPTY,
                            RMODE_READ,
                            RMODE_READ_PULSE,
                            RMODE_READ_PULSE2,
                            R_EXTEND_R_PULSE2,
                            RMODE_CHECK_WIDTH,
                            RMODE_MEASURE_WIDTH);

  signal afsm_state : t_acam_fsm_state;
  signal acam_wdata : std_logic_vector(27 downto 0);

  signal acam_reset_int : std_logic;
  signal tag_enable     : std_logic;
  signal advance_coarse : std_logic;

  -- delay/sync chains
  signal tdc_start_d  : std_logic_vector(2 downto 0);
  signal trig_d       : std_logic_vector(2 downto 0);
  signal acam_ef_d    : std_logic_vector(1 downto 0);
  signal tag_enable_d : std_logic_vector(2 downto 0);

  signal trig_pulse : std_logic;

  -- counters (internal time base)
  signal start_count     : unsigned(3 downto 0);
  signal coarse_count    : unsigned(c_TIMESTAMP_COARSE_BITS-4-1 downto 0);
  signal utc_count       : unsigned(c_TIMESTAMP_UTC_BITS-1 downto 0);
  signal subcycle_offset : signed(4 downto 0);

  signal gcr_input_en_d0 : std_logic;

  -- raw (unprocessed) time tag
  signal raw_tag_valid        : std_logic;
  signal raw_tag_coarse       : unsigned(c_TIMESTAMP_COARSE_BITS-4-1 downto 0);
  signal raw_tag_frac         : signed(22 downto 0);
  signal raw_tag_start_offset : unsigned(3 downto 0);
  signal raw_tag_utc          : unsigned(c_TIMESTAMP_UTC_BITS-1 downto 0);

  signal width_check_sreg : std_logic_vector(g_min_pulse_width-2 downto 0);
  signal width_check_mask : std_logic_vector(g_min_pulse_width-2 downto 0);


  signal timeout_counter : unsigned(5 downto 0);

  signal host_start_dis : std_logic;
  signal host_stop_dis  : std_logic;

  signal start_ok_sreg : std_logic_vector(2 downto 0);
  signal start_ok      : std_logic;


  signal regs_out_int  : t_fd_main_in_registers;
  signal regs_out_stat : t_fd_main_in_registers;

  signal tag_valid_int : std_logic;
  signal tag_coarse    : std_logic_vector(27 downto 0);

  signal mask_stop : std_logic;
begin  -- behave

--Process: p_sync_trigger
-- Inputs: trig_a_i, tag_enable
-- Outputs: trig_pulse, trig_d
--
-- Synchronizer chain for the asynchronous trigger signal. The sync
-- chain is enabled when (tag_enable = '1') and produces a single-cycle pulse
-- on trig_pulse upon each rising edge in the input signal.

  p_sync_trigger : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_n_i = '0') then
        trig_d       <= (others => '0');
        trig_pulse   <= '0';
        tag_enable_d <= (others => '0');
      else
        trig_d(0)  <= trig_a_i and tag_enable;
        trig_d(1)  <= trig_d(0) and tag_enable_d(0);
        trig_d(2)  <= trig_d(1) and tag_enable_d(1);
        trig_pulse <= (trig_d(1) and not trig_d(2)) and tag_enable_d(2);

        tag_enable_d(0) <= tag_enable;
        tag_enable_d(1) <= tag_enable_d(0);
        tag_enable_d(2) <= tag_enable_d(1);
      end if;
    end if;
  end process;

-- Process:  p_host_driven_signals
-- Inputs:   tdcsr_(stop/start)_(dis/en)_i 
-- Outputs:  host_(stop/start)_dis
--
-- Process for handling host commands controlling the state of stop/start
-- disable lines of the ACAM. These are only in effect when the TDC is
-- controlled by the host (GCR_BYPASS = 1).

  p_host_driven_signals : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_n_i = '0') then
        host_stop_dis  <= '1';
        host_start_dis <= '1';
      else

        -- the host wrote '1' to stop_dis bit in TDCSR - disable stop input
        if(regs_i.tdcsr_stop_dis_o = '1') then
          host_stop_dis <= '1';
          -- the host wrote '1' to stop_en bit - enable stop input
        elsif(regs_i.tdcsr_stop_en_o = '1') then
          host_stop_dis <= '0';
        end if;

        -- the same for start disable signal
        if(regs_i.tdcsr_start_dis_o = '1') then
          host_start_dis <= '1';
        elsif(regs_i.tdcsr_start_en_o = '1') then
          host_start_dis <= '0';
        end if;
      end if;
    end if;
  end process;


-- Process:  p_gen_acam_stop
-- Inputs:   GCR.BYPASS, GCR.INPUT_EN, tag_enable, start_pulse_generated
-- Outputs:  acam_stop_dis_o
--
-- ACAM StopDis signal generation. Controls the effective input sampling window
-- of the TDC.
  p_gen_acam_stop : process(clk_ref_i)
  begin
    if(rising_edge(clk_ref_i)) then

-- right after reset, disable the stop signal to prevent the TDC from generating
-- rubbish timestamps before it's properly configured.
      if rst_n_i = '0' then
        acam_stop_dis_o <= '1';
      else

-- BYPASS mode: the TDC is controlled by the host, just pass whatever the host
-- wants.
        if(regs_i.gcr_bypass_o = '1') then
          acam_stop_dis_o <= host_stop_dis;
        else

-- unmask the stop signal only if:
-- - the trigger input is enabled by the host
-- - we are not waiting for REARM command
-- - we have generated at least one valid TDC start pulse (so the TDC has some
--   meaningful reference
          if(regs_i.gcr_input_en_o = '0' or tag_enable = '0' or start_ok = '0' or mask_stop = '1') then
            acam_stop_dis_o <= '1';
          else
            acam_stop_dis_o <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

-- Process: p_gen_acam_start_dis
-- Inputs: GCR.BYPASS, start_count
-- Outputs: stsrt_o, acam_start_dis_o
--
-- Generates the start disable signal for ACAM and Start OK signal (which unmasks
-- for enabling the pulse input).
  p_gen_acam_start_dis : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_n_i = '0') then
        start_ok_sreg    <= (others => '0');
        acam_start_dis_o <= '1';
      else
        -- Host control? just pass the whatever the host decides to the start
        -- disable pin
        if(regs_i.gcr_bypass_o = '1') then
          acam_start_dis_o <= host_start_dis;
          start_ok_sreg    <= (others => '0');
        else
          -- Enable the start input at proper moment to ensure that the 7.125 MHz
          -- "start clock" cycle is not cut.
          if(start_count = x"e") then
            -- advance the start OK shift register with another one.
            start_ok_sreg    <= start_ok_sreg(start_ok_sreg'left-1 downto 0) & '1';
            acam_start_dis_o <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- we assume that the TDC is correctly referenced after start_ok_sreg'length
  -- issued start pulses.
  start_ok <= '1' when (unsigned(not start_ok_sreg) = 0) else '0';


-- Processes: p_sync_tdclk_fedge, p_sync_tdclk_redge
-- Input: tdc_start_i
-- Output: tdc_start_d
--
-- A synchronizer chain for detecting the relation between clk_tdc_i
-- and clk_ref_i. Since both clocks are almost in phase, the first stage
-- reacts to the falling edge of the reference clock to satisfy setup/hold
-- requirements.
-- 
  p_sync_tdclk_fedge : process(clk_ref_i)
  begin
    if falling_edge(clk_ref_i) then
      tdc_start_d(0) <= tdc_start_i;
    end if;
  end process;

  p_sync_tdclk_redge : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      tdc_start_d(1) <= tdc_start_d(0);
      tdc_start_d(2) <= tdc_start_d(1);
    end if;
  end process;

  -- Process: p_sync_acam_ef
  -- Input: acam_ef_i
  -- Output: acam_ef_d1
  --
  -- Synchronizer chain for ACAM empty flag signal
  p_sync_acam_ef : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      acam_ef_d(0) <= acam_ef_i;
      acam_ef_d(1) <= acam_ef_d(0);
    end if;
  end process;

-------------------------------------------------------------------------------
-- Time Base Counters
-------------------------------------------------------------------------------  

-- Start counter: counts the number of clk_ref_i cycles from the last TDC start
-- event.

  p_start_subcycle_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      
      if rst_n_i = '0' or regs_i.gcr_bypass_o = '1' then
        start_count     <= (others => '0');
        subcycle_offset <= (others => '0');
        advance_coarse  <= '0';
      else

        -- External resynchronization: it's a bit tricky, because resync event
        -- can come at any moment (with respect to the TDC start pulse). So,
        -- instead of reeloading start_count, we simply store the difference
        -- between the current start count and the LSBs of the new time value
        -- and correct the timestamps later on.
        if(csync_p1_i = '1') then
          subcycle_offset <= signed('0' & csync_coarse_i(3 downto 0)) - signed('0' & start_count) - 1;
        end if;

        -- Rising edge on TDC_START? Resynchronize the counter, to go to zero
        -- right after the edge.
        if(tdc_start_d(1) = '1' and tdc_start_d(2) = '0') then
          start_count    <= x"2";
          advance_coarse <= '0';
        else
          -- Start cycle expired - advance the 128 ns x counter. We do that one
          -- cycle in advance using a register to relax the P&R timing.
          if(start_count = x"e") then
            advance_coarse <= '1';
          else
            advance_coarse <= '0';
          end if;

          start_count <= start_count + 1;
        end if;
      end if;
    end if;
  end process;

  -- Coarse counter - counts up at every TDC start pulse, up to one second.
  p_coarse_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' or regs_i.gcr_bypass_o = '1' then
        coarse_count <= (others => '0');
      else
        -- External resync event: reload the counter with new time value. A
        -- special case is executed when the resync event came at the same moment as the
        -- overflow of start_count.
        if(csync_p1_i = '1') then
          if(advance_coarse = '1') then
            coarse_count <= unsigned(csync_coarse_i(27 downto 4)) + 1;
          else
            coarse_count <= unsigned(csync_coarse_i(27 downto 4));
          end if;
        elsif(advance_coarse = '1') then
          -- well, just boringly count up
          if(coarse_count = (g_clk_ref_freq / 16) - 1) then
            coarse_count <= (others => '0');
          else
            coarse_count <= coarse_count + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Seconds counter: count up when coarse_count counter has overflown.
  p_seconds_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_n_i = '0') then
        utc_count <= (others => '0');
      else
        if(csync_p1_i = '1') then
          if(advance_coarse = '1' and coarse_count = (g_clk_ref_freq / 16) -1) then
            -- I hate special cases!
            utc_count <= unsigned(csync_utc_i) + 1;
          else
            utc_count <= unsigned(csync_utc_i);
          end if;
          
        elsif(advance_coarse = '1' and coarse_count = (g_clk_ref_freq / 16) - 1) then
          utc_count <= utc_count + 1;
        end if;
      end if;
    end if;
  end process;

  -- Host-driven TDC data register. Used to pass commands to the TDC directly
  -- from the host (initial configuration & calibration)
  p_tdr_register : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_n_i = '0') then
        acam_wdata <= (others => '0');
      else
        if(regs_i.tdr_load_o = '1') then
          acam_wdata <= regs_i.tdr_o;
        end if;
      end if;
    end if;
  end process;

  -- Main state machine. Inputs a lot, outputs even more.
  p_main_fsm : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then

      if(rst_n_i = '0') then
        afsm_state <= IDLE;

        regs_out_int.tdr_i <= (others => '0');

        acam_d_oe_o    <= '0';
        acam_d_o       <= (others => '0');
        acam_rd_n_o    <= '1';
        acam_wr_n_o    <= '1';
        acam_reset_int <= '0';

        timeout_counter <= (others => '0');

        raw_tag_valid        <= '0';
        raw_tag_start_offset <= (others => '0');
        raw_tag_coarse       <= (others => '0');
        raw_tag_utc          <= (others => '0');
        raw_tag_frac         <= (others => '0');

        tag_enable <= '0';

        gcr_input_en_d0 <= '0';

        mask_stop <= '0';
        
      else

        gcr_input_en_d0 <= regs_i.gcr_input_en_o;

        case afsm_state is

          -- IDLE state: we are waiting for a pulse to come, the TDC is
          -- disabled or controlled directly by the host
          when IDLE =>
            raw_tag_valid <= '0';

            -- TDC controlled by the host
            if(regs_i.gcr_bypass_o = '1') then
              acam_reset_int <= regs_i.tdcsr_alutrig_o;

              tag_enable     <= '0';

              -- Handle host reads/writes
              if(regs_i.tdcsr_write_o = '1') then
                afsm_state <= W_DATA_ADDR;
              elsif(regs_i.tdcsr_read_o = '1') then
                afsm_state <= R_ADDR;
              end if;

              -- TDC working in R-Mode and handled by the FD logic
            elsif(regs_i.gcr_input_en_o = '1') then
              acam_reset_int <= '0';

              acam_rd_n_o <= '1';
              acam_wr_n_o <= '1';

              if(start_ok = '1' and trig_pulse = '0' and tag_rearm_p1_i = '1' and gcr_input_en_d0 = '1') then
                tag_enable <= '1';
                mask_stop <= '0';
              end if;

              -- Got a trigger pulse?
              if(trig_pulse = '1' and tag_enable = '1' and start_ok = '1') then
                mask_stop <= '1';
                
                -- start checking its width 
                afsm_state <= RMODE_MEASURE_WIDTH;

                -- store the coarse timestamp
                raw_tag_coarse       <= coarse_count;
                raw_tag_start_offset <= start_count;
                raw_tag_utc          <= utc_count;

                timeout_counter                                  <= (others => '0');

                -- width checking is done using shift register
                width_check_sreg(0)                              <= '1';
                width_check_sreg(width_check_sreg'left downto 1) <= (others => '0');
                width_check_mask                                 <= (others => '0');
              end if;
            else
              -- Input is disabled - mask the trigger input.
              tag_enable <= '0';
            end if;

            acam_d_oe_o <= '0';

          -- Pulse width measuring state: shift in the trigger line to a register.
          -- If it's all ones, the pulse is wide enough. ACAM will be busy
          -- during that time tagging the pulse, so it doesn't impact the
          -- throughput (at least for our minimum pulse width of 24 ns).
          when RMODE_MEASURE_WIDTH =>
            width_check_mask <= width_check_mask(width_check_mask'left-1 downto 0) & trig_d(2);
            width_check_sreg <= width_check_sreg(width_check_sreg'left-1 downto 0) & '0';

            -- The other sreg is used as a counter.
            if(width_check_sreg(width_check_sreg'left) = '1') then
              afsm_state <= RMODE_CHECK_WIDTH;
            end if;

          -- Pulse width (and FIFO) checker
          when RMODE_CHECK_WIDTH =>

-- Something arrived into the ACAM FIFO. Note that here we're using a
-- synchronized version of the signal, as it can go up asynchronously at any time (the processing
-- delay of the ACAM is not constant). This worsens the overall timestamping
-- latency, but ensures that the whole FSM will work correctly.

            if(acam_ef_d(1) = '0') then  -- FIFO not empty

-- check the pulse width. If its too low, purge all timestamps from the FIFO
-- (the "pulse" might have been as well a series of short pulses, which FPGA
-- has not noticed but the TDC has)

              if(width_check_mask /= c_ones(width_check_mask'left downto 0)) then
                afsm_state <= RMODE_PURGE_FIFO;
                tag_enable <= '0';
              else
---- pulse width check passed
                afsm_state  <= RMODE_READ_PULSE;  -- initiate timestamp readout
                acam_rd_n_o <= '0';
                tag_enable  <= '0';
              end if;

-- if the FIFO stays empty for too long after the input event, something must have
-- gone horribly wrong (a glitch?). There we have a timeout counter to make sure
-- the FSM won't get stuck.
            else
              timeout_counter <= timeout_counter + 1;
              if(timeout_counter = c_ACAM_TIMEOUT) then
                afsm_state <= IDLE;
                tag_enable <= '1';
              end if;
            end if;

-- Readout. These two states are simply to extend the RdN negative pulse to
-- avoid rise/fall time SI issues.
          when RMODE_READ_PULSE =>
            afsm_state <= RMODE_READ_PULSE2;

          when RMODE_READ_PULSE2 =>
            afsm_state <= RMODE_READ;

          when RMODE_READ =>

-- store the fine tag
            raw_tag_frac <= signed(acam_d_i(raw_tag_frac'left downto 0));

            acam_rd_n_o <= '1';

            -- check if the FIFO has become empty after the readout. If it didn't, the TDC
            -- must have tagged another rising edge on the trigger input, which
            -- could only have been caused by a glitch or a series of short
            -- pulses in the input signal. In such situation the event must be rejected.
            -- Note that here we're using the asynchronous empty flag signal directly - ACAM
            -- documentation says that it must go up max. 11.8 ns after the
            -- negative edge on the RdN signal. Since our RdN pulse lasts
            -- for 24 ns, there should be no risk of metastability.

            if(acam_ef_i = '1') then
              afsm_state    <= IDLE;
              raw_tag_valid <= '1';
              tag_enable    <= '0';
            else
              
              afsm_state <= RMODE_PURGE_FIFO;
              tag_enable <= '0';
            end if;

-- Purge FIFO state: read out all data remaining in the ACAM fifo after when a
-- glitchy pulse occured.
          when RMODE_PURGE_FIFO =>
            acam_rd_n_o <= '0';
            afsm_state  <= RMODE_PURGE_WAIT;

-- RD_n width extension (SI)
          when RMODE_PURGE_WAIT =>
            afsm_state <= RMODE_PURGE_WAIT2;

          when RMODE_PURGE_WAIT2 =>
            afsm_state <= RMODE_PURGE_CHECK_EMPTY;

-- Check if the FIFO is empty, if not - remove the next word
          when RMODE_PURGE_CHECK_EMPTY =>
            acam_rd_n_o <= '1';
            if(acam_ef_i = '0') then
              afsm_state <= RMODE_PURGE_FIFO;
            else
              tag_enable <= '1';
              afsm_state <= IDLE;
            end if;

-- Host ACAM access: W_states: writes, R_states: reads.
          when W_DATA_ADDR =>
            acam_d_o    <= acam_wdata;
            acam_d_oe_o <= '1';
            afsm_state  <= W_PULSE;

          when W_PULSE =>
            acam_wr_n_o <= '0';
            afsm_state  <= W_WAIT;

          when W_WAIT =>
            acam_wr_n_o <= '1';
            afsm_state  <= IDLE;

          when R_ADDR =>
            acam_d_oe_o <= '0';
            afsm_state  <= R_ADDR2;

          when R_ADDR2 =>
            afsm_state <= R_PULSE;

          when R_PULSE =>
            acam_rd_n_o <= '0';
            afsm_state  <= R_EXTEND_R_PULSE1;

          when R_EXTEND_R_PULSE1 =>
            afsm_state <= R_EXTEND_R_PULSE2;

          when R_EXTEND_R_PULSE2 =>
            afsm_state <= R_READ;

          when R_READ =>
            regs_out_int.tdr_i <= acam_d_i;
            afsm_state         <= R_END_CYCLE;

          when R_END_CYCLE =>
            acam_rd_n_o <= '1';
            afsm_state  <= IDLE;
        end case;
      end if;
    end if;
  end process;

  dbg_o(0) <= raw_tag_valid;
  dbg_o(1) <= trig_d(2);
  dbg_o(2) <= tag_valid_int;

  -- Extend the alutrigger pulse to avoid rise/fall time issues
  U_Alutrig_Driver : gc_extend_pulse
    generic map (
      g_width => 3)
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_n_i,
      pulse_i    => acam_reset_int,
      extended_o => acam_alutrigger_o);

  U_Stat_Unit : fd_timestamper_stat_unit
    port map (
      clk_ref_i       => clk_ref_i,
      rst_n_i         => rst_n_i,
      trig_pulse_i    => trig_pulse,
      raw_tag_valid_i => raw_tag_valid,
      regs_i          => regs_i,
      regs_o          => regs_out_stat);

  U_Timestamp_Postprocessor : fd_acam_timestamp_postprocessor
    generic map (
      g_frac_bits => g_frac_bits)
    port map (
      clk_ref_i              => clk_ref_i,
      rst_n_i                => rst_n_i,
      raw_valid_i            => raw_tag_valid,
      raw_utc_i              => std_logic_vector(raw_tag_utc),
      raw_coarse_i           => std_logic_vector(raw_tag_coarse),
      raw_frac_i             => std_logic_vector(raw_tag_frac),
      raw_start_offset_i     => std_logic_vector(raw_tag_start_offset),
      acam_subcycle_offset_i => std_logic_vector(subcycle_offset),
      tag_valid_o            => tag_valid_int,
      tag_utc_o              => tag_utc_o,
      tag_coarse_o           => tag_coarse,
      tag_frac_o             => tag_frac_o,
      regs_i                 => regs_i);

  regs_o <= regs_out_stat or regs_out_int;  -- combine the two stucts

  tag_valid_o  <= tag_valid_int;
  tag_coarse_o <= tag_coarse;
end behavioral;
