library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fd_wbgen2_pkg.all;

entity fd_csync_generator is

  generic (
    g_coarse_range : integer;
    g_frac_bits    : integer);
  port(
    clk_ref_i : in std_logic;
    rst_n_i   : in std_logic;

    -- White Rabbit Counter sync input
    wr_time_valid_i : in std_logic;
    wr_utc_i        : in std_logic_vector(31 downto 0);
    wr_coarse_i     : in std_logic_vector(27 downto 0);

    -- CSYNC Output 
    csync_p1_o     : out std_logic;
    csync_utc_o    : out std_logic_vector(31 downto 0);
    csync_coarse_o : out std_logic_vector(27 downto 0);

    regs_b : inout t_fd_registers);

end fd_csync_generator;


architecture behavioral of fd_csync_generator is

  constant c_ADDER_PIPELINE_DELAY : integer := 4;

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

  signal coarse : unsigned(27 downto 0);
  signal utc    : unsigned(31 downto 0);

  signal coarse_adjusted : unsigned(27 downto 0);
  signal utc_adjusted    : unsigned(31 downto 0);

  signal csync_int : std_logic;
  
begin  -- behavioral

  regs_b <= c_fd_registers_init_value;

  U_Timescale_Adjust : fd_ts_adder
    generic map (
      g_frac_bits    => 2,
      g_coarse_bits  => 28,
      g_utc_bits     => 32,
      g_coarse_range => g_coarse_range)
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_n_i,
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

  regs_b.gcr_wr_ready_i <= wr_time_valid_i;

  process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        coarse <= (others => '0');
        utc    <= (others => '0');
      else
        if(regs_b.gcr_csync_wr_o = '1' and wr_time_valid_i = '1') then
          utc       <= unsigned(wr_utc_i);
          coarse    <= unsigned(wr_coarse_i) + 1;
          csync_int <= '1';
        elsif(coarse = g_coarse_range) then  -- unlike, but may happen after WR csync
          coarse <= to_unsigned(1, coarse'length);
          utc    <= utc + 1;
          csync_int <= regs_b.gcr_csync_int_o;
        elsif(coarse = g_coarse_range-1) then
          coarse    <= (others => '0');
          utc       <= utc + 1;
          csync_int <= regs_b.gcr_csync_int_o;
        else
          coarse    <= coarse + 1;
          csync_int <= regs_b.gcr_csync_int_o;
        end if;
      end if;
    end if;
  end process;
end behavioral;
