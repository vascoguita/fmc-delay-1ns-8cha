library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fd_wbgen2_pkg.all;
use work.gencores_pkg.all;
use work.wishbone_pkg.all;

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

    led_trig_o : out std_logic;

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
    -- WhiteRabbit time/frequency sync
    ---------------------------------------------------------------------------

    tm_time_valid_i      : in  std_logic;
    tm_cycles_i          : in  std_logic_vector(27 downto 0);
    tm_utc_i             : in  std_logic_vector(39 downto 0);
    tm_clk_aux_lock_en_o : out std_logic;
    tm_clk_aux_locked_i  : in  std_logic;
    tm_dac_value_i       : in  std_logic_vector(31 downto 0);
    tm_dac_wr_i          : in  std_logic;

    ---------------------------------------------------------------------------
    -- Temeperature sensor (1-wire)
    ---------------------------------------------------------------------------

    owr_en_o : out std_logic;
    owr_i    : in  std_logic;

    ---------------------------------------------------------------------------
    -- Wishbone (classic)
    ---------------------------------------------------------------------------

    wb_adr_i : in  std_logic_vector(7 downto 0);
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
  constant c_REF_CLK_FREQ          : integer := 125000000;

  component fd_ts_normalizer
    generic (
      g_frac_bits    : integer;
      g_coarse_bits  : integer;
      g_utc_bits     : integer;
      g_coarse_range : integer);
    port (
      clk_i    : in  std_logic;
      rst_n_i  : in  std_logic;
      valid_i  : in  std_logic;
      utc_i    : in  std_logic_vector(g_utc_bits-1 downto 0);
      coarse_i : in  std_logic_vector(g_coarse_bits-1 downto 0);
      frac_i   : in  std_logic_vector(g_frac_bits-1 downto 0);
      valid_o  : out std_logic;
      utc_o    : out std_logic_vector(g_utc_bits-1 downto 0);
      coarse_o : out std_logic_vector(g_coarse_bits-1 downto 0);
      frac_o   : out std_logic_vector(g_frac_bits-1 downto 0));
  end component;

  component fd_reset_generator
    port (
      clk_sys_i   : in  std_logic;
      clk_ref_i   : in  std_logic;
      rst_n_i     : in  std_logic;
      rst_n_sys_o : out std_logic;
      rst_n_ref_o : out std_logic;
      regs_i      : in  t_fd_out_registers);
  end component;



  component fd_acam_timestamper
    generic (
      g_min_pulse_width : natural;
      g_clk_ref_freq    : integer;
      g_frac_bits       : integer);
    port (
      clk_ref_i         : in  std_logic;
      rst_n_i           : in  std_logic;
      trig_a_n_i        : in  std_logic;
      tdc_start_i       : in  std_logic;
      acam_d_o          : out std_logic_vector(27 downto 0);
      acam_d_i          : in  std_logic_vector(27 downto 0);
      acam_d_oe_o       : out std_logic;
      acam_a_o          : out std_logic_vector(3 downto 0);
      acam_cs_n_o       : out std_logic;
      acam_rd_n_o       : out std_logic;
      acam_wr_n_o       : out std_logic;
      acam_ef_i         : in  std_logic;
      acam_stop_dis_o   : out std_logic;
      acam_start_dis_o  : out std_logic;
      acam_alutrigger_o : out std_logic;
      tag_frac_o        : out std_logic_vector(g_frac_bits-1 downto 0);
      tag_coarse_o      : out std_logic_vector(27 downto 0);
      tag_utc_o         : out std_logic_vector(31 downto 0);
      tag_rearm_p1_i    : in  std_logic;
      tag_valid_o       : out std_logic;
      csync_coarse_i    : in  std_logic_vector(27 downto 0);
      csync_utc_i       : in  std_logic_vector(31 downto 0);
      csync_p1_i        : in  std_logic;
      tdc_start_p1_o    : out std_logic;

      regs_i : in  t_fd_out_registers;
      regs_o : out t_fd_in_registers := c_fd_in_registers_init_value;
      dbg_o  : out std_logic_vector(3 downto 0));
  end component;

  component fd_wishbone_slave
    port (
      rst_n_i               : in  std_logic;
      wb_clk_i              : in  std_logic;
      wb_addr_i             : in  std_logic_vector(5 downto 0);
      wb_data_i             : in  std_logic_vector(31 downto 0);
      wb_data_o             : out std_logic_vector(31 downto 0);
      wb_cyc_i              : in  std_logic;
      wb_sel_i              : in  std_logic_vector(3 downto 0);
      wb_stb_i              : in  std_logic;
      wb_we_i               : in  std_logic;
      wb_ack_o              : out std_logic;
      wb_irq_o              : out std_logic;
      clk_ref_i             : in  std_logic;
      irq_ts_buf_notempty_i : in  std_logic;
      advance_rbuf_o        : out std_logic;
      regs_i                : in  t_fd_in_registers;
      regs_o                : out t_fd_out_registers);
  end component;

  component fd_csync_generator
    generic (
      g_coarse_range : integer);
    port (
      clk_ref_i       : in  std_logic;
      rst_n_i         : in  std_logic;
      wr_time_valid_i : in  std_logic;
      wr_utc_i        : in  std_logic_vector(31 downto 0);
      wr_coarse_i     : in  std_logic_vector(27 downto 0);
      csync_p1_o      : out std_logic;
      csync_utc_o     : out std_logic_vector(31 downto 0);
      csync_coarse_o  : out std_logic_vector(27 downto 0);
      regs_i          : in  t_fd_out_registers;
      regs_o          : out t_fd_in_registers := c_fd_in_registers_init_value);
  end component;

  component fd_delay_channel_driver
    generic (
      g_frac_bits    : integer;
      g_coarse_range : integer);
    port (
      clk_ref_i      : in std_logic;
      rst_n_i        : in std_logic;
      csync_p1_i     : in std_logic;
      csync_utc_i    : in std_logic_vector(31 downto 0);
      csync_coarse_i : in std_logic_vector(27 downto 0);

      gen_cal_i         : in  std_logic;
      rearm_p1_o        : out std_logic;
      tag_valid_i       : in  std_logic;
      tag_utc_i         : in  std_logic_vector(31 downto 0);
      tag_coarse_i      : in  std_logic_vector(27 downto 0);
      tag_frac_i        : in  std_logic_vector(g_frac_bits-1 downto 0);
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
      dcr_force_dly_i   : in  std_logic;
      dcr_pol_i         : in  std_logic;
      frr_i             : in  std_logic_vector(9 downto 0);
      u_start_i         : in  std_logic_vector(31 downto 0);
      c_start_i         : in  std_logic_vector(27 downto 0);
      f_start_i         : in  std_logic_vector(g_frac_bits-1 downto 0);
      u_end_i           : in  std_logic_vector(31 downto 0);
      c_end_i           : in  std_logic_vector(27 downto 0);
      f_end_i           : in  std_logic_vector(g_frac_bits-1 downto 0));
  end component;

  component fd_delay_line_arbiter
    port (
      clk_ref_i    : in  std_logic;
      rst_n_i      : in  std_logic;
      load_i       : in  std_logic_vector(3 downto 0);
      done_o       : out std_logic_vector(3 downto 0);
      delay_val0_i : in  std_logic_vector(9 downto 0);
      delay_val1_i : in  std_logic_vector(9 downto 0);
      delay_val2_i : in  std_logic_vector(9 downto 0);
      delay_val3_i : in  std_logic_vector(9 downto 0);
      delay_val_o  : out std_logic_vector(9 downto 0);
      delay_len_o  : out std_logic_vector(3 downto 0));
  end component;

  component fd_ring_buffer
    generic (
      g_size_log2 : integer;
      g_frac_bits : integer);
    port (
      rst_n_sys_i    : in  std_logic;
      rst_n_ref_i    : in  std_logic;
      clk_ref_i      : in  std_logic;
      clk_sys_i      : in  std_logic;
      tag_valid_i    : in  std_logic;
      tag_utc_i      : in  std_logic_vector(31 downto 0);
      tag_coarse_i   : in  std_logic_vector(27 downto 0);
      tag_frac_i     : in  std_logic_vector(g_frac_bits-1 downto 0);
      advance_rbuf_i : in  std_logic;
      buf_irq_o      : out std_logic;
      regs_i         : in  t_fd_out_registers;
      regs_o         : out t_fd_in_registers := c_fd_in_registers_init_value);
  end component;

  component fd_rearm_generator
    port (
      clk_ref_i    : in  std_logic;
      rst_n_i      : in  std_logic;
      tag_valid_i  : in  std_logic;
      rearm_i      : in  std_logic_vector(3 downto 0);
      dcr_enable_i : in  std_logic_vector(3 downto 0);
      dcr_mode_i   : in  std_logic_vector(3 downto 0);
      rearm_p1_o   : out std_logic);
  end component;

  component fd_spi_dac_arbiter
    generic (
      g_div_ratio_log2 : integer);
    port (
      clk_sys_i       : in  std_logic;
      rst_n_i         : in  std_logic;
      tm_dac_value_i  : in  std_logic_vector(31 downto 0);
      tm_dac_wr_i     : in  std_logic;
      spi_cs_dac_n_o  : out std_logic;
      spi_cs_pll_n_o  : out std_logic;
      spi_cs_gpio_n_o : out std_logic;
      spi_sclk_o      : out std_logic;
      spi_mosi_o      : out std_logic;
      spi_miso_i      : in  std_logic;
      regs_i          : in  t_fd_out_registers;
      regs_o          : out t_fd_in_registers);
  end component;
  
  signal tag_frac   : std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);
  signal tag_coarse : std_logic_vector(27 downto 0);
  signal tag_utc    : std_logic_vector(31 downto 0);
  signal tag_valid  : std_logic;

  signal rbuf_frac   : std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);
  signal rbuf_coarse : std_logic_vector(27 downto 0);
  signal rbuf_utc    : std_logic_vector(31 downto 0);
  signal rbuf_valid  : std_logic;

  signal master_csync_p1     : std_logic;
  signal master_csync_utc    : std_logic_vector(31 downto 0);
  signal master_csync_coarse : std_logic_vector(27 downto 0);

  signal rst_n_sys, rst_n_ref : std_logic;

  signal advance_rbuf : std_logic;
  signal rbuf_irq     : std_logic;
  type t_dly_array is array (integer range <>) of std_logic_vector(9 downto 0);

  signal tdc_rearm_p1 : std_logic;
  signal tdc_start_p1 : std_logic;

  signal dcr_enable_vec : std_logic_vector(3 downto 0);
  signal dcr_mode_vec   : std_logic_vector(3 downto 0);

  signal chx_rearm           : std_logic_vector(3 downto 0);
  signal chx_delay_pulse     : std_logic_vector(3 downto 0);
  signal chx_delay_value     : t_dly_array(0 to 3);
  signal chx_delay_load      : std_logic_vector(3 downto 0);
  signal chx_delay_load_done : std_logic_vector(3 downto 0);

  signal fan_out : t_wishbone_master_out_array(0 to 2);
  signal fan_in  : t_wishbone_master_in_array(0 to 2);

  signal wb_in  : t_wishbone_slave_in;
  signal wb_out : t_wishbone_slave_out;

  signal regs_fromwb     : t_fd_out_registers;
  signal regs_towb_csync : t_fd_in_registers;
  signal regs_towb_spi  : t_fd_in_registers;
  signal regs_towb_tsu   : t_fd_in_registers;
  signal regs_towb_rbuf  : t_fd_in_registers;
  signal regs_towb_local : t_fd_in_registers := c_fd_in_registers_init_value;
  signal regs_towb       : t_fd_in_registers;

  signal spi_cs_vec : std_logic_vector(7 downto 0);

  signal owr_en_int : std_logic_vector(0 downto 0);
  signal owr_int    : std_logic_vector(0 downto 0);
  signal dbg        : std_logic_vector(3 downto 0);

  signal gen_cal_pulse     : std_logic_vector(3 downto 0);
  signal cal_pulse_mask    : std_logic_vector(3 downto 0);
  signal cal_pulse_trigger : std_logic;
  
