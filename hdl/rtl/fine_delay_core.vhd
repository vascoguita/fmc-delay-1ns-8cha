library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fd_wbgen2_pkg.all;

entity fine_delay_core is
  port(

    ---------------------------------------------------------------------------
    -- Clocks & Triggers
    ---------------------------------------------------------------------------

    -- 125 MHz FMC reference clock (from AD9516)
    clk_ref_i : in std_logic;

    -- System clock of any reasonable frequency
    clk_sys_i : in std_logic;

    -- System reset (clk_sys_i domain)
    rst_n_i : in std_logic;

    -- asynchronous TDC trigger
    trig_a_n_i : in std_logic;

    -- calibration TDC trigger
    trig_cal_o : out std_logic;

    -- TDC start signal (copy)
    tdc_start_i : in std_logic;

    ---------------------------------------------------------------------------
    -- ACAM TDC-GPX signals (all asynchronous)
    ---------------------------------------------------------------------------

    -- address bus
    acam_a_o : out std_logic_vector(3 downto 0);

    -- data bus (bidirectional, put the tristates in the top entity)
    acam_d_o     : out std_logic_vector(27 downto 0);
    acam_d_i     : in  std_logic_vector(27 downto 0);
    acam_d_oen_o : out std_logic;

    -- TDC error flag
    acam_err_i        : in  std_logic;
    -- TDC interrupt flag
    acam_int_i        : in  std_logic;
    -- TDC FIFO empty flag
    acam_emptyf_i     : in  std_logic;
    -- TDC FIFO load level flag
    acam_alutrigger_o : out std_logic;

    -- TDC chip select/write/read
    acam_cs_n_o : out std_logic;
    acam_wr_n_o : out std_logic;
    acam_rd_n_o : out std_logic;

    -- TDC StopDisStart ans StartDisStart flags
    acam_start_dis_o : out std_logic;
    acam_stop_dis_o  : out std_logic;

    ---------------------------------------------------------------------------
    -- SPI bus
    ---------------------------------------------------------------------------

    -- chip select for VCTCXO DAC
    spi_cs_dac_n_o : out std_logic;

    -- chip select for AD9516 PLL
    spi_cs_pll_n_o : out std_logic;

    -- chip select for MCP23S17 GPIO
    spi_cs_gpio_n_o : out std_logic;

    -- these are obvious
    spi_sclk_o : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic;

    ---------------------------------------------------------------------------
    -- Delay chip control
    ---------------------------------------------------------------------------

    -- delay latch enables
    delay_len_o : out std_logic_vector(3 downto 0);

    -- delay taps value
    delay_val_o : out std_logic_vector(9 downto 0);

    -- output pulses to be delayed
    delay_pulse_o : out std_logic_vector(3 downto 0);

    ---------------------------------------------------------------------------
    -- WhiteRabbit time sync
    ---------------------------------------------------------------------------

    wr_time_valid_i : in std_logic;
    wr_coarse_i     : in std_logic_vector(27 downto 0);
    wr_utc_i        : in std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------------
    -- Wishbone (classic)
    ---------------------------------------------------------------------------

    wb_adr_i : in  std_logic_vector(5 downto 0);
    wb_dat_i : in  std_logic_vector(31 downto 0);
    wb_dat_o : out std_logic_vector(31 downto 0);
    wb_cyc_i : in  std_logic;
    wb_stb_i : in  std_logic;
    wb_we_i  : in  std_logic;
    wb_ack_o : out std_logic;
    wb_irq_o : out std_logic
    );

end fine_delay_core;

