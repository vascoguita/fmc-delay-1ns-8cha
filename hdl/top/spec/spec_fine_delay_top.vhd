-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

--------------------------------------------------------------------------------
-- CERN BE-CO-HT
-- Fine Delay Mezzanine (fmc-fine-delay)
-- https://ohwr.org/projects/fmc-delay-1ns-8cha
--------------------------------------------------------------------------------
--
-- unit name:   spec_fine_delay
--
-- description: Top entity for Fine Delay reference design.
--
-- Top level design of the SPEC-based FMC Fine Delay.
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
use work.sourceid_spec_fine_delay_pkg;


library unisim;
use unisim.vcomponents.all;

entity spec_fine_delay is
  generic (
    g_WRPC_INITF    : string  := "../../ip_cores/wr-cores/bin/wrpc/wrc_phy8.bram";
    -- Simulation-mode enable parameter. Set by default (synthesis) to 0, and
    -- changed to non-zero in the instantiation of the top level DUT in the
    -- testbench. Its purpose is to reduce some internal counters/timeouts
    -- to speed up simulations.
    g_SIMULATION    : integer := 0);
  port (
    -- Reset button
    button1_n_i : in  std_logic;

    -- Local oscillators
    clk_20m_vcxo_i : in std_logic;  -- 20MHz VCXO clock

    clk_125m_pllref_p_i : in std_logic;  -- 125 MHz PLL reference
    clk_125m_pllref_n_i : in std_logic;

    clk_125m_gtp_n_i : in std_logic;  -- 125 MHz GTP reference
    clk_125m_gtp_p_i : in std_logic;

    -- DAC interface (20MHz and 25MHz VCXO)
    pll25dac_cs_n_o : out std_logic;          -- 25MHz VCXO
    pll20dac_cs_n_o : out std_logic;          -- 20MHz VCXO
    plldac_din_o    : out std_logic;
    plldac_sclk_o   : out std_logic;

    -- Carrier front panel LEDs
    led_act_o   : out std_logic;
    led_link_o : out std_logic;

    -- Auxiliary pins
    aux_leds_o : out std_logic_vector(3 downto 0);

    -- PCB version
    pcbrev_i : in std_logic_vector(3 downto 0);

    -- Carrier 1-wire interface (DS18B20 thermometer + unique ID)
    onewire_b : inout std_logic;

    -- SFP
    sfp_txp_o         : out   std_logic;
    sfp_txn_o         : out   std_logic;
    sfp_rxp_i         : in    std_logic;
    sfp_rxn_i         : in    std_logic;
    sfp_mod_def0_i    : in    std_logic;        -- sfp detect
    sfp_mod_def1_b    : inout std_logic;        -- scl
    sfp_mod_def2_b    : inout std_logic;        -- sda
    sfp_rate_select_o : out   std_logic;
    sfp_tx_fault_i    : in    std_logic;
    sfp_tx_disable_o  : out   std_logic;
    sfp_los_i         : in    std_logic;

    -- SPI
    spi_sclk_o : out std_logic;
    spi_ncs_o  : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic := 'L';

    -- UART
    uart_rxd_i : in  std_logic;
    uart_txd_o : out std_logic;

    ------------------------------------------
    -- GN4124 interface
    --
    -- gn_gpio_b[1] -> AB19 -> GN4124 GPIO9
    -- gn_gpio_b[0] -> U16  -> GN4124 GPIO8
    ------------------------------------------
    gn_rst_n_i      : in    std_logic;
    gn_p2l_clk_n_i  : in    std_logic;
    gn_p2l_clk_p_i  : in    std_logic;
    gn_p2l_rdy_o    : out   std_logic;
    gn_p2l_dframe_i : in    std_logic;
    gn_p2l_valid_i  : in    std_logic;
    gn_p2l_data_i   : in    std_logic_vector(15 downto 0);
    gn_p_wr_req_i   : in    std_logic_vector(1 downto 0);
    gn_p_wr_rdy_o   : out   std_logic_vector(1 downto 0);
    gn_rx_error_o   : out   std_logic;
    gn_l2p_clk_n_o  : out   std_logic;
    gn_l2p_clk_p_o  : out   std_logic;
    gn_l2p_dframe_o : out   std_logic;
    gn_l2p_valid_o  : out   std_logic;
    gn_l2p_edb_o    : out   std_logic;
    gn_l2p_data_o   : out   std_logic_vector(15 downto 0);
    gn_l2p_rdy_i    : in    std_logic;
    gn_l_wr_rdy_i   : in    std_logic_vector(1 downto 0);
    gn_p_rd_d_rdy_i : in    std_logic_vector(1 downto 0);
    gn_tx_error_i   : in    std_logic;
    gn_vc_rdy_i     : in    std_logic_vector(1 downto 0);
    gn_gpio_b       : inout std_logic_vector(1 downto 0);

    ------------------------------------------
    -- FMC slots
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
    fmc0_sda_b : inout std_logic);

