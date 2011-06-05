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
    g_frac_bits       : integer := 12
    );
  port (

-------------------------------------------------------------------------------
-- Clocks / Resets / Triggers
-------------------------------------------------------------------------------

-- System reference clock (125 MHz)
    clk_ref_i : in std_logic;

-- reset, active LOW
    rst_n_i : in std_logic;

-- Inverted ACAM trigger input
    trig_a_n_i : in std_logic;

    tdc_start_i : in std_logic;

-------------------------------------------------------------------------------
-- ACAM TDC-GPX interface
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
-- Time tag I/O
-------------------------------------------------------------------------------

-- fractional part of the time tag (expressed as a number of ACAM bins)
    tag_frac_o : out std_logic_vector(g_frac_bits-1 downto 0);

-- coarse part of the time tag (in clk_ref_i cycles)
    tag_coarse_o : out std_logic_vector(27 downto 0);

-- UTC part of the time tag (in seconds)
    tag_utc_o      : out std_logic_vector(31 downto 0);
    tag_raw_frac_o : out std_logic_vector(22 downto 0);

-- re-arm input. The timestamper automatically disables the trigger input
-- until a positive pulse is delivered to tag_rearm_p1_i. If we want
-- the timestamps to be produced continously, tag_rearm_p1_i can be
-- peramamently driven HI
    tag_rearm_p1_i : in std_logic;

-- single-cycle pulse indicates presence of a valid time tag on the tag_xxx_o lines.
    tag_valid_p1_o : out std_logic;

-------------------------------------------------------------------------------
-- Counter synchronization
-------------------------------------------------------------------------------

-- New value of the coarse counter
    csync_coarse_i : in std_logic_vector(27 downto 0);

-- New value of the UTC counter
    csync_utc_i : in std_logic_vector(31 downto 0);

-- Counter load pulse (can be used only when the input is disabled)
    csync_p1_i : in std_logic;

---------------------------------------------------------------------------
-- Wishbone registers
---------------------------------------------------------------------------

    regs_b : inout t_fd_registers
    );

end fd_acam_timestamper;

architecture behavioral of fd_acam_timestamper is

  -- FIFO timeout in clk_ref_i cycles. If there's no data in the ACAM FIFO
  -- c_ACAM_TIMEOUT after the trigger pulse, we ignore it and reset the TDC.
  constant c_ACAM_TIMEOUT      : integer := 60;
  constant c_ACAM_START_OFFSET : integer := 10000;

  constant c_WRAPAROUND_START_THRESHOLD : integer := 1;
  constant c_WRAPAROUND_FRAC_THRESHOLD  : integer := 2000 + c_ACAM_START_OFFSET*3;


  constant c_REFCLK_PERIOD    : real    := 8000.0;
  constant c_ACAM_BIN_SIZE    : real    := 27.0127677;  -- ACAM bin size in picoseconds
  constant c_SCALER_SHIFT     : integer := 12;
  constant c_FRAC_SCALEFACTOR : integer := integer(real(2**(g_frac_bits + c_SCALER_SHIFT)) * c_ACAM_BIN_SIZE / c_REFCLK_PERIOD);


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

  -- states of the processing delay measurement FSM
  type t_pdelay_meas_state is (PD_WAIT_TRIGGER, PD_WAIT_TAG, PD_UPDATE_STATS);

  -- states of the start signal generator FSM
  type t_start_gen_state is (SG_RESYNC, SG_COUNT);

  -- states of the tag postprocessing FSM
  type t_postprocess_state is (WAIT_TAG_UNWRAP_ADJUST, RESCALE_FRAC, ADD_OFFSET, OUTPUT_TAG);

  signal pp_state   : t_postprocess_state;
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

  -- sync chains
  signal tdc_start_d : std_logic_vector(2 downto 0);

  signal acam_ef_d0 : std_logic;
  signal acam_ef_d1 : std_logic;

  -- counters (internal time base)
  signal start_count  : unsigned(3 downto 0);
  signal coarse_count : unsigned(23 downto 0);
  signal utc_count    : unsigned(31 downto 0);

  signal utc_offset    : unsigned(31 downto 0);
  signal coarse_offset : unsigned(27 downto 0);


  -- raw time tag (unprocessed)
  signal raw_tag_valid_p1     : std_logic;
  signal raw_tag_coarse       : unsigned(23 downto 0);
  signal raw_tag_frac         : unsigned(22 downto 0);
  signal raw_tag_start_offset : unsigned(3 downto 0);
  signal raw_tag_utc          : unsigned(31 downto 0);

  -- post-processed tag
  signal post_tag_coarse : unsigned(27 downto 0);
  signal post_tag_frac   : unsigned(g_frac_bits-1 downto 0);
  signal post_tag_utc    : unsigned(31 downto 0);

  signal post_frac_start_adj  : unsigned(22 downto 0);
  signal post_frac_multiplied : signed(c_SCALER_SHIFT + g_frac_bits + 8 downto 0);

  signal trig_d0, trig_d1, trig_d2, trig_pulse : std_logic;

  signal width_check_sreg : std_logic_vector(g_min_pulse_width-2 downto 0);
  signal width_check_mask : std_logic_vector(g_min_pulse_width-2 downto 0);

  constant c_ones : std_logic_vector(31 downto 0) := x"ffffffff";

  signal timeout_counter       : unsigned(5 downto 0);

  signal host_start_dis : std_logic;
  signal host_stop_dis  : std_logic;


  signal start_ok_sreg : std_logic_vector(2 downto 0);
  signal start_ok      : std_logic;

  
