library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fd_wbgen2_pkg.all;


entity fd_timestamper_stat_unit is
  port(
    clk_ref_i : in std_logic;
    rst_n_i   : in std_logic;

    trig_pulse_i    : in std_logic;
    raw_tag_valid_i : in std_logic;

    regs_i : in  t_fd_out_registers;
    regs_o : out t_fd_in_registers);

end fd_timestamper_stat_unit;

architecture behavioral of fd_timestamper_stat_unit is

  type t_pdelay_meas_state is (PD_WAIT_TRIGGER, PD_WAIT_TAG, PD_UPDATE_STATS);

  -- stat counters signals
  signal event_count_raw    : unsigned(31 downto 0);
  signal event_count_tagged : unsigned(31 downto 0);
  signal pd_state           : t_pdelay_meas_state;

  signal cur_pdelay   : unsigned(7 downto 0);
  signal worst_pdelay : unsigned(7 downto 0);

begin  -- behavioral


  p_count_events : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if (rst_n_i = '0' or regs_i.gcr_input_en_o = '0' or regs_i.iepd_rst_stat_o = '1') then
        event_count_raw    <= (others => '0');
        event_count_tagged <= (others => '0');
      else
        if(trig_pulse_i = '1') then
          event_count_raw <= event_count_raw + 1;
        end if;

        if(raw_tag_valid_i = '1') then
          event_count_tagged <= event_count_tagged + 1;
        end if;
      end if;
    end if;
  end process;

  regs_o.iecraw_i <= std_logic_vector(event_count_raw);
  regs_o.iectag_i <= std_logic_vector(event_count_tagged);

  p_measure_processing_delay : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' or regs_i.gcr_input_en_o = '0' or regs_i.iepd_rst_stat_o = '1' then
        cur_pdelay   <= (others => '0');
        worst_pdelay <= (others => '0');
        pd_state     <= PD_WAIT_TRIGGER;
      else
        case pd_state is
          when PD_WAIT_TRIGGER =>
            if(trig_pulse_i = '1') then
              cur_pdelay <= (others => '0');
              pd_state   <= PD_WAIT_TAG;
            end if;

          when PD_WAIT_TAG =>
            if(trig_pulse_i = '1') then
              pd_state <= PD_WAIT_TRIGGER;
            elsif(raw_tag_valid_i = '1') then
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

  regs_o.iepd_pdelay_i <= std_logic_vector(worst_pdelay);

end behavioral;
