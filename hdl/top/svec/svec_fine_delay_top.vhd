-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

--------------------------------------------------------------------------------
-- CERN BE-CO-HT
-- Fine Delay Mezzanine (fmc-fine-delay)
-- https://ohwr.org/projects/fmc-delay-1ns-8cha
--------------------------------------------------------------------------------
--
-- unit name:   svec_fine_delay
--
-- description: Top entity for Fine Delay reference design.
--
-- Top level design of the SVEC-based FMC Fine Delay (2 mezzanines).
--
-- This is the standard pulse-in/pulse-out WRTD node, with the FMC TDC
-- injecting pulses into the WR network in the form of WRTD messages and
-- the FMC Fine Delay converting those messages back to pulses at the
-- destination.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2011-2019
--------------------------------------------------------------------------------
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 2.0 (the "License"); you may not use this file except
-- in compliance with the License. You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-2.0.
-- Unless required by applicable law or agreed to in writing, software,
-- hardware and materials distributed under this License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
-- or implied. See the License for the specific language governing permissions
-- and limitations under the License.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gencores_pkg.all;
use work.wishbone_pkg.all;
use work.wr_board_pkg.all;
use work.wr_fabric_pkg.all;
use work.fine_delay_pkg.all;
use work.sourceid_svec_fine_delay_pkg;

library unisim;
use unisim.vcomponents.all;