begin  -- behave

--  regs_b <= c_fd_registers_init_value;  -- drive to 'Z'

-- Process: p_sync_trigger
-- Inputs: trig_a_n_i, tag_enable
-- Outputs: trig_pulse, trig_d2
--
-- Synchronizer chain for the asynchronous trigger signal. The trigger is also
-- inverted (since it's driven onboard by a 1GU04 inverting buffer). The sync
-- chain is enabled when (tag_enable = '1') and produces a single-cycle pulse
-- on trig_pulse upon each rising edge in the input signal.

  p_sync_trigger : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      trig_d0    <= trig_a_n_i or (not tag_enable);
      trig_d1    <= not trig_d0 and tag_enable;
      trig_d2    <= trig_d1 and tag_enable;
      trig_pulse <= (trig_d1 and not trig_d2) and tag_enable;
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
      acam_ef_d0 <= acam_ef_i;
      acam_ef_d1 <= acam_ef_d0;
    end if;
  end process;

-- Process: p_gen_acam_start

  p_gen_acam_start : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_n_i = '0') then
        start_ok_sreg    <= (others => '0');
        acam_start_dis_o <= '1';
        start_gen_state  <= SG_RESYNC;
        start_count      <= (others => '0');
        advance_coarse   <= '0';
      else
        if(regs_b.gcr_bypass_o = '1') then
          acam_start_dis_o      <= host_start_dis;
          start_gen_state       <= SG_RESYNC;
          advance_coarse        <= '0';
          start_ok_sreg         <= (others => '0');
        elsif (regs_b.gcr_input_en_o = '0') then
          acam_start_dis_o      <= '1';
          start_gen_state       <= SG_RESYNC;
          advance_coarse        <= '0';
          start_ok_sreg         <= (others => '0');
        else
          
          case start_gen_state is
            when SG_RESYNC =>
              if(tdc_start_d(1) = '1' and tdc_start_d(2) = '0') then
                start_count     <= to_unsigned(2, 4);
                start_gen_state <= SG_COUNT;
              end if;

            when SG_COUNT =>
              start_count <= start_count + 1;
              if(start_count = x"e") then
                advance_coarse <= '1';
                acam_start_dis_o <= '0';
                start_ok_sreg <= start_ok_sreg(start_ok_sreg'left-1 downto 0) & '1';
              else
                advance_coarse <= '0';
              end if;
          end case;
        end if;
      end if;
    end if;
  end process;

  start_ok <= '1' when (unsigned(not start_ok_sreg) = 0) else '0';

  p_coarse_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        coarse_count <= (others => '0');
      else
        if(advance_coarse = '1') then
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
        if(advance_coarse = '1' and coarse_count = (g_clk_ref_freq / 16) - 1) then
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

        raw_tag_valid_p1     <= '0';
        raw_tag_start_offset <= (others => '0');
        raw_tag_coarse       <= (others => '0');
        raw_tag_utc          <= (others => '0');
        raw_tag_frac         <= (others => '0');

        tag_enable <= '0';
        
      else
        case afsm_state is
          when IDLE =>
            raw_tag_valid_p1 <= '0';
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
            width_check_mask <= width_check_mask(width_check_mask'left-1 downto 0) & trig_d2;
            width_check_sreg <= width_check_sreg(width_check_sreg'left-1 downto 0) & '0';

            if(width_check_sreg(width_check_sreg'left) = '1') then
              afsm_state <= RMODE_CHECK_WIDTH;
            end if;
            
          when RMODE_CHECK_WIDTH =>

-- something arrived into the ACAM FIFO. Note that here we're using a
-- synchronized version of the signal, as it can go up anytime (the processing
-- delay of the ACAM is not constant). This worsens the overall timestamping
-- latency, but ensures the whole FSM will work correctly.

            if(acam_ef_d1 = '0')then    -- FIFO not empty

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
              afsm_state       <= IDLE;
              raw_tag_valid_p1 <= '1';
              tag_enable       <= '0';
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
      if (rst_n_i = '0' or regs_b.gcr_input_en_o = '0' or regs_b.gcr_clr_stat_o = '1') then
        event_count_raw    <= (others => '0');
        event_count_tagged <= (others => '0');
      else
        if(trig_pulse = '1') then
          event_count_raw <= event_count_raw + 1;
        end if;

        if(raw_tag_valid_p1 = '1') then
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
      if rst_n_i = '0' or regs_b.gcr_input_en_o = '0' or regs_b.gcr_clr_stat_o = '1' then
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
            if(raw_tag_valid_p1 = '1') then
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

  regs_b.iepd_i <= std_logic_vector(worst_pdelay);

  acam_alutrigger_o <= acam_reset_int;

  p_postprocess_tags : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        tag_valid_p1_o       <= '0';
        tag_coarse_o         <= (others => '0');
        tag_utc_o            <= (others => '0');
        tag_frac_o           <= (others => '0');
        pp_state             <= WAIT_TAG_UNWRAP_ADJUST;
        post_frac_multiplied <= (others => '0');
        
      else
        case pp_state is
          when WAIT_TAG_UNWRAP_ADJUST =>
            if(raw_tag_valid_p1 = '1') then

                -- coarse part
                if(raw_tag_start_offset <= c_WRAPAROUND_START_THRESHOLD and raw_tag_frac > c_WRAPAROUND_FRAC_THRESHOLD) then
                  post_tag_coarse(post_tag_coarse'left downto 4) <= raw_tag_coarse - 1;
                else
                  post_tag_coarse(post_tag_coarse'left downto 4) <= raw_tag_coarse;
                end if;
                post_tag_coarse(3 downto 0) <= (others => '0');

                -- fine part

                post_frac_start_adj <= raw_tag_frac - (3*c_ACAM_START_OFFSET);
                pp_state <= OUTPUT_TAG;                       

                -- UTC part (unchanged in this step)
                post_tag_utc <= raw_tag_utc;

           
--              post_tag_coarse <= raw_tag_coarse & x"0";
--              post_tag_frac   <= raw_tag_frac (11 downto 0);
              pp_state        <= OUTPUT_TAG;
            end if;

            tag_valid_p1_o <= '0';

            --when RESCALE_FRAC =>
            --  post_frac_multiplied <= resize(signed(post_frac_start_adj) * c_FRAC_SCALEFACTOR, post_frac_multiplied'length);
            --  pp_state <= ADD_OFFSET;

            --when ADD_OFFSET =>

            --  post_tag_frac <= unsigned(post_frac_multiplied(c_SCALER_SHIFT + g_frac_bits-1 downto c_SCALER_SHIFT));
            --  post_tag_coarse <= unsigned(signed(post_tag_coarse) + signed(post_frac_multiplied(post_frac_multiplied'left downto c_SCALER_SHIFT + g_frac_bits)));


          when OUTPUT_TAG =>
            tag_utc_o      <= std_logic_vector(post_tag_utc);
            tag_coarse_o   <= std_logic_vector(post_tag_coarse);
            tag_frac_o     <= std_logic_vector(post_frac_start_adj(11 downto 0));
            tag_raw_frac_o <= std_logic_vector(raw_tag_frac);
            tag_valid_p1_o <= '1';

            pp_state <= WAIT_TAG_UNWRAP_ADJUST;
            

          when others => null;
        end case;
      end if;
    end if;
  end process;
  

end behavioral;
