-------------------------------------------------------------------------------
-- Title      : Precise Programmable Pulse Generator (single channel)
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_delay_channel_driver.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-06-01
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Programmable pulse generator, using a coarse counter running
-- followed by a programmable delay line (SY89295U) to achieve sub-nanosecond
-- precision. Generated pulses can start at an absolute time value (PULSE_GEN
-- mode) or certain time after an initial timestamp (DELAY mode). Pulse width
-- and spacing  can be also programmed (10ps resolution for spacings  and width
-- higher than 200 ns, 4ns for faster signals).
--
-- WARNING! Due to pipelining delays, the PG begins generation of a pulse
-- few cycles after it's desired start time - therefore, START/END registers
-- must be corrected to compensate for this delay. See fdelay library sources
-- for details.
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

use work.fine_delay_pkg.all;
use work.gencores_pkg.all;
use work.wishbone_pkg.all;
use work.fd_channel_wbgen2_pkg.all;

entity fd_delay_channel_driver is
  generic(
    g_index : integer);
  port(
    clk_ref_i   : in std_logic;
    clk_sys_i   : in std_logic;
    rst_n_ref_i : in std_logic;
    rst_n_sys_i : in std_logic;

    -- time base synchronization (from fd_csync_generator)
    csync_p1_i     : in std_logic;
    csync_utc_i    : in std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
    csync_coarse_i : in std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);

    -- 1: force a calibration pulse on the output
    gen_cal_i : in std_logic;

    -- Trigger timestamp input (from the TDC), used as a reference point in
    -- DELAY mode
    tag_valid_i  : in std_logic;
    tag_utc_i    : in std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
    tag_coarse_i : in std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
    tag_frac_i   : in std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);

    -- Start-of-first-output-pulse timestamp output. To ring buffer.
    pstart_valid_o  : out std_logic;
    pstart_utc_o    : out std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
    pstart_coarse_o : out std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
    pstart_frac_o   : out std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);

    -- Pulse output for the DDR driver (0 = in-phase, 1 = 180 degrees)
    delay_pulse0_o : out std_logic;
    delay_pulse1_o : out std_logic;

    -- SY89295 delay drive (arbitrated between 4 delay lines)
    delay_value_o     : out std_logic_vector(9 downto 0);
    delay_load_o      : out std_logic;
    delay_load_done_i : in  std_logic;

    -- 1: there's no pending pulse
    delay_idle_o : out std_logic;

    -- WB Interface (pipelined, byte-aligned)
    wb_i : in  t_wishbone_slave_in;
    wb_o : out t_wishbone_slave_out
    );

end fd_delay_channel_driver;

architecture behavioral of fd_delay_channel_driver is

  component fd_channel_wb_slave
    port (
      rst_n_i    : in  std_logic;
      clk_sys_i  : in  std_logic;
      wb_adr_i   : in  std_logic_vector(3 downto 0);
      wb_dat_i   : in  std_logic_vector(31 downto 0);
      wb_dat_o   : out std_logic_vector(31 downto 0);
      wb_cyc_i   : in  std_logic;
      wb_sel_i   : in  std_logic_vector(3 downto 0);
      wb_stb_i   : in  std_logic;
      wb_we_i    : in  std_logic;
      wb_ack_o   : out std_logic;
      wb_stall_o : out std_logic;
      clk_ref_i  : in  std_logic;
      regs_i     : in  t_fd_channel_in_registers;
      regs_o     : out t_fd_channel_out_registers);
  end component;



  procedure f_calc_delay_setpoint (
    signal t             : in  t_fd_timestamp;
    signal frr           : in  std_logic_vector(9 downto 0);
    signal setpoint      : out std_logic_vector(9 downto 0);
    signal first_falling : out std_logic) is
  begin
    if(unsigned(t.f) >= 2**(c_TIMESTAMP_FRAC_BITS-1)) then
      setpoint      <= std_logic_vector(resize(((unsigned(t.f) - to_unsigned(2**(c_TIMESTAMP_FRAC_BITS-1), c_TIMESTAMP_FRAC_BITS)) * unsigned(frr)) srl c_TIMESTAMP_FRAC_BITS, 10));
      first_falling <= '1';
    else
      setpoint      <= std_logic_vector(resize((unsigned(t.f) * unsigned(frr)) srl c_TIMESTAMP_FRAC_BITS, 10));
      first_falling <= '0';
    end if;
  end f_calc_delay_setpoint;


