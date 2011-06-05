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
    tdc_start_i: in std_logic;

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

    csync_p1_i     : in std_logic;
    csync_coarse_i : in std_logic_vector(27 downto 0);
    csync_utc_i    : in std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------------
    -- Wishbone (classic)
    ---------------------------------------------------------------------------

    wb_adr_i : in  std_logic_vector(4 downto 0);
    wb_dat_i : in  std_logic_vector(31 downto 0);
    wb_dat_o : out std_logic_vector(31 downto 0);
    wb_cyc_i : in  std_logic;
    wb_stb_i : in  std_logic;
    wb_we_i  : in  std_logic;
    wb_ack_o : out std_logic


    );

end fine_delay_core;

architecture rtl of fine_delay_core is

  constant c_RSTR_TRIGGER_VALUE : std_logic_vector(31 downto 0) := x"deadbeef";

  component fine_delay_wb
    port (
      rst_n_i   : in    std_logic;
      wb_clk_i  : in    std_logic;
      wb_addr_i : in    std_logic_vector(4 downto 0);
      wb_data_i : in    std_logic_vector(31 downto 0);
      wb_data_o : out   std_logic_vector(31 downto 0);
      wb_cyc_i  : in    std_logic;
      wb_sel_i  : in    std_logic_vector(3 downto 0);
      wb_stb_i  : in    std_logic;
      wb_we_i   : in    std_logic;
      wb_ack_o  : out   std_logic;
      clk_ref_i : in    std_logic;
      regs_b    : inout t_fd_registers);
  end component;
  
  component fd_cal_pulse_gen
    port (
      clk_sys_i     : in  std_logic;
      rst_n_i       : in  std_logic;
      pulse_o       : out std_logic;
      pgcr_enable_i : in  std_logic;
      pgcr_period_i : in  std_logic_vector(30 downto 0));
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
      tag_raw_frac_o    : out   std_logic_vector(22 downto 0);
      tag_rearm_p1_i    : in    std_logic;
      tag_valid_p1_o    : out   std_logic;
      csync_coarse_i    : in    std_logic_vector(27 downto 0);
      csync_utc_i       : in    std_logic_vector(31 downto 0);
      csync_p1_i        : in    std_logic;
      regs_b            : inout t_fd_registers); 
  end component;
  
  signal rstn_host_sysclk : std_logic;
  signal rstn_host_refclk : std_logic;
  signal rstn_host_d0     : std_logic;
  signal rstn_host_d1     : std_logic;

  signal pulse : std_logic;

  signal tag_frac : std_logic_vector(11 downto 0);
  signal tag_frac_raw : std_logic_vector(22 downto 0);
  signal tag_coarse : std_logic_vector(27 downto 0);
  signal tag_utc : std_logic_vector(31 downto 0);
  
  signal tag_valid_p1 : std_logic;

  signal regs : t_fd_registers := c_fd_registers_init_value;

  
begin  -- rtl

  -- drive to 'Z'
