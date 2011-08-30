-------------------------------------------------------------------------------
-- Title      : ACAM TDC-GPX Timestamper
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_acam_timestamper.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2011-08-30
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: A complete sub-nanosecond pulse timestamper based on ACAM's
-- TDC-GPX chip. 
-------------------------------------------------------------------------------
-- Copyright (c) 2011 CERN / BE-CO-HT
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2011-08-24  1.0      slayer  Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;                 -- for real types, used in
                                        -- precalculation of scalefactors

use work.fd_wbgen2_pkg.all;             -- for Wishbone regs

library work;

entity fd_acam_timestamper is
  generic(
    -- minimum input pulse width in clk_ref_i cycles
    g_min_pulse_width : natural := 3;   -- clk_ref_i frequency in Hz
    g_clk_ref_freq    : integer := 125000000;
    g_frac_bits       : integer := 13
    );
  port (

-------------------------------------------------------------------------------
-- Clocks / Resets / Triggers
-------------------------------------------------------------------------------

-- System reference clock (125 MHz coming from the FMC PLL)
    clk_ref_i : in std_logic;

-- reset, active LOW
    rst_n_i : in std_logic;

-- Inverted ACAM trigger input
    trig_a_n_i : in std_logic;

-- TDC Start singnal (i.e. 7.8125 MHz slow clock synchronous to clk_ref_i)
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

-- ACAM address bus
    acam_a_o : out std_logic_vector(3 downto 0);

-- ACAM chip select, read and write enables (all active LOW)
    acam_cs_n_o : out std_logic;
    acam_rd_n_o : out std_logic;
    acam_wr_n_o : out std_logic;

-- ACAM FIFO empty flag
    acam_ef_i : in std_logic;

-- ACAM start&stop disable
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
    tag_coarse_o : out std_logic_vector(27 downto 0);

-- UTC part of the time tag (in seconds)
    tag_utc_o : out std_logic_vector(31 downto 0);

-- re-arm input. After tagging a pulse, the timestamper automatically disables the
-- trigger input until a positive pulse is delivered to tag_rearm_p1_i. If we want
-- the timestamps to be produced continously, tag_rearm_p1_i can be
-- peramamently driven HI
    tag_rearm_p1_i : in std_logic;

-- single-cycle pulse indicates presence of a valid time tag on the tag_xxx_o lines.
    tag_valid_o : out std_logic;

-------------------------------------------------------------------------------
-- Time base synchronization/alignment (clk_ref_i domain). Must not be used
-- when the timestamper input is enabled, as it will likely produce broken timestamps
-- during resynchronization
-------------------------------------------------------------------------------

-- New value of the coarse counter (125 MHz ticks)
    csync_coarse_i : in std_logic_vector(27 downto 0);

-- New value of the UTC counter
    csync_utc_i : in std_logic_vector(31 downto 0);

-- Single-cycle pulse aligns the local timebase counter with csync_coarse_i and
-- csync_utc_i.
    csync_p1_i : in std_logic;

---------------------------------------------------------------------------
-- Wishbone registers
---------------------------------------------------------------------------

    regs_b : inout t_fd_registers
    );

end fd_acam_timestamper;