entity svec_fine_delay is
  generic (
    g_WRPC_INITF    : string  := "../../ip_cores/wr-cores/bin/wrpc/wrc_phy8.bram";
    -- Simulation-mode enable parameter. Set by default (synthesis) to 0, and
    -- changed to non-zero in the instantiation of the top level DUT in the
    -- testbench. Its purpose is to reduce some internal counters/timeouts
    -- to speed up simulations.
    g_SIMULATION     : integer := 0);
  port (
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------

    -- Reset from system fpga
    rst_n_i : in std_logic;

    -- Local oscillators
    clk_20m_vcxo_i : in std_logic;  -- 20MHz VCXO clock

    clk_125m_pllref_p_i : in std_logic;  -- 125 MHz PLL reference
    clk_125m_pllref_n_i : in std_logic;

    clk_125m_gtp_n_i : in std_logic;  -- 125 MHz GTP reference
    clk_125m_gtp_p_i : in std_logic;

    ---------------------------------------------------------------------------
    -- VME interface
    ---------------------------------------------------------------------------

    vme_write_n_i    : in    std_logic;
    vme_sysreset_n_i : in    std_logic;
    vme_retry_oe_o   : out   std_logic;
    vme_retry_n_o    : out   std_logic;
    vme_lword_n_b    : inout std_logic;
    vme_iackout_n_o  : out   std_logic;
    vme_iackin_n_i   : in    std_logic;
    vme_iack_n_i     : in    std_logic;
    vme_gap_i        : in    std_logic;
    vme_dtack_oe_o   : out   std_logic;
    vme_dtack_n_o    : out   std_logic;
    vme_ds_n_i       : in    std_logic_vector(1 downto 0);
    vme_data_oe_n_o  : out   std_logic;
    vme_data_dir_o   : out   std_logic;
    vme_berr_o       : out   std_logic;
    vme_as_n_i       : in    std_logic;
    vme_addr_oe_n_o  : out   std_logic;
    vme_addr_dir_o   : out   std_logic;
    vme_irq_o        : out   std_logic_vector(7 downto 1);
    vme_ga_i         : in    std_logic_vector(4 downto 0);
    vme_data_b       : inout std_logic_vector(31 downto 0);
    vme_am_i         : in    std_logic_vector(5 downto 0);
    vme_addr_b       : inout std_logic_vector(31 downto 1);

    ---------------------------------------------------------------------------
    -- SPI interfaces to DACs
    ---------------------------------------------------------------------------

    pll20dac_din_o    : out std_logic;
    pll20dac_sclk_o   : out std_logic;
    pll20dac_sync_n_o : out std_logic;
    pll25dac_din_o    : out std_logic;
    pll25dac_sclk_o   : out std_logic;
    pll25dac_sync_n_o : out std_logic;

    ---------------------------------------------------------------------------
    -- SFP I/O for transceiver
    ---------------------------------------------------------------------------

    sfp_txp_o         : out   std_logic;
    sfp_txn_o         : out   std_logic;
    sfp_rxp_i         : in    std_logic;
    sfp_rxn_i         : in    std_logic;
    sfp_mod_def0_i    : in    std_logic;  -- sfp detect
    sfp_mod_def1_b    : inout std_logic;  -- scl
    sfp_mod_def2_b    : inout std_logic;  -- sda
    sfp_rate_select_o : out   std_logic;
    sfp_tx_fault_i    : in    std_logic;
    sfp_tx_disable_o  : out   std_logic;
    sfp_los_i         : in    std_logic;

    ---------------------------------------------------------------------------
    -- Carrier I2C EEPROM
    ---------------------------------------------------------------------------

    carrier_scl_b : inout std_logic;
    carrier_sda_b : inout std_logic;

    ---------------------------------------------------------------------------
    -- PCB version
    ---------------------------------------------------------------------------
    pcbrev_i : in std_logic_vector(4 downto 0);

    ---------------------------------------------------------------------------
    -- Onewire interface
    ---------------------------------------------------------------------------

    onewire_b : inout std_logic;

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------

    uart_rxd_i : in  std_logic;
    uart_txd_o : out std_logic;

    ---------------------------------------------------------------------------
    -- SPI (flash is connected to SFPGA and routed to AFPGA
    -- once the boot process is complete)
    ---------------------------------------------------------------------------

    spi_sclk_o : out std_logic;
    spi_ncs_o  : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic;

    ---------------------------------------------------------------------------
    -- Carrier front panel LEDs and IOs
    ---------------------------------------------------------------------------

    fp_led_line_oen_o : out std_logic_vector(1 downto 0);
    fp_led_line_o     : out std_logic_vector(1 downto 0);
    fp_led_column_o   : out std_logic_vector(3 downto 0);

    fp_gpio1_b      : out std_logic;  -- PPS output
    fp_gpio2_b      : out std_logic;  -- Ref clock div2 output
    fp_gpio3_b      : in  std_logic;  -- ext 10MHz clock input
    fp_gpio4_b      : in  std_logic;  -- ext PPS input
    fp_term_en_o    : out std_logic_vector(4 downto 1);
    fp_gpio1_a2b_o  : out std_logic;
    fp_gpio2_a2b_o  : out std_logic;
    fp_gpio34_a2b_o : out std_logic;

    ------------------------------------------
    -- FMC slot 1
    ------------------------------------------

    fmc0_fd_tdc_start_p_i : in std_logic;
    fmc0_fd_tdc_start_n_i : in std_logic;

    fmc0_fd_clk_ref_p_i : in std_logic;
    fmc0_fd_clk_ref_n_i : in std_logic;

    fmc0_fd_trig_a_i         : in    std_logic;
    fmc0_fd_tdc_cal_pulse_o  : out   std_logic;
    fmc0_fd_tdc_d_b          : inout std_logic_vector(27 downto 0);
    fmc0_fd_tdc_emptyf_i     : in    std_logic;
    fmc0_fd_tdc_alutrigger_o : out   std_logic;
    fmc0_fd_tdc_wr_n_o       : out   std_logic;
    fmc0_fd_tdc_rd_n_o       : out   std_logic;
    fmc0_fd_tdc_oe_n_o       : out   std_logic;
    fmc0_fd_led_trig_o       : out   std_logic;
    fmc0_fd_tdc_start_dis_o  : out   std_logic;
    fmc0_fd_tdc_stop_dis_o   : out   std_logic;
    fmc0_fd_spi_cs_dac_n_o   : out   std_logic;
    fmc0_fd_spi_cs_pll_n_o   : out   std_logic;
    fmc0_fd_spi_cs_gpio_n_o  : out   std_logic;
    fmc0_fd_spi_sclk_o       : out   std_logic;
    fmc0_fd_spi_mosi_o       : out   std_logic;
    fmc0_fd_spi_miso_i       : in    std_logic;
    fmc0_fd_delay_len_o      : out   std_logic_vector(3 downto 0);
    fmc0_fd_delay_val_o      : out   std_logic_vector(9 downto 0);
    fmc0_fd_delay_pulse_o    : out   std_logic_vector(3 downto 0);

    fmc0_fd_dmtd_clk_o    : out std_logic;
    fmc0_fd_dmtd_fb_in_i  : in  std_logic;
    fmc0_fd_dmtd_fb_out_i : in  std_logic;

    fmc0_fd_pll_status_i : in  std_logic;
    fmc0_fd_ext_rst_n_o  : out std_logic;

    fmc0_fd_onewire_b : inout std_logic;
   
    -- FMC slot management

    fmc0_prsnt_m2c_n_i : in std_logic;

    fmc0_scl_b : inout std_logic;
    fmc0_sda_b : inout std_logic;

    ------------------------------------------
    -- FMC slot 1
    ------------------------------------------
    
    fmc1_fd_tdc_start_p_i : in std_logic;
    fmc1_fd_tdc_start_n_i : in std_logic;

    fmc1_fd_clk_ref_p_i : in std_logic;
    fmc1_fd_clk_ref_n_i : in std_logic;

    fmc1_fd_trig_a_i         : in    std_logic;
    fmc1_fd_tdc_cal_pulse_o  : out   std_logic;
    fmc1_fd_tdc_d_b          : inout std_logic_vector(27 downto 0);
    fmc1_fd_tdc_emptyf_i     : in    std_logic;
    fmc1_fd_tdc_alutrigger_o : out   std_logic;
    fmc1_fd_tdc_wr_n_o       : out   std_logic;
    fmc1_fd_tdc_rd_n_o       : out   std_logic;
    fmc1_fd_tdc_oe_n_o       : out   std_logic;
    fmc1_fd_led_trig_o       : out   std_logic;
    fmc1_fd_tdc_start_dis_o  : out   std_logic;
    fmc1_fd_tdc_stop_dis_o   : out   std_logic;
    fmc1_fd_spi_cs_dac_n_o   : out   std_logic;
    fmc1_fd_spi_cs_pll_n_o   : out   std_logic;
    fmc1_fd_spi_cs_gpio_n_o  : out   std_logic;
    fmc1_fd_spi_sclk_o       : out   std_logic;
    fmc1_fd_spi_mosi_o       : out   std_logic;
    fmc1_fd_spi_miso_i       : in    std_logic;
    fmc1_fd_delay_len_o      : out   std_logic_vector(3 downto 0);
    fmc1_fd_delay_val_o      : out   std_logic_vector(9 downto 0);
    fmc1_fd_delay_pulse_o    : out   std_logic_vector(3 downto 0);

    fmc1_fd_dmtd_clk_o    : out std_logic;
    fmc1_fd_dmtd_fb_in_i  : in  std_logic;
    fmc1_fd_dmtd_fb_out_i : in  std_logic;

    fmc1_fd_pll_status_i : in  std_logic;
    fmc1_fd_ext_rst_n_o  : out std_logic;

    fmc1_fd_onewire_b : inout std_logic;
   
    -- FMC slot management

    fmc1_prsnt_m2c_n_i : in std_logic;

    fmc1_scl_b : inout std_logic;
    fmc1_sda_b : inout std_logic
    );