-- timebase counter
  signal tb_cntr                     : t_fd_timestamp;
  signal tag_tdc, start_int, end_int : t_fd_timestamp;
  signal delta_int                   : t_fd_timestamp;

  signal rep_n_int                 : unsigned(15 downto 0);
  signal pulse_count               : unsigned(15 downto 0);
  signal rep_cont_int, no_fine_int : std_logic;


  signal pstart, pend : t_fd_timestamp;

  signal start_adder_en : std_logic;
  signal end_adder_en   : std_logic;

  signal start_delay_setpoint       : std_logic_vector(9 downto 0);
  signal end_delay_setpoint         : std_logic_vector(9 downto 0);
  signal start_falling, end_falling : std_logic;



  signal gt_start_stage0, hit_start_stage0, hit_end_stage0 : std_logic_vector(1 downto 0);
  signal gt_start_stage1, hit_start_stage1, hit_end_stage1 : std_logic_vector(1 downto 0);

  signal gt_start, hit_start, hit_end : std_logic;
  signal pulse_pending                : std_logic;

  signal gen_cal_extended : std_logic;

  constant c_MODE_DELAY     : std_logic := '0';
  constant c_MODE_PULSE_GEN : std_logic := '1';

  type t_fine_output_state is (IDLE, WAIT_ARB_START, WAIT_START_PULSE, WAIT_ARB_END, WAIT_PULSE_END, WAIT_ARB_START_CP, COUNT_DOWN);

  signal state : t_fine_output_state;

  signal mode_int                          : std_logic;
  signal pending_update                    : std_logic;
  signal first_pulse, first_pulse_till_hit : std_logic;

  signal sadd_a, sadd_b, eadd_a, eadd_b : t_fd_timestamp;


  signal tag_valid_d : std_logic_vector(4 downto 0);
  signal dcr_arm_d   : std_logic_vector(4 downto 0);

  signal regs_in  : t_fd_channel_out_registers;
  signal regs_out : t_fd_channel_in_registers;
  component chipscope_ila
    port (
      CONTROL : inout std_logic_vector(35 downto 0);
      CLK     : in    std_logic;
      TRIG0   : in    std_logic_vector(31 downto 0);
      TRIG1   : in    std_logic_vector(31 downto 0);
      TRIG2   : in    std_logic_vector(31 downto 0);
      TRIG3   : in    std_logic_vector(31 downto 0));
  end component;

  component chipscope_icon
    port (
      CONTROL0 : inout std_logic_vector (35 downto 0));
  end component;

  signal CONTROL : std_logic_vector(35 downto 0);
  signal CLK     : std_logic;
  signal TRIG0   : std_logic_vector(31 downto 0);
  signal TRIG1   : std_logic_vector(31 downto 0);
  signal TRIG2   : std_logic_vector(31 downto 0);
  signal TRIG3   : std_logic_vector(31 downto 0);
