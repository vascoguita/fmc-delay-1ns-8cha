library ieee;
use ieee.std_logic_1164.all;

entity fd_ts_normalizer is
  generic
    (
      -- sizes of the respective bitfields
      g_frac_bits   : integer := 12;
      g_coarse_bits : integer := 28;
      g_utc_bits    : integer := 32;

      -- upper bound of the coarse part
      g_coarse_range : integer := 125000000
      );

  port(
    clk_i   : in std_logic;
    rst_n_i : in std_logic;

    valid_i  : in std_logic;  
    utc_i    : in std_logic_vector(g_utc_bits-1 downto 0);
    coarse_i : in std_logic_vector(g_coarse_bits-1 downto 0);
    frac_i   : in std_logic_vector(g_frac_bits-1 downto 0);

    valid_o  : out std_logic;
    utc_o    : out std_logic_vector(g_utc_bits-1 downto 0);
    coarse_o : out std_logic_vector(g_coarse_bits-1 downto 0);
    frac_o   : out std_logic_vector(g_frac_bits-1 downto 0)
    );
end fd_ts_normalizer;


architecture wrapper of fd_ts_normalizer is

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
  
begin  

  U_TS_Adder: fd_ts_adder
    generic map (
      g_frac_bits    => g_frac_bits,
      g_coarse_bits  => g_coarse_bits,
      g_utc_bits     => g_utc_bits,
      g_coarse_range => g_coarse_range)
    port map (
      clk_i      => clk_i,
      rst_n_i    => rst_n_i,
      valid_i    => valid_i,
      a_utc_i    => utc_i,
      a_coarse_i => coarse_i,
      a_frac_i   => frac_i,
      b_utc_i    => (others => '0'),
      b_coarse_i => (others => '0'),
      b_frac_i   => (others => '0'),
      valid_o    => valid_o,
      q_utc_o    => utc_o,
      q_coarse_o => coarse_o,
      q_frac_o   => frac_o);

end wrapper;
