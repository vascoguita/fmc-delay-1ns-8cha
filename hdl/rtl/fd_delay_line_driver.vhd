library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fine_delay_pkg.all;

entity delay_line_driver is
  

  port(
    clk_ref_i : in std_logic;
    rst_n_i   : in std_logic;

    -- time base synchronization
    csync_time_i : in t_fd_timestamp;
    csync_p1_i   : in std_logic;

    ch_start_i    : in  t_fd_timestamp_array;
    ch_length_i   : in  t_fd_timestamp_array;
    ch_load_p1_i  : in  std_logic_vector(c_fd_num_outputs-1 downto 0);
    ch_polarity_i : in  std_logic_vector(c_fd_num_outputs-1 downto 0);
    ch_ready_o    : out std_logic_vector(c_fd_num_outputs-1 downto 0);

    delay_bus_o   : out std_logic_vector(9 downto 0);
    delay_len_o   : out std_logic_vector(c_fd_num_outputs-1 downto 0);
    delay_pulse_o : out std_logic_vector(c_fd_num_outputs-1 downto 0)
    );


end delay_line_driver;

architecture behavioral of delay_line_driver is

  signal t : t_fd_timestamp;

  type t_adjustment_fsm_state is(A_IDLE, A_FIX_START, A_FIX_END, A_WAIT_ARM);

  type t_channel is record
    t_start: t_fd_timestamp;
    t_stop: t_fd_timestamp;
    t_length: t_fd_timestamp;
    adj_state: t_adjustment_fsm_state;
    armed: std_logic;
    dly_adjusted: std_logic;
    done: std_logic;
    issued_start: std_logic;
  end record;

  type t_channel_array is array(0 to c_fd_num_outputs-1) of t_channel;
  
  signal C : t_channel_array;
  
begin  -- behavioral

  p_timebase_counter : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        t.secs   <= (others => '0');
        t.cycles <= (others => '0');
        t.fine   <= (others => '0');
      else
        if(csync_p1_i = '1') then
          t <= csync_time_i;
        elsif(t.cycles = c_fd_refclk_freq - 1) then
          t.secs   <= t.secs + 1;
          t.cycles <= (others => '0');
        else
          t.cycles <= t.cycles + 1;
        end if;
      end if;
    end if;
  end process;

  gen_channels : for i in 0 to c_fd_num_outputs-1 generate
    
    
    p_load_adjust_start_stop : process(clk_ref_i)
    begin

      if rising_edge(clk_ref_i) then
        if rst_n_i = '0' then
          C(i).t_start.cycles <= (others => '0');
          C(i).t_start.secs   <= (others => '0');
          C(i).t_start.fine   <= (others => '0');
          C(i).armed <= '0';
        else

          case C(i).adj_state is
            when A_IDLE => 
              if ch_load_p1_i(i) = '1' then
                C(i).t_start.fine <= ch_start_i(i).fine;
                C(i).t_start.cycles <= ch_start_i(i).cycles - 2;  -- 2 cycles in advance
                C(i).t_start.secs <= ch_start_i(i).secs;
                C(i).t_length <= ch_length_i(i);
                C(i).armed <= '1';
                C(i).adj_state <= A_FIX_START;
              end if;

            when A_FIX_START =>
-- calculate the end-of-pulse timestamp
              C(i).t_stop.fine <= C(i).t_start.fine + C(i).t_length.fine;
              C(i).t_stop.cycles <= C(i).t_start.cycles + C(i).t_length.cycles;
              C(i).t_stop.secs <= C(i).t_start.secs + C(i).t_length.secs;

-- unwind start-of-pulse timestamp
              if(C(i).t_start.cycles(27) = '1') then
                C(i).t_start.secs <= C(i).t_start.secs + 1;
                C(i).t_start.cycles <= C(i).t_start.cycles + c_fd_refclk_freq;
              end if;
              
            when others => null;

          end case;
          

          

            


        end if;

      end if;
    end process;
  end generate gen_channels;
  

  
end behavioral;