end entity spec_fine_delay;

architecture arch of spec_fine_delay is


  component IBUFDS is
    generic (
    CAPACITANCE : string  := "DONT_CARE";
    DIFF_TERM   : boolean :=  FALSE;
    DQS_BIAS    : string :=  "FALSE";
    IBUF_DELAY_VALUE : string := "0";
    IBUF_LOW_PWR : boolean :=  TRUE;
    IFD_DELAY_VALUE  : string := "AUTO";
    IOSTANDARD  : string  := "DEFAULT");
    port (
      O  : out std_ulogic;
      I  : in  std_ulogic;
      IB : in  std_ulogic);
  end component IBUFDS;
  
  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------

  -- Number of masters attached to the primary wishbone crossbar
  constant c_NUM_WB_MASTERS : integer := 1;

  -- Number of slaves attached to the primary wishbone crossbar
  constant c_NUM_WB_SLAVES : integer := 2;

  -- Primary Wishbone master(s) offsets
  constant c_WB_MASTER_GENNUM : integer := 0;

  -- Primary Wishbone slave(s) offsets
  constant c_WB_SLAVE_METADATA : integer := 0;
  constant c_WB_SLAVE_FMC_DELAY  : integer := 1;

  -- Convention metadata base address
  constant c_METADATA_ADDR : t_wishbone_address := x"0000_2000";

  -- Primary wishbone crossbar layout
  constant c_WB_LAYOUT_ADDR :
    t_wishbone_address_array(c_NUM_WB_SLAVES - 1 downto 0) := (
      c_WB_SLAVE_METADATA => c_METADATA_ADDR,
      c_WB_SLAVE_FMC_DELAY  => x"0001_0000");

  constant c_WB_LAYOUT_MASK :
    t_wishbone_address_array(c_NUM_WB_SLAVES - 1 downto 0) := (
      c_WB_SLAVE_METADATA => x"0003_ffc0",  --    0x40 bytes
      c_WB_SLAVE_FMC_DELAY  => x"0003_0000");  -- 0x10000 bytes

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  -- Clocks and resets
  signal clk_dmtd_125m : std_logic;
  signal clk_sys_62m5       : std_logic;
  signal clk_ref_125m       : std_logic;

  signal rst_sys_62m5_n     : std_logic := '0';
  signal rst_ref_125m_n     : std_logic := '0';

  -- Wishbone buse(s) from master(s) to crossbar slave port(s)
  signal cnx_master_out : t_wishbone_master_out_array(c_NUM_WB_MASTERS-1 downto 0);
  signal cnx_master_in  : t_wishbone_master_in_array(c_NUM_WB_MASTERS-1 downto 0);

  -- Wishbone buse(s) from crossbar master port(s) to slave(s)
  signal cnx_slave_out : t_wishbone_slave_out_array(c_NUM_WB_SLAVES-1 downto 0);
  signal cnx_slave_in  : t_wishbone_slave_in_array(c_NUM_WB_SLAVES-1 downto 0);

  -- WRPC TM interface and status
  signal tm_link_up         : std_logic;
  signal tm_tai             : std_logic_vector(39 downto 0);
  signal tm_cycles          : std_logic_vector(27 downto 0);
  signal tm_time_valid      : std_logic;
  signal tm_time_valid_sync : std_logic;
  signal tm_clk_aux_lock_en : std_logic_vector(0 downto 0);
  signal tm_clk_aux_locked : std_logic_vector(0 downto 0);
  signal tm_dac_value : std_logic_vector( 23 downto 0);
  signal tm_dac_wr : std_logic_vector(0 downto 0);
  
  signal wrabbit_en         : std_logic;
  signal pps_led            : std_logic;

  -- Wishbone bus from cross-clocking module to FMC0 mezzanine
  signal cnx_fmc0_sync_master_out : t_wishbone_master_out;
  signal cnx_fmc0_sync_master_in  : t_wishbone_master_in;


  -- Wishbone buses from FMC ADC cores to DDR controller
  signal fmc0_wb_ddr_in  : t_wishbone_master_data64_in;
  signal fmc0_wb_ddr_out : t_wishbone_master_data64_out;

  -- Interrupts and status
  signal fmc0_irq           : std_logic;
  signal irq_vector         : std_logic_vector(4 downto 0);
  signal gn4124_access      : std_logic;


  signal fmc0_fd_tdc_start : std_logic;
  signal fmc0_ddr_pll_reset : std_logic;
  signal fmc0_ddr_pll_locked: std_logic;

  signal fmc0_dcm_clk_ref_0 : std_logic;
  signal fmc0_dcm_clk_ref_180 : std_logic;

  signal fmc0_fd_pll_status : std_logic;
  signal fmc0_tdc_data_out, fmc0_tdc_data_in : std_logic_vector(27 downto 0);
  signal fmc0_tdc_data_oe : std_logic;

  signal fmc0_fd_owr_en : std_logic;
  signal fmc0_fd_owr_in : std_logic;

  signal fmc0_fd_tdc_start_predelay                    : std_logic;
  signal fmc0_tdc_start_iodelay_inc                    : std_logic;
  signal fmc0_tdc_start_iodelay_rst                    : std_logic;
  signal fmc0_tdc_start_iodelay_cal                    : std_logic;
  signal fmc0_tdc_start_iodelay_ce                     : std_logic;

  