--  regs <= c_fd_registers_init_value;
  
  p_soft_reset : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if(rst_n_i = '0') then
        rstn_host_sysclk <= '0';
      else
        if(regs.rstr_wr_o = '1' and regs.rstr_o = c_RSTR_TRIGGER_VALUE) then
          rstn_host_sysclk <= '0';
        else
          rstn_host_sysclk <= '1';
        end if;
      end if;
    end if;
  end process;

  p_sync_reset_refclk : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      rstn_host_refclk <= rst_n_i and rstn_host_sysclk;
      rstn_host_d0     <= rstn_host_sysclk;
      rstn_host_d1     <= rstn_host_d0;
      rstn_host_refclk <= rstn_host_d1;
    end if;
  end process;

  p_gpio_loads : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if (rstn_host_sysclk = '0') then
        spi_cs_dac_n_o  <= '1';
        spi_cs_pll_n_o  <= '1';
        spi_cs_gpio_n_o <= '1';
        spi_sclk_o      <= '0';
        spi_mosi_o      <= '0';

        regs.gprr_miso_i <= '0';
      else

        if(regs.gpsr_cs_pll_wr_o = '1' and regs.gpsr_cs_pll_o = '1') then
          spi_cs_pll_n_o <= '1';
        elsif (regs.gpcr_cs_pll_wr_o = '1' and regs.gpcr_cs_pll_o = '1') then
          spi_cs_pll_n_o <= '0';
        end if;

        if(regs.gpsr_cs_gpio_wr_o = '1' and regs.gpsr_cs_gpio_o = '1') then
          spi_cs_gpio_n_o <= '1';
        elsif (regs.gpcr_cs_gpio_wr_o = '1' and regs.gpcr_cs_gpio_o = '1') then
          spi_cs_gpio_n_o <= '0';
        end if;

        if(regs.gpsr_mosi_wr_o = '1' and regs.gpsr_mosi_o = '1') then
          spi_mosi_o <= '1';
        elsif (regs.gpcr_mosi_wr_o = '1' and regs.gpcr_mosi_o = '1') then
          spi_mosi_o <= '0';
        end if;

        if(regs.gpsr_sclk_wr_o = '1' and regs.gpsr_sclk_o = '1') then
          spi_sclk_o <= '1';
        elsif (regs.gpcr_sclk_wr_o = '1' and regs.gpcr_sclk_o = '1') then
          spi_sclk_o <= '0';
        end if;

        regs.gprr_miso_i <= spi_miso_i;
      end if;
    end if;
  end process;


  U_WB_SLAVE : fine_delay_wb
    port map (
      rst_n_i   => rstn_host_sysclk,
      wb_clk_i  => clk_sys_i,
      wb_addr_i => wb_adr_i(4 downto 0),
      wb_data_i => wb_dat_i,
      wb_data_o => wb_dat_o,
      wb_cyc_i  => wb_cyc_i,
      wb_sel_i  => "1111",
      wb_stb_i  => wb_stb_i,
      wb_we_i   => wb_we_i,
      wb_ack_o  => wb_ack_o,
      clk_ref_i => clk_ref_i,

      regs_b => regs
      );

  regs.tsfifo_wr_req_i <= not regs.tsfifo_wr_full_o and tag_valid_p1;
  regs.tsfifo_utc_i <= tag_utc;
  regs.tsfifo_coarse_i <= tag_coarse;
  regs.tsfifo_frac_raw_i <= tag_frac_raw;
  regs.tsfifo_frac_i <= "00000000000" &                        tag_frac;
  

  U_Acam_TSU : fd_acam_timestamper
    generic map (
      g_min_pulse_width => 3,
      g_clk_ref_freq    => 125000000,
      g_frac_bits       => 12)
    port map (
      clk_ref_i => clk_ref_i,
      rst_n_i   => rstn_host_refclk,

      tdc_start_i => tdc_start_i,
      
      trig_a_n_i => trig_a_n_i,

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

      tag_frac_o     => tag_frac(11 downto 0),
      tag_coarse_o   => tag_coarse,
      tag_utc_o      => tag_utc,
      tag_rearm_p1_i => '1',
      tag_raw_frac_o => tag_frac_raw,
      tag_valid_p1_o => tag_valid_p1,

      csync_coarse_i => csync_coarse_i,
      csync_utc_i    => csync_utc_i,
      csync_p1_i     => csync_p1_i,

      regs_b => regs
      );

  U_Cal_Pulse_Gen: fd_cal_pulse_gen
    port map (
      clk_sys_i     => clk_ref_i,
      rst_n_i       => rstn_host_sysclk,
      pulse_o       => pulse,
      pgcr_enable_i => regs.pgcr_enable_o,
      pgcr_period_i => regs.pgcr_period_o);
  

  trig_cal_o <= '0';
  regs.tdcsr_load_i  <= '0';
--  regs.tdcsr_err_i   <= acam_err_i;
  regs.tdcsr_empty_i <= acam_emptyf_i;

  delay_len_o   <= (others => '0');
  delay_pulse_o(0) <= pulse;
  delay_pulse_o(1) <= pulse;
  delay_pulse_o(2) <= pulse;
  delay_pulse_o(3) <= pulse;
  
  delay_val_o   <= (others => '0');
  
  
end rtl;