begin  -- rtl

  wb_in.adr(7 downto 0) <= wb_adr_i;
  wb_in.cyc             <= wb_cyc_i;
  wb_in.stb             <= wb_stb_i;
  wb_in.we              <= wb_we_i;
  wb_in.dat             <= wb_dat_i;
  wb_in.sel             <= "1111";

  wb_ack_o <= wb_out.ack;
  wb_dat_o <= wb_out.dat;


  U_WB_Fanout : xwb_bus_fanout
    generic map (
      g_num_outputs    => 3,
      g_bits_per_slave => 6)
    port map (
      clk_sys_i => clk_sys_i,
      rst_n_i   => rst_n_i,
      slave_i   => wb_in,
      slave_o   => wb_out,
      master_i  => fan_in,
      master_o  => fan_out);

  U_Reset_Generator : fd_reset_generator
    port map (
      clk_sys_i   => clk_sys_i,
      clk_ref_i   => clk_ref_i,
      rst_n_i     => rst_n_i,
      rst_n_sys_o => rst_n_sys,
      rst_n_ref_o => rst_n_ref,
      regs_i      => regs_fromwb);

  U_Csync_generator : fd_csync_generator
    generic map (
      g_coarse_range => c_REF_CLK_FREQ)
    port map (
      clk_ref_i       => clk_ref_i,
      rst_n_i         => rst_n_ref,
      wr_time_valid_i => tm_time_valid_i,
      wr_utc_i        => tm_utc_i(31 downto 0),
      wr_coarse_i     => tm_cycles_i,
      csync_p1_o      => master_csync_p1,
      csync_utc_o     => master_csync_utc,
      csync_coarse_o  => master_csync_coarse,
      regs_i          => regs_fromwb,
      regs_o          => regs_towb_csync);

  regs_towb_local.gcr_wr_locked_i <= tm_clk_aux_locked_i;
  tm_clk_aux_lock_en_o <= regs_fromwb.gcr_wr_lock_en_o;
  
  --U_SPI_Master : xwb_spi
  --  generic map (
  --    g_interface_mode => CLASSIC)
  --  port map (
  --    clk_sys_i  => clk_sys_i,
  --    rst_n_i    => rst_n_i,
  --    slave_i    => fan_out(1),
  --    slave_o    => fan_in(1),
  --    pad_cs_o   => spi_cs_vec,
  --    pad_sclk_o => spi_sclk_o,
  --    pad_mosi_o => spi_mosi_o,
  --    pad_miso_i => spi_miso_i);

  --spi_cs_dac_n_o  <= spi_cs_vec(0);
  --spi_cs_pll_n_o  <= spi_cs_vec(1);
  --spi_cs_gpio_n_o <= spi_cs_vec(2);

  fan_in(1).ack <= '1';
  fan_in(1).err <= '0';
  fan_in(1).rty <= '0';
  
  U_SPI_Arbiter: fd_spi_dac_arbiter
    generic map (
      g_div_ratio_log2 => 10)
    port map (
      clk_sys_i       => clk_sys_i,
      rst_n_i         => rst_n_sys,
      tm_dac_value_i  => tm_dac_value_i,
      tm_dac_wr_i     => tm_dac_wr_i,
      spi_cs_dac_n_o  => spi_cs_dac_n_o,
      spi_cs_pll_n_o  => spi_cs_pll_n_o,
      spi_cs_gpio_n_o => spi_cs_gpio_n_o,
      spi_sclk_o      => spi_sclk_o,
      spi_mosi_o      => spi_mosi_o,
      spi_miso_i      => spi_miso_i,
      regs_i          => regs_fromwb,
      regs_o          => regs_towb_spi);
  

  U_Onewire : xwb_onewire_master
    generic map (
      g_interface_mode => CLASSIC,
      g_num_ports      => 1)
    port map (
      clk_sys_i   => clk_sys_i,
      rst_n_i     => rst_n_i,
      slave_i     => fan_out(2),
      slave_o     => fan_in(2),
      desc_o      => open,
      owr_pwren_o => open,
      owr_en_o    => owr_en_int,
      owr_i       => owr_int);

  owr_en_o   <= owr_en_int(0);
  owr_int(0) <= owr_i;


  regs_towb <= regs_towb_csync or regs_towb_tsu or regs_towb_rbuf or regs_towb_local or regs_towb_spi;

  U_Wishbone_Slave : fd_wishbone_slave
    port map (
      rst_n_i   => rst_n_i,
      wb_clk_i  => clk_sys_i,
      wb_addr_i => fan_out(0).adr(5 downto 0),
      wb_data_i => fan_out(0).dat,
      wb_data_o => fan_in(0).dat,
      wb_cyc_i  => fan_out(0).cyc,
      wb_sel_i  => "1111",
      wb_stb_i  => fan_out(0).stb,
      wb_we_i   => fan_out(0).we,
      wb_ack_o  => fan_in(0).ack,
      clk_ref_i => clk_ref_i,

      regs_o                => regs_fromwb,
      regs_i                => regs_towb,
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

      tag_rearm_p1_i => tdc_rearm_p1,

      csync_coarse_i => master_csync_coarse,
      csync_utc_i    => master_csync_utc,
      csync_p1_i     => master_csync_p1,

      tdc_start_p1_o => tdc_start_p1,

      regs_i => regs_fromwb,
      regs_o => regs_towb_tsu,
      dbg_o  => dbg);

  U_Normalize_for_rbuf : fd_ts_normalizer
    generic map (
      g_frac_bits    => c_TIMESTAMP_FRAC_BITS,
      g_coarse_bits  => 28,
      g_utc_bits     => 32,
      g_coarse_range => c_REF_CLK_FREQ)
    port map (
      clk_i    => clk_ref_i,
      rst_n_i  => rst_n_ref,
      valid_i  => tag_valid,
      utc_i    => tag_utc,
      coarse_i => tag_coarse,
      frac_i   => tag_frac,
      valid_o  => rbuf_valid,
      utc_o    => rbuf_utc,
      coarse_o => rbuf_coarse,
      frac_o   => rbuf_frac);

  U_Ring_Buffer : fd_ring_buffer
    generic map (
      g_size_log2 => c_RING_BUFFER_SIZE_LOG2,
      g_frac_bits => c_TIMESTAMP_FRAC_BITS)
    port map (
      rst_n_sys_i => rst_n_sys,
      rst_n_ref_i => rst_n_ref,
      clk_ref_i   => clk_ref_i,
      clk_sys_i   => clk_sys_i,

      tag_valid_i  => rbuf_valid,
      tag_utc_i    => rbuf_utc,
      tag_coarse_i => rbuf_coarse,
      tag_frac_i   => rbuf_frac,

      advance_rbuf_i => advance_rbuf,
      buf_irq_o      => rbuf_irq,
      regs_i         => regs_fromwb,
      regs_o         => regs_towb_rbuf);

  U_Extend_Cal_Pulse : gc_extend_pulse
    generic map (
      g_width => 3)
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_n_ref,
      pulse_i    => regs_fromwb.calr_cal_pulse_o,
      extended_o => cal_pulse_trigger);

  cal_pulse_mask <= (others => cal_pulse_trigger);
  gen_cal_pulse  <= cal_pulse_mask and regs_fromwb.calr_psel_o;


  U_Delay_Channel_1 : fd_delay_channel_driver
    generic map (
      g_frac_bits    => c_TIMESTAMP_FRAC_BITS,
      g_coarse_range => c_REF_CLK_FREQ)
    port map (
      clk_ref_i      => clk_ref_i,
      rst_n_i        => rst_n_ref,
      csync_p1_i     => master_csync_p1,
      csync_utc_i    => master_csync_utc,
      csync_coarse_i => master_csync_coarse,

      rearm_p1_o => chx_rearm(0),
      gen_cal_i  => gen_cal_pulse(0),

      tag_valid_i       => tag_valid,
      tag_utc_i         => tag_utc,
      tag_coarse_i      => tag_coarse,
      tag_frac_i        => tag_frac,
      delay_pulse_o     => chx_delay_pulse(0),
      delay_value_o     => chx_delay_value(0),
      delay_load_o      => chx_delay_load(0),
      delay_load_done_i => chx_delay_load_done(0),
      dcr_mode_i        => regs_fromwb.dcr1_mode_o,
      dcr_enable_i      => regs_fromwb.dcr1_enable_o,
      dcr_pg_arm_i      => regs_fromwb.dcr1_pg_arm_o,
      dcr_pg_arm_o      => regs_towb_local.dcr1_pg_arm_i,
      dcr_pg_arm_load_i => regs_fromwb.dcr1_pg_arm_load_o,
      dcr_pg_trig_o     => regs_towb_local.dcr1_pg_trig_i,
      dcr_update_i      => regs_fromwb.dcr1_update_o,
      dcr_upd_done_o    => regs_towb_local.dcr1_upd_done_i,
      dcr_force_dly_i   => regs_fromwb.dcr1_force_dly_o,
      dcr_pol_i         => regs_fromwb.dcr1_pol_o,
      frr_i             => regs_fromwb.frr1_o,
      u_start_i         => regs_fromwb.u_start1_o,
      c_start_i         => regs_fromwb.c_start1_o,
      f_start_i         => regs_fromwb.f_start1_o,
      u_end_i           => regs_fromwb.u_end1_o,
      c_end_i           => regs_fromwb.c_end1_o,
      f_end_i           => regs_fromwb.f_end1_o);

  --chx_delay_pulse(1) <= dbg(0);
  --chx_delay_pulse(2) <= dbg(1);
  --chx_delay_pulse(3) <= dbg(2);

  U_Delay_Channel_2 : fd_delay_channel_driver
    generic map (
      g_frac_bits    => c_TIMESTAMP_FRAC_BITS,
      g_coarse_range => c_REF_CLK_FREQ)
    port map (
      clk_ref_i      => clk_ref_i,
      rst_n_i        => rst_n_ref,
      csync_p1_i     => master_csync_p1,
      csync_utc_i    => master_csync_utc,
      csync_coarse_i => master_csync_coarse,

      rearm_p1_o => chx_rearm(1),
      gen_cal_i  => gen_cal_pulse(1),

      tag_valid_i       => tag_valid,
      tag_utc_i         => tag_utc,
      tag_coarse_i      => tag_coarse,
      tag_frac_i        => tag_frac,
      delay_pulse_o     => chx_delay_pulse(1),
      delay_value_o     => chx_delay_value(1),
      delay_load_o      => chx_delay_load(1),
      delay_load_done_i => chx_delay_load_done(1),
      dcr_mode_i        => regs_fromwb.dcr2_mode_o,
      dcr_enable_i      => regs_fromwb.dcr2_enable_o,
      dcr_pg_arm_i      => regs_fromwb.dcr2_pg_arm_o,
      dcr_pg_arm_o      => regs_towb_local.dcr2_pg_arm_i,
      dcr_pg_arm_load_i => regs_fromwb.dcr2_pg_arm_load_o,
      dcr_pg_trig_o     => regs_towb_local.dcr2_pg_trig_i,
      dcr_update_i      => regs_fromwb.dcr2_update_o,
      dcr_upd_done_o    => regs_towb_local.dcr2_upd_done_i,
      dcr_force_dly_i   => regs_fromwb.dcr2_force_dly_o,
      dcr_pol_i         => regs_fromwb.dcr2_pol_o,
      frr_i             => regs_fromwb.frr2_o,
      u_start_i         => regs_fromwb.u_start2_o,
      c_start_i         => regs_fromwb.c_start2_o,
      f_start_i         => regs_fromwb.f_start2_o,
      u_end_i           => regs_fromwb.u_end2_o,
      c_end_i           => regs_fromwb.c_end2_o,
      f_end_i           => regs_fromwb.f_end2_o);

  U_Delay_Channel_3 : fd_delay_channel_driver
    generic map (
      g_frac_bits    => c_TIMESTAMP_FRAC_BITS,
      g_coarse_range => c_REF_CLK_FREQ)
    port map (
      clk_ref_i      => clk_ref_i,
      rst_n_i        => rst_n_ref,
      csync_p1_i     => master_csync_p1,
      csync_utc_i    => master_csync_utc,
      csync_coarse_i => master_csync_coarse,

      rearm_p1_o => chx_rearm(2),
      gen_cal_i  => gen_cal_pulse(2),

      tag_valid_i       => tag_valid,
      tag_utc_i         => tag_utc,
      tag_coarse_i      => tag_coarse,
      tag_frac_i        => tag_frac,
      delay_pulse_o     => chx_delay_pulse(2),
      delay_value_o     => chx_delay_value(2),
      delay_load_o      => chx_delay_load(2),
      delay_load_done_i => chx_delay_load_done(2),
      dcr_mode_i        => regs_fromwb.dcr3_mode_o,
      dcr_enable_i      => regs_fromwb.dcr3_enable_o,
      dcr_pg_arm_i      => regs_fromwb.dcr3_pg_arm_o,
      dcr_pg_arm_o      => regs_towb_local.dcr3_pg_arm_i,
      dcr_pg_arm_load_i => regs_fromwb.dcr3_pg_arm_load_o,
      dcr_pg_trig_o     => regs_towb_local.dcr3_pg_trig_i,
      dcr_update_i      => regs_fromwb.dcr3_update_o,
      dcr_upd_done_o    => regs_towb_local.dcr3_upd_done_i,
      dcr_force_dly_i   => regs_fromwb.dcr3_force_dly_o,
      dcr_pol_i         => regs_fromwb.dcr3_pol_o,
      frr_i             => regs_fromwb.frr3_o,
      u_start_i         => regs_fromwb.u_start3_o,
      c_start_i         => regs_fromwb.c_start3_o,
      f_start_i         => regs_fromwb.f_start3_o,
      u_end_i           => regs_fromwb.u_end3_o,
      c_end_i           => regs_fromwb.c_end3_o,
      f_end_i           => regs_fromwb.f_end3_o);


  U_Delay_Channel_4 : fd_delay_channel_driver
    generic map (
      g_frac_bits    => c_TIMESTAMP_FRAC_BITS,
      g_coarse_range => c_REF_CLK_FREQ)
    port map (
      clk_ref_i      => clk_ref_i,
      rst_n_i        => rst_n_ref,
      csync_p1_i     => master_csync_p1,
      csync_utc_i    => master_csync_utc,
      csync_coarse_i => master_csync_coarse,

      rearm_p1_o => chx_rearm(3),
      gen_cal_i  => gen_cal_pulse(3),

      tag_valid_i       => tag_valid,
      tag_utc_i         => tag_utc,
      tag_coarse_i      => tag_coarse,
      tag_frac_i        => tag_frac,
      delay_pulse_o     => chx_delay_pulse(3),
      delay_value_o     => chx_delay_value(3),
      delay_load_o      => chx_delay_load(3),
      delay_load_done_i => chx_delay_load_done(3),
      dcr_mode_i        => regs_fromwb.dcr4_mode_o,
      dcr_enable_i      => regs_fromwb.dcr4_enable_o,
      dcr_pg_arm_i      => regs_fromwb.dcr4_pg_arm_o,
      dcr_pg_arm_o      => regs_towb_local.dcr4_pg_arm_i,
      dcr_pg_arm_load_i => regs_fromwb.dcr4_pg_arm_load_o,
      dcr_pg_trig_o     => regs_towb_local.dcr4_pg_trig_i,
      dcr_update_i      => regs_fromwb.dcr4_update_o,
      dcr_upd_done_o    => regs_towb_local.dcr4_upd_done_i,
      dcr_force_dly_i   => regs_fromwb.dcr4_force_dly_o,
      dcr_pol_i         => regs_fromwb.dcr4_pol_o,
      frr_i             => regs_fromwb.frr4_o,
      u_start_i         => regs_fromwb.u_start4_o,
      c_start_i         => regs_fromwb.c_start4_o,
      f_start_i         => regs_fromwb.f_start4_o,
      u_end_i           => regs_fromwb.u_end4_o,
      c_end_i           => regs_fromwb.c_end4_o,
      f_end_i           => regs_fromwb.f_end4_o);

  U_Delay_Line_Arbiter : fd_delay_line_arbiter
    port map (
      clk_ref_i    => clk_ref_i,
      rst_n_i      => rst_n_ref,
      load_i       => chx_delay_load,
      done_o       => chx_delay_load_done,
      delay_val0_i => chx_delay_value(0),
      delay_val1_i => chx_delay_value(1),
      delay_val2_i => chx_delay_value(2),
      delay_val3_i => chx_delay_value(3),
      delay_val_o  => delay_val_o,
      delay_len_o  => delay_len_o);

  dcr_enable_vec(0) <= regs_fromwb.dcr1_enable_o;
  dcr_enable_vec(1) <= regs_fromwb.dcr2_enable_o;
  dcr_enable_vec(2) <= regs_fromwb.dcr3_enable_o;
  dcr_enable_vec(3) <= regs_fromwb.dcr4_enable_o;
  dcr_mode_vec(0)   <= regs_fromwb.dcr1_mode_o;
  dcr_mode_vec(1)   <= regs_fromwb.dcr2_mode_o;
  dcr_mode_vec(2)   <= regs_fromwb.dcr3_mode_o;
  dcr_mode_vec(3)   <= regs_fromwb.dcr4_mode_o;


  U_Rearm_TDC : fd_rearm_generator
    port map (
      clk_ref_i    => clk_ref_i,
      rst_n_i      => rst_n_ref,
      tag_valid_i  => tag_valid,
      rearm_i      => chx_rearm,
      dcr_enable_i => dcr_enable_vec,
      dcr_mode_i   => dcr_mode_vec,
      rearm_p1_o   => tdc_rearm_p1);


  U_LED_Driver : gc_extend_pulse
    generic map (
      g_width => 10000000)
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_n_ref,
      pulse_i    => tag_valid,
      extended_o => led_trig_o);

  p_gen_cal_trigger : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_ref = '0' then
        trig_cal_o <= '0';
      else
        trig_cal_o <= regs_fromwb.calr_cal_pulse_o;
      end if;
    end if;
  end process;

  regs_towb_local.tdcsr_load_i  <= '0';
  regs_towb_local.tdcsr_empty_i <= acam_emptyf_i;

  delay_pulse_o <= chx_delay_pulse;

end rtl;