architecture rtl of fine_delay_core is

  constant c_TIMESTAMP_FRAC_BITS   : integer := 12;
  constant c_RING_BUFFER_SIZE_LOG2 : integer := 8;
  constant c_REF_CLK_FREQ          : integer := 256;


  component fd_reset_generator
    port (
      clk_sys_i   : in    std_logic;
      clk_ref_i   : in    std_logic;
      rst_n_i     : in    std_logic;
      rst_n_sys_o : out   std_logic;
      rst_n_ref_o : out   std_logic;
      regs_b      : inout t_fd_registers);
  end component;

  component fd_gpio
    port (
      clk_sys_i       : in    std_logic;
      rst_n_i         : in    std_logic;
      spi_cs_dac_n_o  : out   std_logic;
      spi_cs_pll_n_o  : out   std_logic;
      spi_cs_gpio_n_o : out   std_logic;
      spi_sclk_o      : out   std_logic;
      spi_mosi_o      : out   std_logic;
      spi_miso_i      : in    std_logic;
      regs_b          : inout t_fd_registers);
  end component;

  component fd_wishbone_slave
    port (
      rst_n_i               : in    std_logic;
      wb_clk_i              : in    std_logic;
      wb_addr_i             : in    std_logic_vector(5 downto 0);
      wb_data_i             : in    std_logic_vector(31 downto 0);
      wb_data_o             : out   std_logic_vector(31 downto 0);
      wb_cyc_i              : in    std_logic;
      wb_sel_i              : in    std_logic_vector(3 downto 0);
      wb_stb_i              : in    std_logic;
      wb_we_i               : in    std_logic;
      wb_ack_o              : out   std_logic;
      wb_irq_o              : out   std_logic;
      clk_ref_i             : in    std_logic;
      advance_rbuf_o        : out   std_logic;
      irq_ts_buf_notempty_i : in    std_logic;
      regs_b                : inout t_fd_registers);
  end component;


  component fd_acam_timestamper
    generic (
      g_min_pulse_width : natural;
      g_clk_ref_freq    : integer;
      g_frac_bits       : integer); 
    port (
      clk_ref_i         : in    std_logic;
      rst_n_i           : in    std_logic;
      trig_a_n_i        : in    std_logic;
      tdc_start_i       : in    std_logic;
      acam_d_o          : out   std_logic_vector(27 downto 0);
      acam_d_i          : in    std_logic_vector(27 downto 0);
      acam_d_oe_o       : out   std_logic;
      acam_a_o          : out   std_logic_vector(3 downto 0);
      acam_cs_n_o       : out   std_logic;
      acam_rd_n_o       : out   std_logic;
      acam_wr_n_o       : out   std_logic;
      acam_ef_i         : in    std_logic;
      acam_stop_dis_o   : out   std_logic;
      acam_start_dis_o  : out   std_logic;
      acam_alutrigger_o : out   std_logic;
      tag_frac_o        : out   std_logic_vector(g_frac_bits-1 downto 0);
      tag_coarse_o      : out   std_logic_vector(27 downto 0);
      tag_utc_o         : out   std_logic_vector(31 downto 0);
      tag_rearm_p1_i    : in    std_logic;
      tag_valid_o       : out   std_logic;
      csync_coarse_i    : in    std_logic_vector(27 downto 0);
      csync_utc_i       : in    std_logic_vector(31 downto 0);
      csync_p1_i        : in    std_logic;
      regs_b            : inout t_fd_registers); 
  end component;


  component fd_csync_generator
    generic (
      g_coarse_range : integer;
      g_frac_bits    : integer);
    port (
      clk_ref_i       : in    std_logic;
      rst_n_i         : in    std_logic;
      wr_time_valid_i : in    std_logic;
      wr_utc_i        : in    std_logic_vector(31 downto 0);
      wr_coarse_i     : in    std_logic_vector(27 downto 0);
      csync_p1_o      : out   std_logic;
      csync_utc_o     : out   std_logic_vector(31 downto 0);
      csync_coarse_o  : out   std_logic_vector(27 downto 0);
      regs_b          : inout t_fd_registers);
  end component;

  component fd_ring_buffer
    generic (
      g_size_log2 : integer;
      g_frac_bits : integer);
    port (
      rst_n_sys_i    : in    std_logic;
      rst_n_ref_i    : in    std_logic;
      clk_ref_i      : in    std_logic;
      clk_sys_i      : in    std_logic;
      tag_valid_i    : in    std_logic;
      tag_utc_i      : in    std_logic_vector(31 downto 0);
      tag_coarse_i   : in    std_logic_vector(27 downto 0);
      tag_frac_i     : in    std_logic_vector(g_frac_bits-1 downto 0);
      advance_rbuf_i : in    std_logic;
      buf_irq_o      : out   std_logic;
      regs_b         : inout t_fd_registers);
  end component;

  signal tag_frac   : std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);
  signal tag_coarse : std_logic_vector(27 downto 0);
  signal tag_utc    : std_logic_vector(31 downto 0);
  signal tag_valid  : std_logic;

  signal master_csync_p1     : std_logic;
  signal master_csync_utc    : std_logic_vector(31 downto 0);
  signal master_csync_coarse : std_logic_vector(27 downto 0);

  signal rst_n_sys, rst_n_ref : std_logic;
  signal regs                 : t_fd_registers := c_fd_registers_init_value;

  signal advance_rbuf : std_logic;
  signal rbuf_irq     : std_logic;

  