end entity svec_fine_delay;

architecture arch of svec_fine_delay is

    component fd_ddr_pll
    port (
      RST       : in  std_logic;
      LOCKED    : out std_logic;
      CLK_IN1_P : in  std_logic;
      CLK_IN1_N : in  std_logic;
      CLK_OUT1  : out std_logic;
      CLK_OUT2  : out std_logic);
  end component;

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------

  -- Number of masters attached to the primary wishbone crossbar
  constant c_NUM_WB_MASTERS : integer := 1;

  -- Number of slaves attached to the primary wishbone crossbar
  constant c_NUM_WB_SLAVES : integer := 3;

  -- Primary Wishbone master(s) offsets
  constant c_WB_MASTER_VME : integer := 0;

  -- Primary Wishbone slave(s) offsets
  constant c_WB_SLAVE_METADATA : integer := 0;
  constant c_WB_SLAVE_FD0      : integer := 1;
  constant c_WB_SLAVE_FD1      : integer := 2;

  -- Convention metadata base address
  constant c_METADATA_ADDR : t_wishbone_address := x"0000_4000";

  -- Primary wishbone crossbar layout
  constant c_WB_LAYOUT_ADDR :
    t_wishbone_address_array(c_NUM_WB_SLAVES - 1 downto 0) := (
      c_WB_SLAVE_METADATA => c_METADATA_ADDR,
      c_WB_SLAVE_FD0      => x"0001_0000",
      c_WB_SLAVE_FD1      => x"0002_0000");

  constant c_WB_LAYOUT_MASK :
    t_wishbone_address_array(c_NUM_WB_SLAVES - 1 downto 0) := (
      c_WB_SLAVE_METADATA => x"0003_ffc0",  --    0x40 bytes
      c_WB_SLAVE_FD0      => x"0003_0000",  --   0x200 bytes
      c_WB_SLAVE_FD1      => x"0003_0000"); -- 0x20000 bytes

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  -- Wishbone buse(s) from masters attached to crossbar
  signal cnx_master_out : t_wishbone_master_out_array(c_NUM_WB_MASTERS-1 downto 0);
  signal cnx_master_in  : t_wishbone_master_in_array(c_NUM_WB_MASTERS-1 downto 0);

  -- Wishbone buse(s) to slaves attached to crossbar
  signal cnx_slave_out : t_wishbone_slave_out_array(c_NUM_WB_SLAVES-1 downto 0);
  signal cnx_slave_in  : t_wishbone_slave_in_array(c_NUM_WB_SLAVES-1 downto 0);

  -- clock and reset
  signal areset_n         : std_logic;
  signal clk_dmtd_125m : std_logic;
  signal clk_sys_62m5     : std_logic;
  signal rst_sys_62m5_n   : std_logic;
  signal clk_ref_125m     : std_logic;

  -- VME
  signal vme_access_led    : std_logic;

  -- LEDs and GPIO
  signal pps         : std_logic;
  signal pps_led     : std_logic;
  signal svec_led    : std_logic_vector(15 downto 0);
  signal wr_led_link : std_logic;
  signal wr_led_act  : std_logic;

  -- Interrupts
  signal irq_vector : std_logic_vector(1 downto 0);


  -- WRPC TM interface and aux clocks
  signal tm_link_up         : std_logic;
  signal tm_tai             : std_logic_vector(39 downto 0);
  signal tm_cycles          : std_logic_vector(27 downto 0);
  signal tm_time_valid      : std_logic;
  signal tm_clk_aux_lock_en : std_logic_vector(1 downto 0);
  signal tm_clk_aux_locked  : std_logic_vector(1 downto 0);
  signal tm_dac_value       : std_logic_vector(23 downto 0);
  signal tm_dac_wr          : std_logic_vector(1 downto 0);

    signal dcm0_clk_ref_0, dcm0_clk_ref_180 : std_logic;
  signal fd0_tdc_start                    : std_logic;
  signal fd0_tdc_start_predelay                    : std_logic;
  signal fd0_tdc_start_iodelay_inc                    : std_logic;
  signal fd0_tdc_start_iodelay_rst                    : std_logic;
  signal fd0_tdc_start_iodelay_cal                    : std_logic;
  signal fd0_tdc_start_iodelay_ce                    : std_logic;

  signal tdc0_data_out, tdc0_data_in      : std_logic_vector(27 downto 0);
  signal tdc0_data_oe                     : std_logic;

  signal dcm1_clk_ref_0, dcm1_clk_ref_180 : std_logic;
  signal fd1_tdc_start                    : std_logic;
  signal fd1_tdc_start_predelay                    : std_logic;
  signal fd1_tdc_start_iodelay_inc                    : std_logic;
  signal fd1_tdc_start_iodelay_rst                    : std_logic;
  signal fd1_tdc_start_iodelay_cal                    : std_logic;
  signal fd1_tdc_start_iodelay_ce                    : std_logic;

  signal tdc1_data_out, tdc1_data_in      : std_logic_vector(27 downto 0);
  signal tdc1_data_oe                     : std_logic;


  signal ddr0_pll_reset                  : std_logic;
  signal ddr0_pll_locked, fd0_pll_status : std_logic;
  signal ddr1_pll_reset                  : std_logic;
  signal ddr1_pll_locked, fd1_pll_status : std_logic;

  signal fd0_scl_out, fd0_scl_in, fd0_sda_out, fd0_sda_in : std_logic;
  signal fd1_scl_out, fd1_scl_in, fd1_sda_out, fd1_sda_in : std_logic;
  signal fd0_owr_en, fd0_owr_in                           : std_logic;
  signal fd1_owr_en, fd1_owr_in                           : std_logic;
  signal fd0_irq, fd1_irq : std_logic;


  
  attribute keep                   : string;
  attribute keep of dcm0_clk_ref_0 : signal is "TRUE";
  attribute keep of dcm1_clk_ref_0 : signal is "TRUE";

  -- Misc FMC signals

  attribute iob        : string;
  attribute iob of pps : signal is "FORCE";

