library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fine_delay_pkg.all;

entity fd_delay_channel_driver is
  generic(
    g_frac_bits    : integer;
    g_coarse_range : integer);

  port(
    clk_ref_i : in std_logic;
    rst_n_i   : in std_logic;

    -- time base synchronization
    csync_p1_i     : in std_logic;
    csync_utc_i    : in std_logic_vector(31 downto 0);
    csync_coarse_i : in std_logic_vector(27 downto 0);

    tdc_start_p1_i: in std_logic;
    
    rearm_p1_o : out std_logic;

    tag_valid_i  : in std_logic;
    tag_utc_i    : in std_logic_vector(31 downto 0);
    tag_coarse_i : in std_logic_vector(27 downto 0);
    tag_frac_i   : in std_logic_vector(g_frac_bits-1 downto 0);

    delay_pulse_o     : out std_logic;
    delay_value_o     : out std_logic_vector(9 downto 0);
    delay_load_o      : out std_logic;
    delay_load_done_i : in  std_logic;

    dcr_mode_i        : in  std_logic;
    dcr_enable_i      : in  std_logic;
    dcr_pg_arm_i      : in  std_logic;
    dcr_pg_arm_o      : out std_logic;
    dcr_pg_arm_load_i : in  std_logic;
    dcr_pg_trig_o     : out std_logic;
    dcr_update_i      : in  std_logic;
    dcr_upd_done_o    : out std_logic;
    dcr_force_cp_i    : in  std_logic;
    dcr_pol_i         : in  std_logic;
    frr_i             : in  std_logic_vector(9 downto 0);
    u_start_i         : in  std_logic_vector(31 downto 0);
    c_start_i         : in  std_logic_vector(27 downto 0);
    f_start_i         : in  std_logic_vector(g_frac_bits-1 downto 0);
    u_end_i           : in  std_logic_vector(31 downto 0);
    c_end_i           : in  std_logic_vector(27 downto 0);
    f_end_i           : in  std_logic_vector(g_frac_bits-1 downto 0)
    );

end fd_delay_channel_driver;

architecture behavioral of fd_delay_channel_driver is


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

  signal cntr_utc    : unsigned(31 downto 0);
  signal cntr_coarse : unsigned(27 downto 0);


  signal u_start_int : std_logic_vector(31 downto 0);
  signal c_start_int : std_logic_vector(27 downto 0);
  signal f_start_int : std_logic_vector(g_frac_bits-1 downto 0);

  signal u_end_int : std_logic_vector(31 downto 0);
  signal c_end_int : std_logic_vector(27 downto 0);
  signal f_end_int : std_logic_vector(g_frac_bits-1 downto 0);

  signal st_coarse : std_logic_vector(27 downto 0);
  signal st_frac   : std_logic_vector(g_frac_bits-1 downto 0);
  signal st_utc    : std_logic_vector(31 downto 0);

  signal end_coarse : std_logic_vector(27 downto 0);
  signal end_frac   : std_logic_vector(g_frac_bits-1 downto 0);
  signal end_utc    : std_logic_vector(31 downto 0);

  signal st_end_valid : std_logic;

  signal st_delay_setpoint  : unsigned(9 downto 0);
  signal end_delay_setpoint : unsigned(9 downto 0);

  signal pg_hit_start_stage0, pg_hit_end_stage0   : std_logic_vector(1 downto 0);
  signal dly_hit_start_stage0, dly_hit_end_stage0 : std_logic_vector(1 downto 0);

  signal hit_start, hit_end : std_logic;
  signal hit_start_d0       : std_logic;
  signal pulse_pending      : std_logic;

  constant c_MODE_DELAY     : std_logic := '0';
  constant c_MODE_PULSE_GEN : std_logic := '1';

  type t_fine_output_state is (IDLE, WAIT_ARB_START, WAIT_START_PULSE, WAIT_ARB_END, WAIT_PULSE_END, WAIT_ARB_START_CP, WAIT_PULSE_CP);

  signal state     : t_fine_output_state;

  

begin

  U_Calc_Pulse_Start : fd_ts_adder
    generic map (
      g_frac_bits    => g_frac_bits,
      g_coarse_bits  => 28,
      g_utc_bits     => 32,
      g_coarse_range => g_coarse_range)
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_n_i,
      valid_i    => tag_valid_i,
      a_utc_i    => tag_utc_i,
      a_coarse_i => tag_coarse_i,
      a_frac_i   => tag_frac_i,
      b_utc_i    => u_start_int,
      b_coarse_i => c_start_int,
      b_frac_i   => f_start_int,
      valid_o    => st_end_valid,
      q_utc_o    => st_utc,
      q_coarse_o => st_coarse,
      q_frac_o   => st_frac);

  U_Calc_Pulse_End : fd_ts_adder
    generic map (
      g_frac_bits    => g_frac_bits,
      g_coarse_bits  => 28,
      g_utc_bits     => 32,
      g_coarse_range => g_coarse_range)
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_n_i,
      valid_i    => tag_valid_i,
      a_utc_i    => tag_utc_i,
      a_coarse_i => tag_coarse_i,
      a_frac_i   => tag_frac_i,
      b_utc_i    => u_end_int,
      b_coarse_i => c_end_int,
      b_frac_i   => f_end_int,
      valid_o    => open,
      q_utc_o    => end_utc,
      q_coarse_o => end_coarse,
      q_frac_o   => end_frac);

  st_delay_setpoint  <= resize((unsigned(st_frac) * unsigned(frr_i)) srl g_frac_bits, 10);
  end_delay_setpoint <= resize((unsigned(end_frac) * unsigned(frr_i)) srl g_frac_bits, 10);

  dcr_upd_done_o <= '1';

  p_update_start_end_regs : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        u_start_int <= (others => '0');
        c_start_int <= (others => '0');
        f_start_int <= (others => '0');
        u_end_int   <= (others => '0');
        c_end_int   <= (others => '0');
        f_end_int   <= (others => '0');
      else
        if(dcr_update_i = '1') then
          u_start_int <= u_start_i;
          c_start_int <= c_start_i;
          f_start_int <= f_start_i;
          u_end_int   <= u_end_i;
          c_end_int   <= c_end_i;
          f_end_int   <= f_end_i;
        end if;
      end if;
    end if;
  end process;

  p_timebase_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        cntr_utc    <= (others => '0');
        cntr_coarse <= (others => '0');
      else
        if(csync_p1_i = '1')then
          cntr_utc    <= unsigned(csync_utc_i);
          cntr_coarse <= unsigned(csync_coarse_i);
        elsif(cntr_coarse = g_coarse_range-1) then
          cntr_coarse <= (others => '0');
          cntr_utc    <= cntr_utc + 1;
        else
          cntr_coarse <= cntr_coarse + 1;
        end if;
      end if;
    end if;
  end process;