begin  -- rtl

  U_Reset_Generator : fd_reset_generator
    port map (
      clk_sys_i   => clk_sys_i,
      clk_ref_i   => clk_ref_i,
      rst_n_i     => rst_n_i,
      rst_n_sys_o => rst_n_sys,
      rst_n_ref_o => rst_n_ref,
      regs_b      => regs);

  U_Csync_generator : fd_csync_generator
    generic map (
      g_coarse_range => c_REF_CLK_FREQ,
      g_frac_bits    => c_TIMESTAMP_FRAC_BITS)
    port map (
      clk_ref_i       => clk_ref_i,
      rst_n_i         => rst_n_ref,
      wr_time_valid_i => wr_time_valid_i,
      wr_utc_i        => wr_utc_i,
      wr_coarse_i     => wr_coarse_i,
      csync_p1_o      => master_csync_p1,
      csync_utc_o     => master_csync_utc,
      csync_coarse_o  => master_csync_coarse,
      regs_b          => regs);

  U_GPIO : fd_gpio
    port map (
      clk_sys_i       => clk_sys_i,
      rst_n_i         => rst_n_sys,
      spi_cs_dac_n_o  => spi_cs_dac_n_o,
      spi_cs_pll_n_o  => spi_cs_pll_n_o,
      spi_cs_gpio_n_o => spi_cs_gpio_n_o,
      spi_sclk_o      => spi_sclk_o,
      spi_mosi_o      => spi_mosi_o,
      spi_miso_i      => spi_miso_i,
      regs_b          => regs);

  U_Wishbon_Slave : fd_wishbone_slave
    port map (
      rst_n_i   => rst_n_i,
      wb_clk_i  => clk_sys_i,
      wb_addr_i => wb_adr_i(5 downto 0),
      wb_data_i => wb_dat_i,
      wb_data_o => wb_dat_o,
      wb_cyc_i  => wb_cyc_i,
      wb_sel_i  => "1111",
      wb_stb_i  => wb_stb_i,
      wb_we_i   => wb_we_i,
      wb_ack_o  => wb_ack_o,
      clk_ref_i => clk_ref_i,

      regs_b                => regs,
      irq_ts_buf_notempty_i => rbuf_irq,
      advance_rbuf_o        => advance_rbuf
      );

  U_Acam_TSU : fd_acam_timestamper
    generic map (
      g_min_pulse_width => 3,
      g_clk_ref_freq    => c_REF_CLK_FREQ,
      g_frac_bits       => c_TIMESTAMP_FRAC_BITS)
    port map (
      clk_ref_i => clk_ref_i,
      rst_n_i   => rst_n_ref,

      tdc_start_i => tdc_start_i,
      trig_a_n_i  => trig_a_n_i,

      acam_d_o          => acam_d_o,
      acam_d_i          => acam_d_i,
      acam_d_oe_o       => acam_d_oen_o,
      acam_a_o          => acam_a_o,
      acam_cs_n_o       => acam_cs_n_o,
      acam_rd_n_o       => acam_rd_n_o,
      acam_wr_n_o       => acam_wr_n_o,
      acam_ef_i         => acam_emptyf_i,
      acam_stop_dis_o   => acam_stop_dis_o,
      acam_start_dis_o  => acam_start_dis_o,
      acam_alutrigger_o => acam_alutrigger_o,

      tag_frac_o   => tag_frac,
      tag_coarse_o => tag_coarse,
      tag_utc_o    => tag_utc,
      tag_valid_o  => tag_valid,

      tag_rearm_p1_i => '1',

      csync_coarse_i => master_csync_coarse,
      csync_utc_i    => master_csync_utc,
      csync_p1_i     => master_csync_p1,

      regs_b => regs
      );

  U_Ring_Buffer : fd_ring_buffer
    generic map (
      g_size_log2 => c_RING_BUFFER_SIZE_LOG2,
      g_frac_bits => c_TIMESTAMP_FRAC_BITS)
    port map (
      rst_n_sys_i => rst_n_sys,
      rst_n_ref_i => rst_n_ref,
      clk_ref_i   => clk_ref_i,
      clk_sys_i   => clk_sys_i,

      tag_valid_i  => tag_valid,
      tag_utc_i    => tag_utc,
      tag_coarse_i => tag_coarse,
      tag_frac_i   => tag_frac,

      advance_rbuf_i => advance_rbuf,
      buf_irq_o      => rbuf_irq,
      regs_b         => regs);

  trig_cal_o         <= '0';
  regs.tdcsr_load_i  <= '0';
  regs.tdcsr_empty_i <= acam_emptyf_i;
  
end rtl;