architecture behavioral of fd_acam_timestamper is

  component fd_ts_adder
    generic (
      g_frac_bits    : integer;
      g_coarse_bits  : integer;
      g_utc_bits     : integer;
      g_coarse_range : integer);
    port (
      clk_i      : in  std_logic;
      rst_n_i    : in  std_logic;
      valid_i    : in  std_logic;
      a_utc_i    : in  std_logic_vector(g_utc_bits-1 downto 0);
      a_coarse_i : in  std_logic_vector(g_coarse_bits-1 downto 0);
      a_frac_i   : in  std_logic_vector(g_frac_bits-1 downto 0);
      b_utc_i    : in  std_logic_vector(g_utc_bits-1 downto 0);
      b_coarse_i : in  std_logic_vector(g_coarse_bits-1 downto 0);
      b_frac_i   : in  std_logic_vector(g_frac_bits-1 downto 0);
      valid_o    : out std_logic;
      q_utc_o    : out std_logic_vector(g_utc_bits-1 downto 0);
      q_coarse_o : out std_logic_vector(g_coarse_bits-1 downto 0);
      q_frac_o   : out std_logic_vector(g_frac_bits-1 downto 0));
  end component;

  constant c_ACAM_TIMEOUT : integer := 60;
  constant c_SCALER_SHIFT : integer := 12;

  -- states of the main ACAM FSM reading/writing data from/to the TDC
  type t_acam_fsm_state is (IDLE, R_ADDR, R_PULSE, R_READ, W_DATA_ADDR, W_PULSE, W_WAIT,
                            RMODE_PURGE_FIFO,
                            RMODE_PURGE_WAIT,
                            RMODE_PURGE_CHECK_EMPTY,
                            RMODE_READ,
                            RMODE_READ_PULSE,
                            RMODE_READ_PULSE2,
                            R_EXTEND_R_PULSE,
                            RMODE_CHECK_WIDTH,
                            RMODE_MEASURE_WIDTH);

  -- states of the diagnostic FSM measuring timestamper processing delays
  type t_pdelay_meas_state is (PD_WAIT_TRIGGER, PD_WAIT_TAG, PD_UPDATE_STATS);

  -- states of the start signal generator FSM
  type t_start_gen_state is (SG_RESYNC, SG_COUNT);

  signal afsm_state : t_acam_fsm_state;
  signal acam_wdata : std_logic_vector(27 downto 0);

  signal acam_reset_int : std_logic;
  signal tag_enable     : std_logic;

  -- stat counters signals
  signal event_count_raw    : unsigned(31 downto 0);
  signal event_count_tagged : unsigned(31 downto 0);

  signal pd_state     : t_pdelay_meas_state;
  signal cur_pdelay   : unsigned(7 downto 0);
  signal worst_pdelay : unsigned(7 downto 0);

  signal start_gen_state : t_start_gen_state;

  signal advance_coarse : std_logic;

  -- delay/sync chains
  signal tdc_start_d : std_logic_vector(2 downto 0);
  signal trig_d      : std_logic_vector(2 downto 0);
  signal acam_ef_d   : std_logic_vector(1 downto 0);

  signal trig_pulse : std_logic;

  -- counters (internal time base)
  signal start_count  : unsigned(3 downto 0);
  signal coarse_count : unsigned(23 downto 0);
  signal utc_count    : unsigned(31 downto 0);

  signal subcycle_offset : signed(4 downto 0);

  -- raw time tag (unprocessed)
  signal raw_tag_valid        : std_logic;
  signal raw_tag_coarse       : unsigned(23 downto 0);
  signal raw_tag_frac         : unsigned(22 downto 0);
  signal raw_tag_start_offset : unsigned(3 downto 0);
  signal raw_tag_utc          : unsigned(31 downto 0);

  -- post-processed tag
  signal post_tag_coarse      : unsigned(27 downto 0);
  signal post_tag_frac        : unsigned(g_frac_bits-1 downto 0);
  signal post_tag_utc         : unsigned(31 downto 0);
  signal post_frac_multiplied : signed(c_SCALER_SHIFT + g_frac_bits + 8 downto 0);
  signal post_frac_start_adj  : unsigned(22 downto 0);

  signal pp_pipe : std_logic_vector(2 downto 0);

  signal width_check_sreg : std_logic_vector(g_min_pulse_width-2 downto 0);
  signal width_check_mask : std_logic_vector(g_min_pulse_width-2 downto 0);

  constant c_ones : std_logic_vector(31 downto 0) := x"ffffffff";

  signal timeout_counter : unsigned(5 downto 0);

  signal host_start_dis : std_logic;
  signal host_stop_dis  : std_logic;


  signal start_ok_sreg : std_logic_vector(2 downto 0);
  signal start_ok      : std_logic;

  signal dbg_utc    : unsigned(31 downto 0);
  signal dbg_coarse : unsigned(27 downto 0);
  
begin  -- behave

  regs_b <= c_fd_registers_init_value;