begin  -- architecture arch

  areset_n <= vme_sysreset_n_i and rst_n_i;

  cmp_xwb_metadata : entity work.xwb_metadata
    generic map (
      g_VENDOR_ID    => x"0000_10DC",
      g_DEVICE_ID    => x"574f_0002", -- SVEC + 2xFineDelay
      g_VERSION      => x"0300_0009",
      g_CAPABILITIES => x"0000_0000",
      g_COMMIT_ID    => sourceid_svec_fine_delay_pkg.sourceid)
    port map (
      clk_i   => clk_sys_62m5,
      rst_n_i => rst_sys_62m5_n,
      wb_i    => cnx_slave_in(c_WB_SLAVE_METADATA),
      wb_o    => cnx_slave_out(c_WB_SLAVE_METADATA));

  inst_svec_base : entity work.svec_base_wr
    generic map (
      g_WITH_VIC           => TRUE,
      g_WITH_ONEWIRE       => FALSE,
      g_WITH_SPI           => FALSE,
      g_WITH_WR            => TRUE,
      g_WITH_DDR4          => FALSE,
      g_WITH_DDR5          => FALSE,
      g_APP_OFFSET         => c_METADATA_ADDR,
      g_NUM_USER_IRQ       => 2,
      g_DPRAM_INITF        => g_WRPC_INITF,
      g_AUX_CLKS           => 2,
      g_FABRIC_IFACE       => plain,
      g_SIMULATION         => g_SIMULATION,
      g_VERBOSE            => FALSE)
    port map (
      rst_n_i              => areset_n,
      clk_125m_pllref_p_i  => clk_125m_pllref_p_i,
      clk_125m_pllref_n_i  => clk_125m_pllref_n_i,
      clk_20m_vcxo_i       => clk_20m_vcxo_i,
      clk_125m_gtp_n_i     => clk_125m_gtp_n_i,
      clk_125m_gtp_p_i     => clk_125m_gtp_p_i,
      clk_aux_i(0)         => dcm0_clk_ref_0,
      clk_aux_i(1)         => dcm1_clk_ref_0,
      clk_10m_ext_i        => '0',
      pps_ext_i            => '0',
      vme_write_n_i        => vme_write_n_i,
      vme_sysreset_n_i     => vme_sysreset_n_i,
      vme_retry_oe_o       => vme_retry_oe_o,
      vme_retry_n_o        => vme_retry_n_o,
      vme_lword_n_b        => vme_lword_n_b,
      vme_iackout_n_o      => vme_iackout_n_o,
      vme_iackin_n_i       => vme_iackin_n_i,
      vme_iack_n_i         => vme_iack_n_i,
      vme_gap_i            => vme_gap_i,
      vme_dtack_oe_o       => vme_dtack_oe_o,
      vme_dtack_n_o        => vme_dtack_n_o,
      vme_ds_n_i           => vme_ds_n_i,
      vme_data_oe_n_o      => vme_data_oe_n_o,
      vme_data_dir_o       => vme_data_dir_o,
      vme_berr_o           => vme_berr_o,
      vme_as_n_i           => vme_as_n_i,
      vme_addr_oe_n_o      => vme_addr_oe_n_o,
      vme_addr_dir_o       => vme_addr_dir_o,
      vme_irq_o            => vme_irq_o,
      vme_ga_i             => vme_ga_i,
      vme_data_b           => vme_data_b,
      vme_am_i             => vme_am_i,
      vme_addr_b           => vme_addr_b,
      fmc0_scl_b           => fmc0_scl_b,
      fmc0_sda_b           => fmc0_sda_b,
      fmc1_scl_b           => fmc1_scl_b,
      fmc1_sda_b           => fmc1_sda_b,
      fmc0_prsnt_m2c_n_i   => fmc0_prsnt_m2c_n_i,
      fmc1_prsnt_m2c_n_i   => fmc1_prsnt_m2c_n_i,
      onewire_b            => onewire_b,
      carrier_scl_b        => carrier_scl_b,
      carrier_sda_b        => carrier_sda_b,
      spi_sclk_o           => spi_sclk_o,
      spi_ncs_o            => spi_ncs_o,
      spi_mosi_o           => spi_mosi_o,
      spi_miso_i           => spi_miso_i,
      uart_rxd_i           => uart_rxd_i,
      uart_txd_o           => uart_txd_o,
      plldac_sclk_o        => pll20dac_sclk_o,
      plldac_din_o         => pll20dac_din_o,
      pll20dac_din_o       => pll20dac_din_o,
      pll20dac_sclk_o      => pll20dac_sclk_o,
      pll20dac_sync_n_o    => pll20dac_sync_n_o,
      pll25dac_din_o       => pll25dac_din_o,
      pll25dac_sclk_o      => pll25dac_sclk_o,
      pll25dac_sync_n_o    => pll25dac_sync_n_o,
      sfp_txp_o            => sfp_txp_o,
      sfp_txn_o            => sfp_txn_o,
      sfp_rxp_i            => sfp_rxp_i,
      sfp_rxn_i            => sfp_rxn_i,
      sfp_mod_def0_i       => sfp_mod_def0_i,
      sfp_mod_def1_b       => sfp_mod_def1_b,
      sfp_mod_def2_b       => sfp_mod_def2_b,
      sfp_rate_select_o    => sfp_rate_select_o,
      sfp_tx_fault_i       => sfp_tx_fault_i,
      sfp_tx_disable_o     => sfp_tx_disable_o,
      sfp_los_i            => sfp_los_i,
      pcbrev_i             => pcbrev_i,
      clk_dmtd_125m_o => clk_dmtd_125m,
      clk_sys_62m5_o       => clk_sys_62m5,
      rst_sys_62m5_n_o     => rst_sys_62m5_n,
      clk_ref_125m_o       => clk_ref_125m,
      rst_ref_125m_n_o     => open,
      irq_user_i           => irq_vector,
      tm_link_up_o         => tm_link_up,
      tm_time_valid_o      => tm_time_valid,
      tm_tai_o             => tm_tai,
      tm_cycles_o          => tm_cycles,
      tm_dac_value_o       => tm_dac_value,
      tm_dac_wr_o          => tm_dac_wr,
      tm_clk_aux_lock_en_i => tm_clk_aux_lock_en,
      tm_clk_aux_locked_o  => tm_clk_aux_locked,
      pps_p_o              => pps,
      pps_led_o            => pps_led,
      link_ok_o            => open,
      led_link_o           => wr_led_link,
      led_act_o            => wr_led_act,
      app_wb_o             => cnx_master_out(c_WB_MASTER_VME),
      app_wb_i             => cnx_master_in(c_WB_MASTER_VME));

  irq_vector(0) <= fd0_irq;
  irq_vector(1) <= fd1_irq;
  
  -----------------------------------------------------------------------------
  -- Primary wishbone Crossbar
  -----------------------------------------------------------------------------

  cmp_sdb_crossbar : xwb_crossbar
    generic map (
      g_VERBOSE     => FALSE,
      g_NUM_MASTERS => c_NUM_WB_MASTERS,
      g_NUM_SLAVES  => c_NUM_WB_SLAVES,
      g_REGISTERED  => TRUE,
      g_ADDRESS     => c_WB_LAYOUT_ADDR,
      g_MASK        => c_WB_LAYOUT_MASK)
    port map (
      clk_sys_i => clk_sys_62m5,
      rst_n_i   => rst_sys_62m5_n,
      slave_i   => cnx_master_out,
      slave_o   => cnx_master_in,
      master_i  => cnx_slave_out,
      master_o  => cnx_slave_in);