begin  -- architecture arch

  cmp_xwb_metadata : entity work.xwb_metadata
    generic map (
      g_VENDOR_ID    => x"0000_10DC",
      g_DEVICE_ID    => x"574f_0001", -- SPEC + 1xFine Delay
      g_VERSION      => x"0300_0008",
      g_CAPABILITIES => x"0000_0000",
      g_COMMIT_ID    => sourceid_spec_fine_delay_pkg.sourceid)
    port map (
      clk_i   => clk_sys_62m5,
      rst_n_i => rst_sys_62m5_n,
      wb_i    => cnx_slave_in(c_WB_SLAVE_METADATA),
      wb_o    => cnx_slave_out(c_WB_SLAVE_METADATA));

  inst_spec_base : entity work.spec_base_wr
    generic map (
      g_WITH_VIC      => TRUE,
      g_WITH_ONEWIRE  => FALSE,
      g_WITH_SPI      => FALSE,
      g_WITH_WR       => TRUE,
      g_WITH_DDR      => FALSE,
      g_APP_OFFSET    => c_METADATA_ADDR,
      g_NUM_USER_IRQ  => 5,
      g_DPRAM_INITF   => g_WRPC_INITF,
      g_AUX_CLKS      => 1,
      g_FABRIC_IFACE  => plain,
      g_SIMULATION    => f_int2bool(g_SIMULATION))
    port map (
      clk_125m_pllref_p_i => clk_125m_pllref_p_i,
      clk_125m_pllref_n_i => clk_125m_pllref_n_i,
      clk_aux_i(0) => fmc0_dcm_clk_ref_0,
      gn_rst_n_i          => gn_rst_n_i,
      gn_p2l_clk_n_i      => gn_p2l_clk_n_i,
      gn_p2l_clk_p_i      => gn_p2l_clk_p_i,
      gn_p2l_rdy_o        => gn_p2l_rdy_o,
      gn_p2l_dframe_i     => gn_p2l_dframe_i,
      gn_p2l_valid_i      => gn_p2l_valid_i,
      gn_p2l_data_i       => gn_p2l_data_i,
      gn_p_wr_req_i       => gn_p_wr_req_i,
      gn_p_wr_rdy_o       => gn_p_wr_rdy_o,
      gn_rx_error_o       => gn_rx_error_o,
      gn_l2p_clk_n_o      => gn_l2p_clk_n_o,
      gn_l2p_clk_p_o      => gn_l2p_clk_p_o,
      gn_l2p_dframe_o     => gn_l2p_dframe_o,
      gn_l2p_valid_o      => gn_l2p_valid_o,
      gn_l2p_edb_o        => gn_l2p_edb_o,
      gn_l2p_data_o       => gn_l2p_data_o,
      gn_l2p_rdy_i        => gn_l2p_rdy_i,
      gn_l_wr_rdy_i       => gn_l_wr_rdy_i,
      gn_p_rd_d_rdy_i     => gn_p_rd_d_rdy_i,
      gn_tx_error_i       => gn_tx_error_i,
      gn_vc_rdy_i         => gn_vc_rdy_i,
      gn_gpio_b           => gn_gpio_b,
      fmc0_scl_b          => fmc0_scl_b,
      fmc0_sda_b          => fmc0_sda_b,
      fmc0_prsnt_m2c_n_i  => fmc0_prsnt_m2c_n_i,
      onewire_b           => onewire_b,
      spi_sclk_o          => spi_sclk_o,
      spi_ncs_o           => spi_ncs_o,
      spi_mosi_o          => spi_mosi_o,
      spi_miso_i          => spi_miso_i,
      pcbrev_i            => pcbrev_i,
      led_act_o           => led_act_o,
      led_link_o          => led_link_o,
      button1_n_i         => button1_n_i,
      uart_rxd_i          => uart_rxd_i,
      uart_txd_o          => uart_txd_o,
      clk_20m_vcxo_i      => clk_20m_vcxo_i,
      clk_125m_gtp_n_i    => clk_125m_gtp_n_i,
      clk_125m_gtp_p_i    => clk_125m_gtp_p_i,
      plldac_sclk_o       => plldac_sclk_o,
      plldac_din_o        => plldac_din_o,
      pll25dac_cs_n_o     => pll25dac_cs_n_o,
      pll20dac_cs_n_o     => pll20dac_cs_n_o,
      sfp_txp_o           => sfp_txp_o,
      sfp_txn_o           => sfp_txn_o,
      sfp_rxp_i           => sfp_rxp_i,
      sfp_rxn_i           => sfp_rxn_i,
      sfp_mod_def0_i      => sfp_mod_def0_i,
      sfp_mod_def1_b      => sfp_mod_def1_b,
      sfp_mod_def2_b      => sfp_mod_def2_b,
      sfp_rate_select_o   => sfp_rate_select_o,
      sfp_tx_fault_i      => sfp_tx_fault_i,
      sfp_tx_disable_o    => sfp_tx_disable_o,
      sfp_los_i           => sfp_los_i,
      clk_dmtd_125m_o     => clk_dmtd_125m,
      clk_62m5_sys_o      => clk_sys_62m5,
      rst_62m5_sys_n_o    => rst_sys_62m5_n,
      clk_125m_ref_o      => clk_ref_125m,
      rst_125m_ref_n_o    => rst_ref_125m_n,
      irq_user_i          => irq_vector,
      tm_link_up_o        => tm_link_up,
      tm_time_valid_o     => tm_time_valid,
      tm_tai_o            => tm_tai,
      tm_cycles_o         => tm_cycles,
      tm_clk_aux_lock_en_i => tm_clk_aux_lock_en,
      tm_clk_aux_locked_o => tm_clk_aux_locked,
      
      tm_dac_value_o       => tm_dac_value,
      tm_dac_wr_o          => tm_dac_wr,

      pps_p_o             => open,
      pps_led_o           => pps_led,
      link_ok_o           => wrabbit_en,
      app_wb_o            => cnx_master_out(c_WB_MASTER_GENNUM),
      app_wb_i            => cnx_master_in(c_WB_MASTER_GENNUM));

  ------------------------------------------------------------------------------
  -- Primary wishbone crossbar
  ------------------------------------------------------------------------------

  cmp_crossbar : xwb_crossbar
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

  ------------------------------------------------------------------------------
  -- FMC Fine Delay mezzanine
  ------------------------------------------------------------------------------

  cmp0_tm_time_valid_sync : gc_sync_ffs
    port map (
      clk_i    => clk_ref_125m,
      rst_n_i  => '1',
      data_i   => tm_time_valid,
      synced_o => tm_time_valid_sync);

  cmp0_fmc_irq_sync : gc_sync_ffs
    port map (
      clk_i    => clk_sys_62m5,
      rst_n_i  => '1',
      data_i   => fmc0_irq,
      synced_o => irq_vector(0));

  cmp0_fd_tdc_start : IBUFDS
    generic map (
      DIFF_TERM    => true,
      IBUF_LOW_PWR => false  -- Low power (TRUE) vs. performance (FALSE) setting for referenced
      )
    port map (
      O  => fmc0_fd_tdc_start_predelay,               -- Buffer output
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
      IDATAIN => fmc0_fd_tdc_start_predelay,
      DATAOUT2 => fmc0_fd_tdc_start,
      INC => fmc0_tdc_start_iodelay_inc,
      CE =>  fmc0_tdc_start_iodelay_ce,
      RST =>  fmc0_tdc_start_iodelay_rst,
      CLK => fmc0_dcm_clk_ref_0,
      BUSY => open,
      ODATAIN => '0',
      CAL => fmc0_tdc_start_iodelay_cal,
      T => '1',
      IOCLK0 => fmc0_dcm_clk_ref_0,
      IOCLK1 => '0'
      );

  cmp0_fd_ddr_pll : entity work.fd_ddr_pll
    port map (
      RST       => fmc0_ddr_pll_reset,
      LOCKED    => fmc0_ddr_pll_locked,
      CLK_IN1_P => fmc0_fd_clk_ref_p_i,
      CLK_IN1_N => fmc0_fd_clk_ref_n_i,
      CLK_OUT1  => fmc0_dcm_clk_ref_0,
      CLK_OUT2  => fmc0_dcm_clk_ref_180);

  fmc0_ddr_pll_reset <= not fmc0_fd_pll_status_i; 
  fmc0_fd_pll_status <= fmc0_fd_pll_status_i and fmc0_ddr_pll_locked;
  
  cmp0_fmc_fdelay_mezzanine : entity work.fine_delay_core
    generic map (
      g_with_wr_core        => true,
      g_simulation          => f_int2bool(g_simulation),
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_fmc_slot_id         => 0)
    port map (
      clk_sys_i     => clk_sys_62m5,
      rst_n_i       => rst_sys_62m5_n,

      clk_ref_0_i   => fmc0_dcm_clk_ref_0,
      clk_ref_180_i => fmc0_dcm_clk_ref_180,
      clk_dmtd_i    => clk_dmtd_125m,

      dcm_reset_o   => open,
      dcm_locked_i  => fmc0_ddr_pll_locked,

      idelay_cal_o => fmc0_tdc_start_iodelay_cal,
      idelay_rst_o => fmc0_tdc_start_iodelay_rst,
      idelay_ce_o => fmc0_tdc_start_iodelay_ce,
      idelay_inc_o => fmc0_tdc_start_iodelay_inc,
      
      trig_a_i          => fmc0_fd_trig_a_i,
      tdc_cal_pulse_o   => fmc0_fd_tdc_cal_pulse_o,
      tdc_start_i       => fmc0_fd_tdc_start,
      dmtd_fb_in_i      => fmc0_fd_dmtd_fb_in_i,
      dmtd_fb_out_i     => fmc0_fd_dmtd_fb_out_i,
      dmtd_samp_o       => fmc0_fd_dmtd_clk_o,
      led_trig_o        => fmc0_fd_led_trig_o,
      ext_rst_n_o       => fmc0_fd_ext_rst_n_o,
      pll_status_i      => fmc0_fd_pll_status,
      acam_d_o          => fmc0_tdc_data_out,
      acam_d_i          => fmc0_tdc_data_in,
      acam_d_oen_o      => fmc0_tdc_data_oe,
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
      tm_utc_i             => tm_tai, -- fixme - it's really TAI, not utc. Fix
                                      -- in the FD core
      tm_clk_aux_lock_en_o => tm_clk_aux_lock_en(0),
      tm_clk_aux_locked_i  => tm_clk_aux_locked(0),
      tm_clk_dmtd_locked_i => '1',  --    FIXME: fan out real signal from the
      --    WRCore
      tm_dac_value_i       => tm_dac_value,
      tm_dac_wr_i          => tm_dac_wr(0),

      owr_en_o        => fmc0_fd_owr_en,
      owr_i           => fmc0_fd_owr_in,

      -- i2c now from spec template
      i2c_scl_oen_o   => open,
      i2c_scl_i       => '1',
      i2c_sda_oen_o   => open,
      i2c_sda_i       => '1',

      fmc_present_n_i => fmc0_prsnt_m2c_n_i,
      
      wb_adr_i   => cnx_slave_in(c_WB_SLAVE_FMC_DELAY).adr,
      wb_dat_i   => cnx_slave_in(c_WB_SLAVE_FMC_DELAY).dat,
      wb_dat_o   => cnx_slave_out(c_WB_SLAVE_FMC_DELAY).dat,
      wb_sel_i   => cnx_slave_in(c_WB_SLAVE_FMC_DELAY).sel,
      wb_cyc_i   => cnx_slave_in(c_WB_SLAVE_FMC_DELAY).cyc,
      wb_stb_i   => cnx_slave_in(c_WB_SLAVE_FMC_DELAY).stb,
      wb_we_i    => cnx_slave_in(c_WB_SLAVE_FMC_DELAY).we,
      wb_ack_o   => cnx_slave_out(c_WB_SLAVE_FMC_DELAY).ack,
      wb_stall_o => cnx_slave_out(c_WB_SLAVE_FMC_DELAY).stall,
      wb_irq_o => fmc0_irq
      );

  cnx_slave_out(c_WB_SLAVE_FMC_DELAY).rty <= '0';
  cnx_slave_out(c_WB_SLAVE_FMC_DELAY).err <= '0';


  
  fmc0_fd_tdc_d_b    <= fmc0_tdc_data_out when fmc0_tdc_data_oe = '1' else (others => 'Z');
  fmc0_fd_tdc_oe_n_o <= '1';
  fmc0_tdc_data_in   <= fmc0_fd_tdc_d_b;

  fmc0_fd_onewire_b <= '0' when fmc0_fd_owr_en = '1' else 'Z';
  fmc0_fd_owr_in    <= fmc0_fd_onewire_b;


  ------------------------------------------------------------------------------
  -- Carrier LEDs
  ------------------------------------------------------------------------------

  cmp_pci_access_led : gc_extend_pulse
    generic map (
      g_width => 2500000)
    port map (
      clk_i      => clk_sys_62m5,
      rst_n_i    => rst_sys_62m5_n,
      pulse_i    => cnx_slave_in(c_WB_MASTER_GENNUM).cyc,
      extended_o => gn4124_access);

  aux_leds_o(0) <= not gn4124_access;
  aux_leds_o(1) <= '1';
  aux_leds_o(2) <= not tm_time_valid;
  aux_leds_o(3) <= not pps_led;

end architecture arch;