-- Process: p_sync_trigger
-- Inputs: trig_a_n_i, tag_enable
-- Outputs: trig_pulse, trig_d
--
-- Synchronizer chain for the asynchronous trigger signal. The trigger is also
-- inverted (since it's driven onboard by a 1GU04 inverting buffer). The sync
-- chain is enabled when (tag_enable = '1') and produces a single-cycle pulse
-- on trig_pulse upon each rising edge in the input signal.

  p_sync_trigger : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      trig_d(0)  <= trig_a_n_i or (not tag_enable);
      trig_d(1)  <= not trig_d(0) and tag_enable;
      trig_d(2)  <= trig_d(1) and tag_enable;
      trig_pulse <= (trig_d(1) and not trig_d(2)) and tag_enable;
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
        if(regs_b.tdcsr_stop_dis_o = '1') then
          host_stop_dis <= '1';
        -- the host wrote '1' to stop_en bit - enable stop input
        elsif(regs_b.tdcsr_stop_en_o = '1') then
          host_stop_dis <= '0';
        end if;

        -- the same for start disable signal
        if(regs_b.tdcsr_start_dis_o = '1') then
          host_start_dis <= '1';
        elsif(regs_b.tdcsr_start_en_o = '1') then
          host_start_dis <= '0';
        end if;
      end if;
    end if;
  end process;


-- Process:  p_gen_acam_stop
-- Inputs:   gcr_bypass_i, gcr_input_en_i, tag_enable, start_pulse_generated
-- Outputs:  acam_stop_dis_o
--
-- ACAM StopDis signal generation

  p_gen_acam_stop : process(clk_ref_i)
  begin
    if(rising_edge(clk_ref_i)) then
-- right after reset, disable the stop signal to prevent the TDC from generating
-- rubbish timestamps before it's properly configured.
      if rst_n_i = '0' then
        acam_stop_dis_o <= '1';
      else

        if(regs_b.gcr_bypass_o = '1') then  -- the TDC is controlled by the host
          acam_stop_dis_o <= host_stop_dis;
        else

-- unmask the stop signal only if:
-- - the trigger input is enabled by the host
-- - timestamping has not been disabled by the delay unit
-- - we have generated at least one valid TDC start pulse
          if(regs_b.gcr_input_en_o = '0' or tag_enable = '0' or start_ok = '0') then
            acam_stop_dis_o <= '1';
          else
            acam_stop_dis_o <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

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

  p_start_subcycle_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      
      if rst_n_i = '0' or regs_b.gcr_bypass_o = '1' then
        start_count     <= (others => '0');
        subcycle_offset <= (others => '0');
        advance_coarse  <= '0';
      else
        if(csync_p1_i = '1') then
          subcycle_offset <= signed('0' & csync_coarse_i(3 downto 0)) - signed('0' & start_count) - 1;
        end if;

        if(tdc_start_d(1) = '1' and tdc_start_d(2) = '0') then
          start_count    <= x"2";
          advance_coarse <= '0';
        else
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



  p_gen_acam_start_dis : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_n_i = '0') then
        start_ok_sreg    <= (others => '0');
        acam_start_dis_o <= '1';
      else
        if(regs_b.gcr_bypass_o = '1' or regs_b.gcr_input_en_o = '0') then
          acam_start_dis_o <= host_start_dis;
          start_ok_sreg    <= (others => '0');
        else
          if(start_count = x"e") then
            start_ok_sreg    <= start_ok_sreg(start_ok_sreg'left-1 downto 0) & '1';
            acam_start_dis_o <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  start_ok <= '1' when (unsigned(not start_ok_sreg) = 0) else '0';

  p_coarse_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' or regs_b.gcr_bypass_o = '1' then
        coarse_count <= (others => '0');
      else

        if(csync_p1_i = '1') then
          if(advance_coarse = '1') then
            coarse_count <= unsigned(csync_coarse_i(27 downto 4)) + 1;
          else
            coarse_count <= unsigned(csync_coarse_i(27 downto 4));
          end if;
        elsif(advance_coarse = '1') then
          if(coarse_count = (g_clk_ref_freq / 16) - 1) then
            coarse_count <= (others => '0');
          else
            coarse_count <= coarse_count + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  p_utc_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_n_i = '0') then
        utc_count <= (others => '0');
      else
        if(csync_p1_i = '1') then
          --if(advance_coarse = '1') then
          --  utc_count <= unsigned(csync_utc_i) + 1;
          --else
            utc_count <= unsigned(csync_utc_i);
          --end if;
          
        elsif(advance_coarse = '1' and coarse_count = (g_clk_ref_freq / 16) - 1) then
          utc_count <= utc_count + 1;
        end if;
      end if;
    end if;
  end process;

  p_tar_register : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_n_i = '0') then
        acam_wdata <= (others => '0');
      else
        if(regs_b.tar_data_load_o = '1') then
          acam_wdata <= regs_b.tar_data_o;
        end if;
      end if;
    end if;
  end process;

  dbg_utc    <= unsigned(utc_count);
  dbg_coarse <= unsigned(signed(coarse_count & start_count) + subcycle_offset);


  p_main_fsm : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      
      if(rst_n_i = '0') then
        afsm_state <= IDLE;

        regs_b.tar_data_i <= (others => '0');

        acam_d_oe_o    <= '0';
        acam_d_o       <= (others => '0');
        acam_cs_n_o    <= '1';
        acam_rd_n_o    <= '1';
        acam_wr_n_o    <= '1';
        acam_a_o       <= (others => '0');
        acam_reset_int <= '0';

        timeout_counter <= (others => '0');

        raw_tag_valid        <= '0';
        raw_tag_start_offset <= (others => '0');
        raw_tag_coarse       <= (others => '0');
        raw_tag_utc          <= (others => '0');
        raw_tag_frac         <= (others => '0');

        tag_enable <= '0';
        
      else
        case afsm_state is
          when IDLE =>
            raw_tag_valid <= '0';
            -- TDC controlled by the host
            if(regs_b.gcr_bypass_o = '1') then
              acam_reset_int <= '0';
              tag_enable     <= '0';


              if(regs_b.tdcsr_write_o = '1') then
                afsm_state <= W_DATA_ADDR;
              elsif(regs_b.tdcsr_read_o = '1') then
                afsm_state <= R_ADDR;
              end if;

            -- TDC working in R-Mode and handled by the FD logic
            elsif(regs_b.gcr_input_en_o = '1') then
              acam_reset_int <= '0';

              acam_a_o    <= x"8";      -- permamently select FIFO1 register
              acam_cs_n_o <= '0';       -- permamently enable the chip
              acam_rd_n_o <= '1';
              acam_wr_n_o <= '1';

              if(tag_rearm_p1_i = '1') then
                tag_enable <= '1';
              end if;

              if(trig_pulse = '1' and tag_enable = '1') then
                
                afsm_state <= RMODE_MEASURE_WIDTH;

                raw_tag_coarse       <= coarse_count;
                raw_tag_start_offset <= start_count;
                raw_tag_utc          <= utc_count;

                timeout_counter                                  <= (others => '0');
                width_check_sreg(0)                              <= '1';
                width_check_sreg(width_check_sreg'left downto 1) <= (others => '0');
                width_check_mask                                 <= (others => '0');
              end if;
            end if;

            acam_d_oe_o <= '0';

          when RMODE_MEASURE_WIDTH =>
            width_check_mask <= width_check_mask(width_check_mask'left-1 downto 0) & trig_d(2);
            width_check_sreg <= width_check_sreg(width_check_sreg'left-1 downto 0) & '0';

            if(width_check_sreg(width_check_sreg'left) = '1') then
              afsm_state <= RMODE_CHECK_WIDTH;
            end if;
            
          when RMODE_CHECK_WIDTH =>

-- something arrived into the ACAM FIFO. Note that here we're using a
-- synchronized version of the signal, as it can go up anytime (the processing
-- delay of the ACAM is not constant). This worsens the overall timestamping
-- latency, but ensures the whole FSM will work correctly.

            if(acam_ef_d(1) = '0')then  -- FIFO not empty

-- check the pulse width. If its too low, purge all timestamps from the FIFO
-- (the pulse might have been as well a series of short pulses, which FPGA
-- didn't notice but the TDC did)

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
-- gone horriby wrong (a glitch?). There we have a timeout counter to make sure
-- the FSM won't get stuck.
            else
              timeout_counter <= timeout_counter + 1;
              if(timeout_counter = c_ACAM_TIMEOUT) then
                afsm_state <= IDLE;
                tag_enable <= '1';
              end if;
            end if;

-- Readout. These two states are simply to extend the RdN negative pulse
          when RMODE_READ_PULSE =>
            afsm_state <= RMODE_READ_PULSE2;

          when RMODE_READ_PULSE2 =>
            afsm_state <= RMODE_READ;

          when RMODE_READ =>

-- store the time tag
            raw_tag_frac <= unsigned(acam_d_i(raw_tag_frac'left downto 0));

            acam_rd_n_o <= '1';

            -- check if the FIFO became empty after the readout. If it didn't, the TDC
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

          when RMODE_PURGE_FIFO =>
            acam_rd_n_o <= '0';
            afsm_state  <= RMODE_PURGE_WAIT;

          when RMODE_PURGE_WAIT =>
            afsm_state <= RMODE_PURGE_CHECK_EMPTY;

          when RMODE_PURGE_CHECK_EMPTY =>
            acam_rd_n_o <= '1';
            if(acam_ef_i = '0') then
              afsm_state <= RMODE_PURGE_FIFO;
            else
              tag_enable <= '1';
              afsm_state <= IDLE;
            end if;



          when W_DATA_ADDR =>
            acam_d_o    <= acam_wdata;
            acam_a_o    <= regs_b.tar_addr_o;
            acam_d_oe_o <= '1';
            afsm_state  <= W_PULSE;

          when W_PULSE =>
            acam_cs_n_o <= '0';
            acam_wr_n_o <= '0';
            afsm_state  <= W_WAIT;

          when W_WAIT =>
            acam_cs_n_o <= '1';
            acam_wr_n_o <= '1';
            afsm_state  <= IDLE;

          when R_ADDR =>
            acam_a_o    <= regs_b.tar_addr_o;
            acam_d_oe_o <= '0';
            afsm_state  <= R_PULSE;
          when R_PULSE =>
            acam_cs_n_o <= '0';
            acam_rd_n_o <= '0';
            afsm_state  <= R_EXTEND_R_PULSE;

          when R_EXTEND_R_PULSE =>
            afsm_state <= R_READ;

          when R_READ =>
            acam_cs_n_o       <= '1';
            acam_rd_n_o       <= '1';
            regs_b.tar_data_i <= acam_d_i;
            afsm_state        <= IDLE;

          when others => null;
        end case;
      end if;
    end if;
  end process;

  p_count_events : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if (rst_n_i = '0' or regs_b.gcr_input_en_o = '0' or regs_b.iepd_rst_stat_o = '1') then
        event_count_raw    <= (others => '0');
        event_count_tagged <= (others => '0');
      else
        if(trig_pulse = '1') then
          event_count_raw <= event_count_raw + 1;
        end if;

        if(raw_tag_valid = '1') then
          event_count_tagged <= event_count_tagged + 1;
        end if;
      end if;
    end if;
  end process;

  regs_b.iecraw_i <= std_logic_vector(event_count_raw);
  regs_b.iectag_i <= std_logic_vector(event_count_tagged);

  p_measure_processing_delay : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' or regs_b.gcr_input_en_o = '0' or regs_b.iepd_rst_stat_o = '1' then
        cur_pdelay   <= (others => '0');
        worst_pdelay <= (others => '0');
        pd_state     <= PD_WAIT_TRIGGER;
      else
        case pd_state is
          when PD_WAIT_TRIGGER =>
            if(trig_pulse = '1') then
              cur_pdelay <= (others => '0');
              pd_state   <= PD_WAIT_TAG;
            end if;

          when PD_WAIT_TAG =>
            if(raw_tag_valid = '1') then
              pd_state <= PD_UPDATE_STATS;
            else
              cur_pdelay <= cur_pdelay + 1;
            end if;

          when PD_UPDATE_STATS =>
            if(cur_pdelay > worst_pdelay) then
              worst_pdelay <= cur_pdelay;
            end if;
            pd_state <= PD_WAIT_TRIGGER;
            
          when others => null;
        end case;

        
      end if;
    end if;
  end process;

  regs_b.iepd_pdelay_i <= std_logic_vector(worst_pdelay);

  acam_alutrigger_o <= acam_reset_int;



  p_postprocess_tags : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        tag_valid_o  <= '0';
        tag_coarse_o <= (others => '0');
        tag_utc_o    <= (others => '0');
        tag_frac_o   <= (others => '0');
      else

--stage 1
        pp_pipe(0) <= raw_tag_valid;

        if (raw_tag_start_offset <= unsigned(regs_b.atmcr_c_thr_o)) and (raw_tag_frac > unsigned(regs_b.atmcr_f_thr_o)) then
          post_tag_coarse(post_tag_coarse'left downto 4) <= raw_tag_coarse - 1;
        else
          post_tag_coarse(post_tag_coarse'left downto 4) <= raw_tag_coarse;
        end if;
        post_frac_start_adj <= raw_tag_frac - unsigned(regs_b.asor_offset_o);

        post_tag_coarse(3 downto 0) <= (others => '0');
        post_tag_utc                <= raw_tag_utc;


--stage 2

        pp_pipe(1)           <= pp_pipe(0);
        post_frac_multiplied <= resize(signed(post_frac_start_adj) * signed(regs_b.adsfr_o), post_frac_multiplied'length);


--stage 3
        pp_pipe(2)   <= pp_pipe(1);
        tag_utc_o    <= std_logic_vector(post_tag_utc);
        tag_coarse_o <= std_logic_vector(raw_tag_coarse & raw_tag_start_offset);
        --tag_coarse_o   <= std_logic_vector(signed(post_tag_coarse) + signed(post_frac_multiplied(post_frac_multiplied'left downto c_SCALER_SHIFT + g_frac_bits)));
        tag_frac_o   <= std_logic_vector(post_frac_multiplied(c_SCALER_SHIFT + g_frac_bits-1 downto c_SCALER_SHIFT));
--        tag_raw_frac_o <= std_logic_vector(raw_tag_frac);

        tag_valid_o <= pp_pipe(2);

      end if;
    end if;
  end process;

  

end behavioral;