-------------------------------------------------------------------------------
-- FINE DELAY 0 INSTANTIATION
-------------------------------------------------------------------------------

  cmp_fd_tdc_start0 : IBUFDS
    generic map (
      DIFF_TERM    => true,
      IBUF_LOW_PWR => false  -- Low power (TRUE) vs. performance (FALSE) setting for referenced
      )
    port map (
      O  => fd0_tdc_start_predelay,              -- Buffer output
      I  => fmc0_fd_tdc_start_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => fmc0_fd_tdc_start_n_i  -- Diff_n buffer input (connect directly to top-level port)
      );

  cmp_fd_tdc_start_delay0 : IODELAY2
    generic map (
      DELAY_SRC => "IDATAIN",
      IDELAY_TYPE => "VARIABLE_FROM_ZERO",
      DATA_RATE => "SDR"
      )
    port map (
      IDATAIN => fd0_tdc_start_predelay,
      DATAOUT2 => fd0_tdc_start,
      INC => fd0_tdc_start_iodelay_inc,
      CE =>  fd0_tdc_start_iodelay_ce,
      RST =>  fd0_tdc_start_iodelay_rst,
      CLK => dcm0_clk_ref_0,
      ODATAIN => '0',
      CAL => fd0_tdc_start_iodelay_cal,
      T => '1',
      IOCLK0 => dcm0_clk_ref_0,
      IOCLK1 => '0'
      );

  
  U_DDR_PLL0 : fd_ddr_pll
    port map (
      RST       => ddr0_pll_reset,
      LOCKED    => ddr0_pll_locked,
      CLK_IN1_P => fmc0_fd_clk_ref_p_i,
      CLK_IN1_N => fmc0_fd_clk_ref_n_i,
      CLK_OUT1  => dcm0_clk_ref_0,
      CLK_OUT2  => dcm0_clk_ref_180);

  ddr0_pll_reset <= not fmc0_fd_pll_status_i;
  fd0_pll_status <= fmc0_fd_pll_status_i and ddr0_pll_locked;

  U_FineDelay_Core0 : entity work.fine_delay_core
    generic map (
      g_with_wr_core        => true,
      g_simulation          => f_int2bool(g_simulation),
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_fmc_slot_id         => 0)
    port map (
      clk_ref_0_i   => dcm0_clk_ref_0,
      clk_ref_180_i => dcm0_clk_ref_180,
      clk_sys_i     => clk_sys_62m5,
      clk_dmtd_i    => clk_dmtd_125m,
      rst_n_i       => rst_sys_62m5_n,
      dcm_reset_o   => open,
      dcm_locked_i  => ddr0_pll_locked,

      trig_a_i          => fmc0_fd_trig_a_i,
      tdc_cal_pulse_o   => fmc0_fd_tdc_cal_pulse_o,
      tdc_start_i       => fd0_tdc_start,
      dmtd_fb_in_i      => fmc0_fd_dmtd_fb_in_i,
      dmtd_fb_out_i     => fmc0_fd_dmtd_fb_out_i,
      dmtd_samp_o       => fmc0_fd_dmtd_clk_o,
      led_trig_o        => fmc0_fd_led_trig_o,
      ext_rst_n_o       => fmc0_fd_ext_rst_n_o,
      pll_status_i      => fd0_pll_status,
      acam_d_o          => tdc0_data_out,
      acam_d_i          => tdc0_data_in,
      acam_d_oen_o      => tdc0_data_oe,
      acam_emptyf_i     => fmc0_fd_tdc_emptyf_i,
      acam_alutrigger_o => fmc0_fd_tdc_alutrigger_o,
      acam_wr_n_o       => fmc0_fd_tdc_wr_n_o,
      acam_rd_n_o       => fmc0_fd_tdc_rd_n_o,
      acam_start_dis_o  => fmc0_fd_tdc_start_dis_o,
      acam_stop_dis_o   => fmc0_fd_tdc_stop_dis_o,
      spi_cs_dac_n_o    => fmc0_fd_spi_cs_dac_n_o,
      spi_cs_pll_n_o    => fmc0_fd_spi_cs_pll_n_o,
      spi_cs_gpio_n_o   => fmc0_fd_spi_cs_gpio_n_o,
      spi_sclk_o        => fmc0_fd_spi_sclk_o,
      spi_mosi_o        => fmc0_fd_spi_mosi_o,
      spi_miso_i        => fmc0_fd_spi_miso_i,

      delay_len_o   => fmc0_fd_delay_len_o,
      delay_val_o   => fmc0_fd_delay_val_o,
      delay_pulse_o => fmc0_fd_delay_pulse_o,

      tm_link_up_i         => tm_link_up,
      tm_time_valid_i      => tm_time_valid,
      tm_cycles_i          => tm_cycles,
      tm_utc_i             => tm_tai,
      tm_clk_aux_lock_en_o => tm_clk_aux_lock_en(0),
      tm_clk_aux_locked_i  => tm_clk_aux_locked(0),
      tm_clk_dmtd_locked_i => '1',
      tm_dac_value_i       => tm_dac_value,
      tm_dac_wr_i          => tm_dac_wr(0),

      owr_en_o        => fd0_owr_en,
      owr_i           => fd0_owr_in,
      i2c_scl_oen_o   => fd0_scl_out,
      i2c_scl_i       => fd0_scl_in,
      i2c_sda_oen_o   => fd0_sda_out,
      i2c_sda_i       => fd0_sda_in,
      fmc_present_n_i => fmc0_prsnt_m2c_n_i,

      idelay_cal_o => fd0_tdc_start_iodelay_cal,
      idelay_rst_o => fd0_tdc_start_iodelay_rst,
      idelay_ce_o => fd0_tdc_start_iodelay_ce,
      idelay_inc_o => fd0_tdc_start_iodelay_inc,
      idelay_busy_i => '0',
       
      wb_adr_i   => cnx_slave_in(c_WB_SLAVE_FD0).adr,
      wb_dat_i   => cnx_slave_in(c_WB_SLAVE_FD0).dat,
      wb_dat_o   => cnx_slave_out(c_WB_SLAVE_FD0).dat,
      wb_sel_i   => cnx_slave_in(c_WB_SLAVE_FD0).sel,
      wb_cyc_i   => cnx_slave_in(c_WB_SLAVE_FD0).cyc,
      wb_stb_i   => cnx_slave_in(c_WB_SLAVE_FD0).stb,
      wb_we_i    => cnx_slave_in(c_WB_SLAVE_FD0).we,
      wb_ack_o   => cnx_slave_out(c_WB_SLAVE_FD0).ack,
      wb_stall_o => cnx_slave_out(c_WB_SLAVE_FD0).stall,
      wb_irq_o   => fd0_irq);

  cnx_slave_out(c_WB_SLAVE_FD0).err <= '0';
  cnx_slave_out(c_WB_SLAVE_FD0).rty <= '0';