-- Delay mode - uses the adjusted trigger timestamp
  dly_hit_start_stage0(0) <= '1' when (cntr_coarse = unsigned(st_coarse)) else '0';
  dly_hit_start_stage0(1) <= '1' when (cntr_utc = unsigned(st_utc))       else '0';

-- Pulse generator mode - uses the values from u_start directly
  pg_hit_start_stage0(0) <= '1' when (cntr_coarse = unsigned(c_start_int)) else '0';
  pg_hit_start_stage0(1) <= '1' when (cntr_utc = unsigned(u_start_int))    else '0';

  dly_hit_end_stage0(0) <= '1' when (cntr_coarse = unsigned(end_coarse)) else '0';
  dly_hit_end_stage0(1) <= '1' when (cntr_utc = unsigned(end_utc))       else '0';

  pg_hit_end_stage0(0) <= '1' when (cntr_coarse = unsigned(c_end_int)) else '0';
  pg_hit_end_stage0(1) <= '1' when (cntr_utc = unsigned(u_end_int))    else '0';

  p_match_hit_stage1 : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' or dcr_enable_i = '0' then
        hit_end   <= '0';
        hit_start <= '0';
      else
        if(dcr_mode_i = c_MODE_DELAY) then
          hit_start <= dly_hit_start_stage0(0) and dly_hit_start_stage0(1) and pulse_pending;
          hit_end   <= dly_hit_end_stage0(0) and dly_hit_end_stage0(1) and pulse_pending;
        elsif(dcr_mode_i = c_MODE_PULSE_GEN) then
          hit_start <= pg_hit_start_stage0(0) and pg_hit_start_stage0(1) and pulse_pending;
          hit_end   <= pg_hit_end_stage0(0) and pg_hit_end_stage0(1) and pulse_pending;
        end if;
      end if;
    end if;
  end process;


  p_gen_pulse : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        delay_pulse_o <= '0';
        pulse_pending <= '0';
      else
        if(dcr_enable_i = '0') then

          if(state = WAIT_PULSE_CP) then
            delay_pulse_o <= tdc_start_p1_i;
          else
            delay_pulse_o <= not dcr_pol_i;
          end if;
          
          pulse_pending <= '0';
        else
          if(tag_valid_i = '1') then
            pulse_pending <= '1';
            delay_pulse_o <= not dcr_pol_i;
          elsif(hit_start = '1') then
            delay_pulse_o <= dcr_pol_i;
          elsif (hit_end = '1') then
            delay_pulse_o <= not dcr_pol_i;
            pulse_pending <= '0';
          elsif (pulse_pending = '0') then
            delay_pulse_o <= not dcr_pol_i;
          end if;
        end if;
      end if;
    end if;
  end process;

  p_fine_fsm : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0'  then
        state         <= IDLE;
        delay_load_o  <= '0';
        delay_value_o <= (others => '0');
        rearm_p1_o    <= '0';
        hit_start_d0  <= '0';
      else

        hit_start_d0 <= hit_start;

        case state is
          when IDLE =>
            rearm_p1_o <= '0';

            if (st_end_valid = '1' and dcr_enable_i = '1') then
              delay_value_o <= std_logic_vector(st_delay_setpoint);
              delay_load_o  <= '1';
              state         <= WAIT_ARB_START;
            elsif(dcr_force_cp_i = '1') then
              delay_value_o <= frr_i;
              delay_load_o <= '1';
              state <= WAIT_ARB_START_CP;
            end if;

          when WAIT_ARB_START =>
            if(delay_load_done_i = '1') then
              state        <= WAIT_START_PULSE;
              delay_load_o <= '0';
            end if;

          when WAIT_ARB_START_CP =>
            if(delay_load_done_i = '1') then
              state        <= WAIT_PULSE_CP;
              delay_load_o <= '0';
            end if;

          when WAIT_PULSE_CP =>
            if(tdc_start_p1_i = '1') then
              state <= IDLE;
            end if;

          when WAIT_START_PULSE =>
            if (hit_start_d0 = '1') then
              state         <= WAIT_ARB_END;
              delay_value_o <= std_logic_vector(end_delay_setpoint);
              delay_load_o  <= '1';
            end if;

          when WAIT_ARB_END =>
            if(delay_load_done_i = '1') then
              state        <= WAIT_PULSE_END;
              delay_load_o <= '0';
            end if;

          when WAIT_PULSE_END =>
            if(hit_end = '1') then
              rearm_p1_o <= '1';
              state      <= IDLE;
            end if;
            
        end case;
      end if;
    end if;
  end process;
  
end behavioral;