begin

  gen_chipscope : if(g_index = 0) generate
  --  chipscope_ila_1 : chipscope_ila
  --    port map (
  --      CONTROL => CONTROL,
  --      CLK     => clk_ref_i,
  --      TRIG0   => TRIG0,
  --      TRIG1   => TRIG1,
  --      TRIG2   => TRIG2,
  --      TRIG3   => TRIG3);

  --  chipscope_icon_1 : chipscope_icon
  --    port map (
  --      CONTROL0 => CONTROL);
    TRIG0(0)  <= regs_in.dcr_mode_o;
    TRIG0(1)  <= regs_in.dcr_enable_o;
    TRIG0(2)  <= regs_in.dcr_update_o;
    TRIG0(3)  <= pending_update;
    TRIG0(4)  <= first_pulse_till_hit;
    TRIG0(5)  <= first_pulse;
    TRIG0(6)  <= tag_valid_i;
    TRIG0(7)  <= mode_int;
    TRIG0(8)  <= hit_start;
    TRIG0(9)  <= hit_end;
    TRIG0(10) <= mode_int;
    TRIG0(11) <= '1' when state = IDLE             else '0';
    TRIG0(12) <= '1' when state = WAIT_ARB_START   else '0';
    TRIG0(14) <= '1' when state = WAIT_START_PULSE else '0';
    TRIG0(15) <= '1' when state = WAIT_ARB_END     else '0';
    TRIG0(16) <= '1' when state = WAIT_PULSE_END   else '0';
    TRIG0(17) <= '1' when state = COUNT_DOWN       else '0';
    trig0(18) <= csync_p1_i;
    
    TRIG1(27 downto 0) <= tag_coarse_i;
    trig2(27 downto 0) <= tb_cntr.c;
    trig3(27 downto 0) <= csync_coarse_i;
    
    
  end generate gen_chipscope;


  U_WB_Slave : fd_channel_wb_slave
    port map (
      rst_n_i    => rst_n_sys_i,
      clk_sys_i  => clk_sys_i,
      wb_adr_i   => wb_i.adr(3 downto 0),
      wb_dat_i   => wb_i.dat,
      wb_dat_o   => wb_o.dat,
      wb_cyc_i   => wb_i.cyc,
      wb_sel_i   => wb_i.sel,
      wb_stb_i   => wb_i.stb,
      wb_we_i    => wb_i.we,
      wb_ack_o   => wb_o.ack,
      wb_stall_o => wb_o.stall,
      clk_ref_i  => clk_ref_i,
      regs_i     => regs_out,
      regs_o     => regs_in);

  wb_o.err <= '0';
  wb_o.int <= '0';
  wb_o.rty <= '0';

  tag_tdc <= f_to_internal_time(tag_utc_i, tag_coarse_i, tag_frac_i);

  p_tag_valid_delay : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_ref_i = '0' then
        tag_valid_d <= (others => '0');
        dcr_arm_d   <= (others => '0');
      else
        tag_valid_d <= tag_valid_d(tag_valid_d'length-2 downto 0) & tag_valid_i;
        dcr_arm_d   <= dcr_arm_d(dcr_arm_d'length-2 downto 0) & regs_in.dcr_pg_arm_o;
      end if;
    end if;
  end process;


  -- adder inputs:
  -- Mode/Pulse                DELAY                  PULSE GEN
  -- 1st pulse            TDC tag/start_dly         0 / start_dly
  -- following                       current start/delta    

  p_mux_adder_inputs : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(first_pulse = '1') then
        if(mode_int = c_MODE_DELAY) then
          sadd_a <= tag_tdc;
          sadd_b <= start_int;
          eadd_a <= tag_tdc;
          eadd_b <= end_int;
        else
          sadd_a <= f_to_internal_time("0", "0", "0");
          sadd_b <= start_int;
          eadd_a <= f_to_internal_time("0", "0", "0");
          eadd_b <= end_int;
        end if;
      else
        sadd_a <= pstart;
        sadd_b <= delta_int;
        eadd_a <= pend;
        eadd_b <= delta_int;
      end if;
    end if;
  end process;


  -- output: start_adder_en, end_adder_en
  p_gen_adder_enables : process(hit_start, hit_end, tag_valid_i, regs_in, mode_int, first_pulse)
  begin
    case mode_int is
      when c_MODE_DELAY =>
        if(first_pulse = '1') then
          start_adder_en <= tag_valid_i;
          end_adder_en   <= tag_valid_i;
        else
          start_adder_en <= hit_start;
          end_adder_en   <= hit_end;
        end if;
        
      when c_MODE_PULSE_GEN =>
        if(first_pulse = '1') then
          start_adder_en <= regs_in.dcr_pg_arm_o;
          end_adder_en   <= regs_in.dcr_pg_arm_o;
        else
          start_adder_en <= hit_start;
          end_adder_en   <= hit_end;
        end if;
      when others =>
        start_adder_en <= '0';
        end_adder_en   <= '0';
    end case;
  end process;

  U_Calc_Pulse_Start : fd_ts_adder
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_n_ref_i,
      valid_i    => '1',
      enable_i   => start_adder_en,
      -- TDC TAG/Current pstart
      a_utc_i    => sadd_a.u,
      a_coarse_i => sadd_a.c,
      a_frac_i   => sadd_a.f,
      -- + Start/Delta (from DCRx registers)
      b_utc_i    => sadd_b.u,
      b_coarse_i => sadd_b.c,
      b_frac_i   => sadd_b.f,
      -- = pstart
      q_utc_o    => pstart.u,
      q_coarse_o => pstart.c,
      q_frac_o   => pstart.f);


  U_Calc_Pulse_End : fd_ts_adder
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_n_ref_i,
      valid_i    => '1',
      enable_i   => end_adder_en,
      -- TDC TAG/Current pend
      a_utc_i    => eadd_a.u,
      a_coarse_i => eadd_a.c,
      a_frac_i   => eadd_a.f,
      -- + End/Delta (from DCRx registers)
      b_utc_i    => eadd_b.u,
      b_coarse_i => eadd_b.c,
      b_frac_i   => eadd_b.f,
      -- = pend
      q_utc_o    => pend.u,
      q_coarse_o => pend.c,
      q_frac_o   => pend.f);


  p_rescale_setpoints : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      f_calc_delay_setpoint(pstart, regs_in.frr_o, start_delay_setpoint, start_falling);
      f_calc_delay_setpoint(pend, regs_in.frr_o, end_delay_setpoint, end_falling);
    end if;
  end process;

  p_update_registers : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_ref_i = '0' then
        pending_update <= '0';
      else
        if(regs_in.dcr_update_o = '1') then
          pending_update <= '1';
        end if;

        if(pending_update = '1' and state = IDLE) then
          pending_update <= '0';

          mode_int     <= regs_in.dcr_mode_o;
          start_int    <= f_to_internal_time(regs_in.u_starth_o & regs_in.u_startl_o, regs_in.c_start_o, regs_in.f_start_o);
          end_int      <= f_to_internal_time(regs_in.u_endh_o & regs_in.u_endl_o, regs_in.c_end_o, regs_in.f_end_o);
          delta_int    <= f_to_internal_time(regs_in.u_delta_o, regs_in.c_delta_o, regs_in.f_delta_o);
          rep_cont_int <= regs_in.rcr_cont_o;
          rep_n_int    <= unsigned(regs_in.rcr_rep_cnt_o);
          no_fine_int  <= regs_in.dcr_no_fine_o;
        end if;
      end if;
    end if;
  end process;

  regs_out.dcr_upd_done_i <= not pending_update;

  p_timebase_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(csync_p1_i = '1')then
        tb_cntr.u <= csync_utc_i;
        tb_cntr.c <= csync_coarse_i;
      elsif(unsigned(tb_cntr.c) = c_REF_CLK_FREQ-1) then
        tb_cntr.c <= (others => '0');
        tb_cntr.u <= std_logic_vector(unsigned(tb_cntr.u) + 1);
      else
        tb_cntr.c <= std_logic_vector(unsigned(tb_cntr.c) + 1);
      end if;
    end if;
  end process;