-- tristate buffer for the TDC data bus:
  fmc0_fd_tdc_d_b    <= tdc0_data_out when tdc0_data_oe = '1' else (others => 'Z');
  fmc0_fd_tdc_oe_n_o <= '1';
  tdc0_data_in   <= fmc0_fd_tdc_d_b;

  fmc0_fd_onewire_b <= '0' when fd0_owr_en = '1' else 'Z';
  fd0_owr_in    <= fmc0_fd_onewire_b;


-------------------------------------------------------------------------------
-- FINE DELAY 1 INSTANTIATION
-------------------------------------------------------------------------------

  cmp_fd_tdc_start1 : IBUFDS
    generic map (
      DIFF_TERM    => true,
      IBUF_LOW_PWR => false  -- Low power (TRUE) vs. performance (FALSE) setting for referenced
      )
    port map (
      O  => fd1_tdc_start_predelay,              -- Buffer output
      I  => fmc1_fd_tdc_start_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => fmc1_fd_tdc_start_n_i  -- Diff_n buffer input (connect directly to top-level port)
      );

  cmp_fd_tdc_start_delay1 : IODELAY2
    generic map (
      DELAY_SRC => "IDATAIN",
      IDELAY_TYPE => "VARIABLE_FROM_ZERO",
      DATA_RATE => "SDR"
      )
    port map (
      IDATAIN => fd1_tdc_start_predelay,
      DATAOUT2 => fd1_tdc_start,
      INC => fd1_tdc_start_iodelay_inc,
      CE =>  fd1_tdc_start_iodelay_ce,
      RST =>  fd1_tdc_start_iodelay_rst,
      CLK => dcm1_clk_ref_0,
      ODATAIN => '0',
      CAL => fd1_tdc_start_iodelay_cal,
      T => '1',
      IOCLK0 => dcm1_clk_ref_0,
      IOCLK1 => '0'
      );

    
  U_DDR_PLL1 : fd_ddr_pll
    port map (
      RST       => ddr1_pll_reset,
      LOCKED    => ddr1_pll_locked,
      CLK_IN1_P => fmc1_fd_clk_ref_p_i,
      CLK_IN1_N => fmc1_fd_clk_ref_n_i,
      CLK_OUT1  => dcm1_clk_ref_0,
      CLK_OUT2  => dcm1_clk_ref_180);

  ddr1_pll_reset <= not fmc1_fd_pll_status_i;
  fd1_pll_status <= fmc1_fd_pll_status_i and ddr1_pll_locked;

  U_FineDelay_Core1 : entity work.fine_delay_core
    generic map (
      g_with_wr_core        => true,
      g_simulation          => f_int2bool(g_simulation),
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_fmc_slot_id         => 1)
    port map (
      clk_ref_0_i   => dcm1_clk_ref_0,
      clk_ref_180_i => dcm1_clk_ref_180,
      clk_sys_i     => clk_sys_62m5,
      clk_dmtd_i    => clk_dmtd_125m,
      rst_n_i       => rst_sys_62m5_n,
      dcm_reset_o   => open,
      dcm_locked_i  => ddr1_pll_locked,

      trig_a_i          => fmc1_fd_trig_a_i,
      tdc_cal_pulse_o   => fmc1_fd_tdc_cal_pulse_o,
      tdc_start_i       => fd1_tdc_start,
      dmtd_fb_in_i      => fmc1_fd_dmtd_fb_in_i,
      dmtd_fb_out_i     => fmc1_fd_dmtd_fb_out_i,
      dmtd_samp_o       => fmc1_fd_dmtd_clk_o,
      led_trig_o        => fmc1_fd_led_trig_o,
      ext_rst_n_o       => fmc1_fd_ext_rst_n_o,
      pll_status_i      => fd1_pll_status,
      acam_d_o          => tdc1_data_out,
      acam_d_i          => tdc1_data_in,
      acam_d_oen_o      => tdc1_data_oe,
      acam_emptyf_i     => fmc1_fd_tdc_emptyf_i,
      acam_alutrigger_o => fmc1_fd_tdc_alutrigger_o,
      acam_wr_n_o       => fmc1_fd_tdc_wr_n_o,
      acam_rd_n_o       => fmc1_fd_tdc_rd_n_o,
      acam_start_dis_o  => fmc1_fd_tdc_start_dis_o,
      acam_stop_dis_o   => fmc1_fd_tdc_stop_dis_o,
      spi_cs_dac_n_o    => fmc1_fd_spi_cs_dac_n_o,
      spi_cs_pll_n_o    => fmc1_fd_spi_cs_pll_n_o,
      spi_cs_gpio_n_o   => fmc1_fd_spi_cs_gpio_n_o,
      spi_sclk_o        => fmc1_fd_spi_sclk_o,
      spi_mosi_o        => fmc1_fd_spi_mosi_o,
      spi_miso_i        => fmc1_fd_spi_miso_i,

      delay_len_o   => fmc1_fd_delay_len_o,
      delay_val_o   => fmc1_fd_delay_val_o,
      delay_pulse_o => fmc1_fd_delay_pulse_o,

      tm_link_up_i         => tm_link_up,
      tm_time_valid_i      => tm_time_valid,
      tm_cycles_i          => tm_cycles,
      tm_utc_i             => tm_tai,
      tm_clk_aux_lock_en_o => tm_clk_aux_lock_en(1),
      tm_clk_aux_locked_i  => tm_clk_aux_locked(1),
      tm_clk_dmtd_locked_i => '1',  --    FIXME: fan out real signal from the
      --    --    WRCore
      tm_dac_value_i       => tm_dac_value,
      tm_dac_wr_i          => tm_dac_wr(1),

      owr_en_o        => fd1_owr_en,
      owr_i           => fd1_owr_in,
      i2c_scl_oen_o   => fd1_scl_out,
      i2c_scl_i       => fd1_scl_in,
      i2c_sda_oen_o   => fd1_sda_out,
      i2c_sda_i       => fd1_sda_in,
      fmc_present_n_i => fmc1_prsnt_m2c_n_i,

      idelay_cal_o => fd1_tdc_start_iodelay_cal,
      idelay_rst_o => fd1_tdc_start_iodelay_rst,
      idelay_ce_o => fd1_tdc_start_iodelay_ce,
      idelay_inc_o => fd1_tdc_start_iodelay_inc,
      idelay_busy_i => '0',
      
      wb_adr_i   => cnx_slave_in(c_WB_SLAVE_FD1).adr,
      wb_dat_i   => cnx_slave_in(c_WB_SLAVE_FD1).dat,
      wb_dat_o   => cnx_slave_out(c_WB_SLAVE_FD1).dat,
      wb_sel_i   => cnx_slave_in(c_WB_SLAVE_FD1).sel,
      wb_cyc_i   => cnx_slave_in(c_WB_SLAVE_FD1).cyc,
      wb_stb_i   => cnx_slave_in(c_WB_SLAVE_FD1).stb,
      wb_we_i    => cnx_slave_in(c_WB_SLAVE_FD1).we,
      wb_ack_o   => cnx_slave_out(c_WB_SLAVE_FD1).ack,
      wb_stall_o => cnx_slave_out(c_WB_SLAVE_FD1).stall,
      wb_irq_o   => fd1_irq);

  cnx_slave_out(c_WB_SLAVE_FD1).err <= '0';
  cnx_slave_out(c_WB_SLAVE_FD1).rty <= '0';

-- tristate buffer for the TDC data bus:
  fmc1_fd_tdc_d_b    <= tdc1_data_out when tdc1_data_oe = '1' else (others => 'Z');
  fmc1_fd_tdc_oe_n_o <= '1';
  tdc1_data_in   <= fmc1_fd_tdc_d_b;

  fmc1_fd_onewire_b <= '0' when fd1_owr_en = '1' else 'Z';
  fd1_owr_in    <= fmc1_fd_onewire_b;

  cmp_vme_led_extend : gc_extend_pulse
    generic map (
      g_width => 5000000)
    port map (
      clk_i      => clk_sys_62m5,
      rst_n_i    => rst_sys_62m5_n,
      pulse_i    => cnx_slave_in(c_WB_MASTER_VME).cyc,
      extended_o => vme_access_led);


  -----------------------------------------------------------------------------
  -- Carrier front panel LEDs and LEMOs
  -----------------------------------------------------------------------------

  cmp_led_controller : gc_bicolor_led_ctrl
    generic map(
      g_NB_COLUMN    => 4,
      g_NB_LINE      => 2,
      g_CLK_FREQ     => 62500000,  -- in Hz
      g_REFRESH_RATE => 250        -- in Hz
      )
    port map(
      rst_n_i => rst_sys_62m5_n,
      clk_i   => clk_sys_62m5,

      led_intensity_i => "1100100",  -- in %

      led_state_i => svec_led,

      column_o   => fp_led_column_o,
      line_o     => fp_led_line_o,
      line_oen_o => fp_led_line_oen_o);

  -- Drive the front panel LEDs:

  -- LED 1: WR Link status
  svec_led(6) <= wr_led_link;
  svec_led(7) <= '0';

  -- LED 2: WR Link activity status
  svec_led(4) <= wr_led_act;
  svec_led(5) <= '0';

  -- LED 3: WR PPS blink
  svec_led(2) <= pps_led;
  svec_led(3) <= '0';

  -- LED 4: WR Time validity
  svec_led(0) <= tm_time_valid;
  svec_led(1) <= '0';

  -- LED 5: VME access
  svec_led(14) <= vme_access_led;
  svec_led(15) <= '0';

  -- LED 6: FD0 locked to WR
  svec_led(12) <= tm_clk_aux_locked(0);
  svec_led(13) <= '0';

  -- LED 6: FD1 locked to WR
  svec_led(10) <= tm_clk_aux_locked(1);
  svec_led(11) <= '0';

  svec_led(8) <= '0';
  svec_led(9) <= '0';

  -- Front panel IO configuration
  fp_gpio1_b      <= tm_clk_aux_locked(0);
  fp_gpio2_b      <= tm_clk_aux_locked(1);
  
  fp_term_en_o    <= (others => '0');
  fp_gpio1_a2b_o  <= '1';
  fp_gpio2_a2b_o  <= '1';
  fp_gpio34_a2b_o <= '0';

end architecture arch;