-- Delay mode - uses the adjusted trigger timestamp
  hit_start_stage0(0) <= '1' when (tb_cntr.c = pstart.c) else '0';
  hit_start_stage0(1) <= '1' when (tb_cntr.u = pstart.u) else '0';
  hit_end_stage0(0)   <= '1' when (tb_cntr.c = pend.c)   else '0';
  hit_end_stage0(1)   <= '1' when (tb_cntr.u = pend.u)   else '0';

  p_match_hit_stage1 : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_ref_i = '0' or regs_in.dcr_enable_o = '0' then
        hit_end          <= '0';
        hit_start        <= '0';
        hit_start_stage1 <= (others => '0');
        hit_end_stage1   <= (others => '0');
      else
        hit_start_stage1 <= hit_start_stage0;
        hit_end_stage1   <= hit_end_stage0;

        hit_start <= hit_start_stage1(0) and hit_start_stage1(1);
        hit_end   <= hit_end_stage1(0) and hit_end_stage1(1);
      end if;
    end if;
  end process;


  U_Extend_Cal_Pulse : gc_extend_pulse
    generic map (
      g_width => 3)
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_n_ref_i,
      pulse_i    => gen_cal_i,
      extended_o => gen_cal_extended);

  p_fine_fsm : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_ref_i = '0' or regs_in.dcr_enable_o = '0' then
        state                <= IDLE;
        delay_load_o         <= '0';
        first_pulse          <= '1';
        first_pulse_till_hit <= '0';
        delay_pulse1_o       <= regs_in.dcr_force_hi_o;
        delay_pulse0_o       <= regs_in.dcr_force_hi_o;
        delay_idle_o         <= '1';
        

      else
        case state is
          when IDLE =>
            first_pulse <= '1';

            delay_pulse0_o <= gen_cal_extended;
            delay_pulse1_o <= gen_cal_extended;

            if(regs_in.dcr_pg_arm_o = '1') then
              regs_out.dcr_pg_trig_i <= '0';
            end if;

            pulse_count <= unsigned(rep_n_int);

            if ((mode_int = c_MODE_DELAY and tag_valid_d(tag_valid_d'left) = '1')) then
              delay_value_o        <= std_logic_vector(start_delay_setpoint);
              delay_load_o         <= '1';
              first_pulse_till_hit <= '1';
              delay_idle_o         <= '0';
              state                <= WAIT_ARB_START;
            elsif (mode_int = c_MODE_PULSE_GEN and dcr_arm_d(tag_valid_d'left) = '1') then
              delay_value_o        <= std_logic_vector(start_delay_setpoint);
              first_pulse_till_hit <= '1';
              delay_load_o         <= '1';
              state                <= WAIT_ARB_START;
            elsif(regs_in.dcr_force_dly_o = '1') then
              delay_value_o <= regs_in.frr_o;
              delay_load_o  <= '1';
              state         <= WAIT_ARB_START_CP;
            end if;

          when WAIT_ARB_START =>
            if(delay_load_done_i = '1') then
              state        <= WAIT_START_PULSE;
              first_pulse  <= '0';
              delay_load_o <= '0';
            end if;

          when WAIT_ARB_START_CP =>
            if(delay_load_done_i = '1') then
              state        <= IDLE;
              delay_load_o <= '0';
            end if;

          when WAIT_START_PULSE =>
            if (hit_start = '1') then
              first_pulse_till_hit <= '0';
              delay_pulse0_o       <= not start_falling;
              delay_pulse1_o       <= '1';

              if(no_fine_int = '1') then
                state <= WAIT_PULSE_END;
              else
                state         <= WAIT_ARB_END;
                delay_value_o <= std_logic_vector(end_delay_setpoint);
                delay_load_o  <= '1';
              end if;
            else
              delay_pulse0_o <= '0';
              delay_pulse1_o <= '0';
            end if;

          when WAIT_ARB_END =>
            delay_pulse0_o <= '1';
            delay_pulse1_o <= '1';

            if(delay_load_done_i = '1') then
              state        <= WAIT_PULSE_END;
              delay_load_o <= '0';
            end if;

          when WAIT_PULSE_END =>
            if(hit_end = '1') then
              delay_pulse0_o <= '1';
              delay_pulse1_o <= end_falling;
              state          <= COUNT_DOWN;

            else
              delay_pulse0_o <= '1';
              delay_pulse1_o <= '1';
            end if;

          when COUNT_DOWN =>
            delay_pulse0_o <= '0';
            delay_pulse1_o <= '0';

            if(pulse_count = 0 and rep_cont_int = '0') then
              state                  <= IDLE;
              delay_idle_o           <= '1';
              regs_out.dcr_pg_trig_i <= '1';
            else
              regs_out.dcr_pg_trig_i <= '1';
              if(no_fine_int = '1') then
                state <= WAIT_START_PULSE;
              else
                delay_value_o <= std_logic_vector(start_delay_setpoint);
                delay_load_o  <= '1';
                state         <= WAIT_ARB_START;
              end if;
            end if;

            pulse_count <= pulse_count - 1;
            
        end case;
      end if;
    end if;
  end process;

  pstart_utc_o    <= pstart.u;
  pstart_coarse_o <= pstart.c;
  pstart_frac_o   <= pstart.f;
  pstart_valid_o  <= hit_start and first_pulse_till_hit;
  
end behavioral;
