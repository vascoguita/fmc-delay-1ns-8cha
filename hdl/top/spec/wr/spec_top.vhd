
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.gn4124_core_pkg.all;
use work.gencores_pkg.all;
use work.wrcore_pkg.all;
use work.wbconmax_pkg.all;
use work.wr_fabric_pkg.all;
use work.wishbone_pkg.all;



library UNISIM;
use UNISIM.vcomponents.all;


entity spec_top is
  generic
    (
      g_standalone : boolean := true;
      g_debugging: boolean := false
      );
  port
    (
      -- Global ports
      clk_20m_vcxo_i : in std_logic;    -- 20MHz VCXO clock

      clk_125m_pllref_p_i : in std_logic;  -- 125 MHz PLL reference
      clk_125m_pllref_n_i : in std_logic;


      -- Font panel LEDs
      LED_RED   : out std_logic;
      LED_GREEN : out std_logic;

      dac_sclk_o  : out std_logic;
      dac_din_o   : out std_logic;
      dac_cs1_n_o : out std_logic;
      dac_cs2_n_o : out std_logic;


      button1_i : in std_logic:='1';
      button2_i : in std_logic:='1';
      -------------------------------------------------------------------------
      -- SFP pins
      -------------------------------------------------------------------------

--      wr_ref_clk_p_i: in std_logic;
--      wr_ref_clk_n_i: in std_logic;

      dbg_tbi_td_o: out std_logic_vector(9 downto 0);
      dbg_tbi_rd_i: in std_logic_vector(9 downto 0) := "0000000000";

      sfp_txp_o : out std_logic;
      sfp_txn_o : out std_logic;

      sfp_rxp_i : in std_logic:='0';
      sfp_rxn_i : in std_logic:='1';

      sfp_mod_def0_b    : inout std_logic;  -- rate_select
      sfp_mod_def1_b    : inout std_logic;  -- scl
      sfp_mod_def2_b    : inout std_logic;  -- sda
      sfp_rate_select_b : inout std_logic;
      sfp_tx_fault_i    : in    std_logic := '0';
      sfp_tx_disable_o  : out   std_logic;
      sfp_los_i         : in    std_logic := '0';

      -------------------------------------------------------------------------
      -- Fine Delay Pins
      -------------------------------------------------------------------------

      fd_tdc_start_p_i : in std_logic := '0';
      fd_tdc_start_n_i : in std_logic := '1';

      fd_clk_ref_p_i : in std_logic := '0';
      fd_clk_ref_n_i : in std_logic := '1';

      fd_trig_a_i         : in    std_logic := '1';
      fd_trig_cal_o       : out   std_logic;
      fd_tdc_d_b          : inout std_logic_vector(27 downto 0);
      fd_tdc_a_o          : out   std_logic_vector(3 downto 0);
      fd_tdc_emptyf_i     : in    std_logic := '1';
      fd_tdc_alutrigger_o : out   std_logic;
      fd_tdc_cs_n_o       : out   std_logic;
      fd_tdc_wr_n_o       : out   std_logic;
      fd_tdc_rd_n_o       : out   std_logic;
      fd_tdc_oe_n_o       : out   std_logic;
      fd_led_trig_o       : out   std_logic;
      fd_tdc_start_dis_o  : out   std_logic;
      fd_tdc_stop_dis_o   : out   std_logic;
      fd_spi_cs_dac_n_o   : out   std_logic;
      fd_spi_cs_pll_n_o   : out   std_logic;
      fd_spi_cs_gpio_n_o  : out   std_logic;
      fd_spi_sclk_o       : out   std_logic;
      fd_spi_mosi_o       : out   std_logic;
      fd_spi_miso_i       : in    std_logic := '1';
      fd_delay_len_o      : out   std_logic_vector(3 downto 0);
      fd_delay_val_o      : out   std_logic_vector(9 downto 0);
      fd_delay_pulse_o    : out   std_logic_vector(3 downto 0);


      fmc_scl_b : inout std_logic;
      fmc_sda_b : inout std_logic;
      onewire_b : inout std_logic;

      -----------------------------------------
      --UART
      -----------------------------------------
      uart_rxd_i : in  std_logic:='1';
      uart_txd_o : out std_logic
      );

end spec_top;



architecture rtl of spec_top is

  component wr_tbi_phy
    port (
      serdes_rst_i          : in  std_logic;
      serdes_loopen_i       : in  std_logic;
      serdes_prbsen_i       : in  std_logic;
      serdes_enable_i       : in  std_logic;
      serdes_syncen_i       : in  std_logic;
      serdes_tx_data_i      : in  std_logic_vector(7 downto 0);
      serdes_tx_k_i         : in  std_logic;
      serdes_tx_disparity_o : out std_logic;
      serdes_tx_enc_err_o   : out std_logic;
      serdes_rx_data_o      : out std_logic_vector(7 downto 0);
      serdes_rx_k_o         : out std_logic;
      serdes_rx_enc_err_o   : out std_logic;
      serdes_rx_bitslide_o  : out std_logic_vector(3 downto 0);
      tbi_refclk_i          : in  std_logic;
      tbi_rbclk_i           : in  std_logic;
      tbi_td_o              : out std_logic_vector(9 downto 0);
      tbi_rd_i              : in  std_logic_vector(9 downto 0);
      tbi_syncen_o          : out std_logic;
      tbi_loopen_o          : out std_logic;
      tbi_prbsen_o          : out std_logic;
      tbi_enable_o          : out std_logic);
  end component;
  
  component fine_delay_core
    port (
      clk_ref_i            : in  std_logic;
      clk_sys_i            : in  std_logic;
      rst_n_i              : in  std_logic;
      trig_a_n_i           : in  std_logic;
      trig_cal_o           : out std_logic;
      tdc_start_i          : in  std_logic;
      acam_a_o             : out std_logic_vector(3 downto 0);
      acam_d_o             : out std_logic_vector(27 downto 0);
      acam_d_i             : in  std_logic_vector(27 downto 0);
      acam_d_oen_o         : out std_logic;
      acam_err_i           : in  std_logic;
      acam_int_i           : in  std_logic;
      acam_emptyf_i        : in  std_logic;
      acam_alutrigger_o    : out std_logic;
      acam_cs_n_o          : out std_logic;
      acam_wr_n_o          : out std_logic;
      acam_rd_n_o          : out std_logic;
      acam_start_dis_o     : out std_logic;
      acam_stop_dis_o      : out std_logic;
      led_trig_o           : out std_logic;
      spi_cs_dac_n_o       : out std_logic;
      spi_cs_pll_n_o       : out std_logic;
      spi_cs_gpio_n_o      : out std_logic;
      spi_sclk_o           : out std_logic;
      spi_mosi_o           : out std_logic;
      spi_miso_i           : in  std_logic;
      delay_len_o          : out std_logic_vector(3 downto 0);
      delay_val_o          : out std_logic_vector(9 downto 0);
      delay_pulse_o        : out std_logic_vector(3 downto 0);
      owr_en_o             : out std_logic;
      owr_i                : in  std_logic;
      tm_time_valid_i      : in  std_logic                     := '0';
      tm_cycles_i          : in  std_logic_vector(27 downto 0) := x"0000000";
      tm_utc_i             : in  std_logic_vector(39 downto 0) := x"0000000000";
      tm_clk_aux_lock_en_o : out std_logic;
      tm_clk_aux_locked_i  : in  std_logic                     := '0';
      tm_dac_value_i       : in  std_logic_vector(23 downto 0) := x"000000";
      tm_dac_wr_i          : in  std_logic                     := '0';
      i2c_scl_o            : out std_logic;
      i2c_scl_oen_o        : out std_logic;
      i2c_scl_i            : in  std_logic;
      i2c_sda_o            : out std_logic;
      i2c_sda_oen_o        : out std_logic;
      i2c_sda_i            : in  std_logic;
      wb_adr_i             : in  std_logic_vector(7 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_dat_o             : out std_logic_vector(31 downto 0);
      wb_cyc_i             : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_we_i              : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_irq_o             : out std_logic);
  end component;

  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------

  component gn4124_core
    generic(
      -- g_IS_SPARTAN6       : boolean := false;  -- This generic is used to instanciate spartan6 specific primitives
      g_BAR0_APERTURE     : integer := 20;  -- BAR0 aperture, defined in GN4124 PCI_BAR_CONFIG register (0x80C)
                                            -- => number of bits to address periph on the board
      g_CSR_WB_SLAVES_NB  : integer := 1;   -- Number of CSR wishbone slaves
      g_DMA_WB_SLAVES_NB  : integer := 1;   -- Number of DMA wishbone slaves
      g_DMA_WB_ADDR_WIDTH : integer := 26;  -- DMA wishbone address bus width;
      g_CSR_WB_MODE       : string  := "classic"
      );
    port
      (
        ---------------------------------------------------------
        -- Control and status
        --
        -- Asynchronous reset from GN4124
        rst_n_a_i      : in  std_logic;
        -- P2L clock PLL locked
        p2l_pll_locked : out std_logic;
        -- Debug ouputs
        debug_o        : out std_logic_vector(7 downto 0);

        ---------------------------------------------------------
        -- P2L Direction
        --
        -- Source Sync DDR related signals
        p2l_clk_p_i  : in  std_logic;   -- Receiver Source Synchronous Clock+
        p2l_clk_n_i  : in  std_logic;   -- Receiver Source Synchronous Clock-
        p2l_data_i   : in  std_logic_vector(15 downto 0);  -- Parallel receive data
        p2l_dframe_i : in  std_logic;   -- Receive Frame
        p2l_valid_i  : in  std_logic;   -- Receive Data Valid
        -- P2L Control
        p2l_rdy_o    : out std_logic;   -- Rx Buffer Full Flag
        p_wr_req_i   : in  std_logic_vector(1 downto 0);  -- PCIe Write Request
        p_wr_rdy_o   : out std_logic_vector(1 downto 0);  -- PCIe Write Ready
        rx_error_o   : out std_logic;   -- Receive Error

        ---------------------------------------------------------
        -- L2P Direction
        --
        -- Source Sync DDR related signals
        l2p_clk_p_o  : out std_logic;  -- Transmitter Source Synchronous Clock+
        l2p_clk_n_o  : out std_logic;  -- Transmitter Source Synchronous Clock-
        l2p_data_o   : out std_logic_vector(15 downto 0);  -- Parallel transmit data
        l2p_dframe_o : out std_logic;   -- Transmit Data Frame
        l2p_valid_o  : out std_logic;   -- Transmit Data Valid
        l2p_edb_o    : out std_logic;   -- Packet termination and discard
        -- L2P Control
        l2p_rdy_i    : in  std_logic;   -- Tx Buffer Full Flag
        l_wr_rdy_i   : in  std_logic_vector(1 downto 0);  -- Local-to-PCIe Write
        p_rd_d_rdy_i : in  std_logic_vector(1 downto 0);  -- PCIe-to-Local Read Response Data Ready
        tx_error_i   : in  std_logic;   -- Transmit Error
        vc_rdy_i     : in  std_logic_vector(1 downto 0);  -- Channel ready

        ---------------------------------------------------------
        -- Interrupt interface
        dma_irq_o : out std_logic_vector(1 downto 0);  -- Interrupts sources to IRQ manager
        irq_p_i   : in  std_logic;  -- Interrupt request pulse from IRQ manager
        irq_p_o   : out std_logic;  -- Interrupt request pulse to GN4124 GPIO

        ---------------------------------------------------------
        -- Target interface (CSR wishbone master)
        wb_clk_i : in  std_logic;
        wb_adr_o : out std_logic_vector(g_BAR0_APERTURE-priv_log2_ceil(g_CSR_WB_SLAVES_NB+1)-1 downto 0);
        wb_dat_o : out std_logic_vector(31 downto 0);  -- Data out
        wb_sel_o : out std_logic_vector(3 downto 0);   -- Byte select
        wb_stb_o : out std_logic;
        wb_we_o  : out std_logic;
        wb_cyc_o : out std_logic_vector(g_CSR_WB_SLAVES_NB-1 downto 0);
        wb_dat_i : in  std_logic_vector((32*g_CSR_WB_SLAVES_NB)-1 downto 0);  -- Data in
        wb_ack_i : in  std_logic_vector(g_CSR_WB_SLAVES_NB-1 downto 0);

        ---------------------------------------------------------
        -- DMA interface (Pipelined wishbone master)
        dma_clk_i   : in  std_logic;
        dma_adr_o   : out std_logic_vector(31 downto 0);
        dma_dat_o   : out std_logic_vector(31 downto 0);  -- Data out
        dma_sel_o   : out std_logic_vector(3 downto 0);   -- Byte select
        dma_stb_o   : out std_logic;
        dma_we_o    : out std_logic;
        dma_cyc_o   : out std_logic;  --_vector(g_DMA_WB_SLAVES_NB-1 downto 0);
        dma_dat_i   : in  std_logic_vector((32*g_DMA_WB_SLAVES_NB)-1 downto 0);  -- Data in
        dma_ack_i   : in  std_logic;  --_vector(g_DMA_WB_SLAVES_NB-1 downto 0);
        dma_stall_i : in  std_logic--_vector(g_DMA_WB_SLAVES_NB-1 downto 0)        -- for pipelined Wishbone
        );
  end component;  --  gn4124_core

  component BUFG
    port (
      O : out std_ulogic;
      I : in  std_ulogic);
  end component;

  component BUFIO2
    generic (
      DIVIDE_BYPASS : boolean := true;
      DIVIDE        : integer := 1;
      I_INVERT      : boolean := false;
      USE_DOUBLER   : boolean := false);
    port (
      DIVCLK       : out std_ulogic;
      IOCLK        : out std_ulogic;
      SERDESSTROBE : out std_ulogic;
      I            : in  std_ulogic);
  end component;

  component wr_core
    generic (
      g_simulation         : integer;
      g_virtual_uart       : natural;
      g_ep_rxbuf_size_log2 : integer;
      g_dpram_initf        : string;
      g_dpram_size         : integer;
      g_num_gpio           : integer);
    port (
      clk_sys_i          : in  std_logic;
      clk_dmtd_i         : in  std_logic;
      clk_ref_i          : in  std_logic;
      clk_aux_i          : in  std_logic := '0';
      rst_n_i           : in  std_logic;
      pps_p_o            : out std_logic;
      dac_hpll_load_p1_o : out std_logic;
      dac_hpll_data_o    : out std_logic_vector(15 downto 0);
      dac_dpll_load_p1_o : out std_logic;
      dac_dpll_data_o    : out std_logic_vector(15 downto 0);
      phy_ref_clk_i      : in  std_logic;
      phy_tx_data_o      : out std_logic_vector(7 downto 0);
      phy_tx_k_o         : out std_logic;
      phy_tx_disparity_i : in  std_logic;
      phy_tx_enc_err_i   : in  std_logic;
      phy_rx_data_i      : in  std_logic_vector(7 downto 0);
      phy_rx_rbclk_i     : in  std_logic;
      phy_rx_k_i         : in  std_logic;
      phy_rx_enc_err_i   : in  std_logic;
      phy_rx_bitslide_i  : in  std_logic_vector(3 downto 0);
      phy_rst_o          : out std_logic;
      phy_loopen_o       : out std_logic;
      gpio_o             : out std_logic_vector(g_num_gpio-1 downto 0);
      gpio_i             : in  std_logic_vector(g_num_gpio-1 downto 0);
      gpio_dir_o         : out std_logic_vector(g_num_gpio-1 downto 0);
      uart_rxd_i         : in  std_logic;
      uart_txd_o         : out std_logic;
      wb_addr_i          : in  std_logic_vector(c_aw-1 downto 0);
      wb_data_i          : in  std_logic_vector(c_dw-1 downto 0);
      wb_data_o          : out std_logic_vector(c_dw-1 downto 0);
      wb_sel_i           : in  std_logic_vector(c_sw-1 downto 0);
      wb_we_i            : in  std_logic;
      wb_cyc_i           : in  std_logic;
      wb_stb_i           : in  std_logic;
      wb_ack_o           : out std_logic;

      ext_snk_adr_i   : in  std_logic_vector(1 downto 0)  := "00";
      ext_snk_dat_i   : in  std_logic_vector(15 downto 0) := x"0000";
      ext_snk_sel_i   : in  std_logic_vector(1 downto 0)  := "00";
      ext_snk_cyc_i   : in  std_logic                     := '0';
      ext_snk_we_i    : in  std_logic                     := '0';
      ext_snk_stb_i   : in  std_logic                     := '0';
      ext_snk_ack_o   : out std_logic;
      ext_snk_err_o   : out std_logic;
      ext_snk_stall_o : out std_logic;


      ext_src_adr_o   : out std_logic_vector(1 downto 0);
      ext_src_dat_o   : out std_logic_vector(15 downto 0);
      ext_src_sel_o   : out std_logic_vector(1 downto 0);
      ext_src_cyc_o   : out std_logic;
      ext_src_stb_o   : out std_logic;
      ext_src_we_o    : out std_logic;
      ext_src_ack_i   : in  std_logic := '1';
      ext_src_err_i   : in  std_logic := '0';
      ext_src_stall_i : in  std_logic := '0';

      -- DAC Control
      tm_dac_value_o : out std_logic_vector(23 downto 0);
      tm_dac_wr_o    : out std_logic;

      -- Aux clock lock enable
      tm_clk_aux_lock_en_i : in std_logic := '0';

      -- Aux clock locked flag
      tm_clk_aux_locked_o : out std_logic;

      -- Timecode output
      tm_time_valid_o : out std_logic;
      tm_utc_o        : out std_logic_vector(39 downto 0);
      tm_cycles_o     : out std_logic_vector(27 downto 0);

      rst_aux_n_o : out std_logic;
      dio_o       : out std_logic_vector(3 downto 0));
  end component;

  component wr_gtp_phy_spartan6
    generic (
      g_simulation         : integer;
      g_ch0_use_refclk_out : boolean := false;
      g_ch1_use_refclk_out : boolean := false;
      g_ch0_refclk_input   : integer := 0;
      g_ch1_refclk_input   : integer := 0
      );
    port (
      ch0_ref_clk_i      : in  std_logic;
      ch0_ref_clk_o      : out std_logic;
      ch0_tx_data_i      : in  std_logic_vector(7 downto 0);
      ch0_tx_k_i         : in  std_logic;
      ch0_tx_disparity_o : out std_logic;
      ch0_tx_enc_err_o   : out std_logic;
      ch0_rx_rbclk_o     : out std_logic;
      ch0_rx_data_o      : out std_logic_vector(7 downto 0);
      ch0_rx_k_o         : out std_logic;
      ch0_rx_enc_err_o   : out std_logic;
      ch0_rx_bitslide_o  : out std_logic_vector(3 downto 0);
      ch0_rst_i          : in  std_logic;
      ch0_loopen_i       : in  std_logic;
      ch1_ref_clk_i      : in  std_logic;
      ch1_ref_clk_o      : out std_logic;
      ch1_tx_data_i      : in  std_logic_vector(7 downto 0) := "00000000";
      ch1_tx_k_i         : in  std_logic                    := '0';
      ch1_tx_disparity_o : out std_logic;
      ch1_tx_enc_err_o   : out std_logic;
      ch1_rx_data_o      : out std_logic_vector(7 downto 0);
      ch1_rx_rbclk_o     : out std_logic;
      ch1_rx_k_o         : out std_logic;
      ch1_rx_enc_err_o   : out std_logic;
      ch1_rx_bitslide_o  : out std_logic_vector(3 downto 0);
      ch1_rst_i          : in  std_logic                    := '0';
      ch1_loopen_i       : in  std_logic                    := '0';
      pad_txn0_o         : out std_logic;
      pad_txp0_o         : out std_logic;
      pad_rxn0_i         : in  std_logic                    := '0';
      pad_rxp0_i         : in  std_logic                    := '0';
      pad_txn1_o         : out std_logic;
      pad_txp1_o         : out std_logic;
      pad_rxn1_i         : in  std_logic                    := '0';
      pad_rxp1_i         : in  std_logic                    := '0');
  end component;

  component spec_serial_dac_arb
    generic(
      g_invert_sclk    : boolean;
      g_num_extra_bits : integer);        
    port (
      clk_i       : in  std_logic;
      rst_n_i     : in  std_logic;
      val1_i      : in  std_logic_vector(15 downto 0);
      load1_i     : in  std_logic;
      val2_i      : in  std_logic_vector(15 downto 0);
      load2_i     : in  std_logic;
      dac_cs_n_o  : out std_logic_vector(1 downto 0);
      dac_clr_n_o : out std_logic;
      dac_sclk_o  : out std_logic;
      dac_din_o   : out std_logic);
  end component;

  component chipscope_ila
    port (
      CONTROL : inout std_logic_vector(35 downto 0);
      CLK     : in    std_logic;
      TRIG0   : in    std_logic_vector(31 downto 0);
      TRIG1   : in    std_logic_vector(31 downto 0);
      TRIG2   : in    std_logic_vector(31 downto 0);
      TRIG3   : in    std_logic_vector(31 downto 0));
  end component;

  signal CONTROL : std_logic_vector(35 downto 0);
  signal CLK     : std_logic;
  signal TRIG0   : std_logic_vector(31 downto 0);
  signal TRIG1   : std_logic_vector(31 downto 0);
  signal TRIG2   : std_logic_vector(31 downto 0);
  signal TRIG3   : std_logic_vector(31 downto 0);
  signal s_TRIG0   : std_logic_vector(31 downto 0);
  signal s_TRIG1   : std_logic_vector(31 downto 0);
  signal s_TRIG2   : std_logic_vector(31 downto 0);
  signal s_TRIG3   : std_logic_vector(31 downto 0);

  component chipscope_icon
    port (
      CONTROL0 : inout std_logic_vector (35 downto 0));
  end component;

  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  constant c_BAR0_APERTURE     : integer := 20;
  constant c_CSR_WB_SLAVES_NB  : integer := 1;
  constant c_DMA_WB_SLAVES_NB  : integer := 1;
  constant c_DMA_WB_ADDR_WIDTH : integer := 26;

  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------

  -- LCLK from GN4124 used as system clock
  signal l_clk : std_logic;

  -- P2L colck PLL status
  signal p2l_pll_locked : std_logic;

  -- Reset
  signal rst_a : std_logic;
  signal rst   : std_logic;

  -- CSR wishbone bus
  signal wb_adr     : std_logic_vector(c_BAR0_APERTURE-priv_log2_ceil(c_CSR_WB_SLAVES_NB+1)-1 downto 0);
  signal wb_dat_i   : std_logic_vector((32*c_CSR_WB_SLAVES_NB)-1 downto 0);
  signal wb_dat_o   : std_logic_vector(31 downto 0);
  signal wb_sel     : std_logic_vector(3 downto 0);
  signal wb_cyc     : std_logic_vector(c_CSR_WB_SLAVES_NB-1 downto 0);
  signal wb_stb     : std_logic;
  signal wb_we      : std_logic;
  signal wb_ack     : std_logic_vector(c_CSR_WB_SLAVES_NB-1 downto 0);
  signal spi_wb_adr : std_logic_vector(4 downto 0);

  -- DMA wishbone bus
  signal dma_adr     : std_logic_vector(31 downto 0);
  signal dma_dat_i   : std_logic_vector((32*c_DMA_WB_SLAVES_NB)-1 downto 0);
  signal dma_dat_o   : std_logic_vector(31 downto 0);
  signal dma_sel     : std_logic_vector(3 downto 0);
  signal dma_cyc     : std_logic;  --_vector(c_DMA_WB_SLAVES_NB-1 downto 0);
  signal dma_stb     : std_logic;
  signal dma_we      : std_logic;
  signal dma_ack     : std_logic;  --_vector(c_DMA_WB_SLAVES_NB-1 downto 0);
  signal dma_stall   : std_logic;  --_vector(c_DMA_WB_SLAVES_NB-1 downto 0);
  signal ram_we      : std_logic_vector(0 downto 0);
  signal ddr_dma_adr : std_logic_vector(29 downto 0);

  signal irq_to_gn4124 : std_logic;

  -- SPI
  signal spi_slave_select : std_logic_vector(7 downto 0);


  signal pllout_clk_sys       : std_logic;
  signal pllout_clk_dmtd      : std_logic;
  signal pllout_clk_fb_pllref : std_logic;
  signal pllout_clk_fb_dmtd   : std_logic;

  signal clk_20m_vcxo_buf : std_logic;
  signal clk_125m_pllref  : std_logic;
  signal clk_sys          : std_logic;
  signal clk_dmtd         : std_logic;
  signal dac_rst_n        : std_logic;
  signal led_divider      : unsigned(23 downto 0);

  signal wrc_gpio_out : std_logic_vector(7 downto 0);
  signal wrc_gpio_in  : std_logic_vector(7 downto 0);
  signal wrc_gpio_dir : std_logic_vector(7 downto 0);
  signal wb_adr_wrc   : std_logic_vector(17 downto 0);
  signal dio          : std_logic_vector(3 downto 0);

  signal dac_hpll_load_p1 : std_logic;
  signal dac_dpll_load_p1 : std_logic;
  signal dac_hpll_data    : std_logic_vector(15 downto 0);
  signal dac_dpll_data    : std_logic_vector(15 downto 0);

  signal pps : std_logic;

  signal phy_tx_data      : std_logic_vector(7 downto 0);
  signal phy_tx_k         : std_logic;
  signal phy_tx_disparity : std_logic;
  signal phy_tx_enc_err   : std_logic;
  signal phy_rx_data      : std_logic_vector(7 downto 0);
  signal phy_rx_rbclk     : std_logic;
  signal phy_rx_k         : std_logic;
  signal phy_rx_enc_err   : std_logic;
  signal phy_rx_bitslide  : std_logic_vector(3 downto 0);
  signal phy_rst          : std_logic;
  signal phy_loopen       : std_logic;

  signal dio_in  : std_logic_vector(4 downto 0);
  signal dio_out : std_logic_vector(4 downto 0);
  signal dio_clk : std_logic;

  signal local_reset_n  : std_logic;
  signal mbone_rst_n    : std_logic;
  signal button1_synced : std_logic_vector(2 downto 0);

  signal mbone_src_out : t_wrf_source_out;
  signal mbone_src_in  : t_wrf_source_in;
  signal mbone_snk_out : t_wrf_sink_out;
  signal mbone_snk_in  : t_wrf_sink_in;


  component xmini_bone
    generic (
      g_class_mask    : std_logic_vector(7 downto 0);
      g_our_ethertype : std_logic_vector(15 downto 0));
    port (
      clk_sys_i : in  std_logic;
      rst_n_i   : in  std_logic;
      src_o     : out t_wrf_source_out;
      src_i     : in  t_wrf_source_in;
      snk_o     : out t_wrf_sink_out;
      snk_i     : in  t_wrf_sink_in;
      master_o  : out t_wishbone_master_out;
      master_i  : in  t_wishbone_master_in);
  end component;

  signal mbone_wb_out    : t_wishbone_master_out;
  signal mbone_wb_in     : t_wishbone_master_in;
  signal host_wb_out     : t_wishbone_master_out;
  signal host_wb_in      : t_wishbone_master_in;
  signal dpram_slave2_in : t_wishbone_master_out;

  signal powerup_reset_reg : std_logic_vector(15 downto 0) := x"ffff";

  signal cnx_out : t_wishbone_master_out_array(0 to 1);
  signal cnx_in  : t_wishbone_master_in_array(0 to 1);

  signal cnx_slave_in  : t_wishbone_slave_in;
  signal cnx_slave_out : t_wishbone_slave_out;

  signal fd_clk_ref                : std_logic;
  signal fd_tdc_start              : std_logic;
  signal onewire_en                : std_logic;
  signal scl_pad_out               : std_logic;
  signal scl_pad_in                : std_logic;
  signal scl_pad_oen               : std_logic;
  signal sda_pad_out               : std_logic;
  signal sda_pad_in                : std_logic;
  signal sda_pad_oen               : std_logic;
  signal tdc_data_out, tdc_data_in : std_logic_vector(27 downto 0);
  signal tdc_data_oe               : std_logic;


  signal tm_utc             : std_logic_vector(39 downto 0);
  signal tm_cycles          : std_logic_vector(27 downto 0);
  signal tm_time_valid      : std_logic;
  signal tm_clk_aux_lock_en : std_logic;
  signal tm_clk_aux_locked  : std_logic;
  signal tm_dac_value       : std_logic_vector(23 downto 0);
  signal tm_dac_wr          : std_logic;

  signal wr_ref_clk_phyin  : std_logic;
  signal wr_ref_clk_phyout : std_logic;

  signal fd_clk_ref_pin     : std_logic;
  signal fd_clk_ref_bufio_q : std_logic;

  signal dna_din : std_logic;
  signal dna_dout : std_logic;
  signal dna_clk : std_logic;
  signal dna_shift : std_logic;
  signal dna_read : std_logic;
  
   
    
  
begin


  cmp_sys_clk_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 8,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 16,         -- 62.5 MHz
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKOUT1_DIVIDE     => 16,         -- 125 MHz
      CLKOUT1_PHASE      => 0.000,
      CLKOUT1_DUTY_CYCLE => 0.500,
      CLKOUT2_DIVIDE     => 16,
      CLKOUT2_PHASE      => 0.000,
      CLKOUT2_DUTY_CYCLE => 0.500,
      CLKIN_PERIOD       => 8.0,
      REF_JITTER         => 0.016)
    port map (
      CLKFBOUT => pllout_clk_fb_pllref,
      CLKOUT0  => pllout_clk_sys,
      CLKOUT1  => open,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => open,
      RST      => '0',
      CLKFBIN  => pllout_clk_fb_pllref,
      CLKIN    => clk_125m_pllref);

  cmp_dmtd_clk_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 50,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 8,          -- 62.5 MHz
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKOUT1_DIVIDE     => 16,         -- 125 MHz
      CLKOUT1_PHASE      => 0.000,
      CLKOUT1_DUTY_CYCLE => 0.500,
      CLKOUT2_DIVIDE     => 8,
      CLKOUT2_PHASE      => 0.000,
      CLKOUT2_DUTY_CYCLE => 0.500,
      CLKIN_PERIOD       => 50.0,
      REF_JITTER         => 0.016)
    port map (
      CLKFBOUT => pllout_clk_fb_dmtd,
      CLKOUT0  => pllout_clk_dmtd,
      CLKOUT1  => open, --pllout_clk_sys,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => open,
      RST      => '0',
      CLKFBIN  => pllout_clk_fb_dmtd,
      CLKIN    => clk_20m_vcxo_buf);


  gen_standalone1 : if(g_standalone) generate
    
    p_gen_reset : process(clk_sys)
    begin
      if rising_edge(clk_sys) then
        button1_synced(0) <= button1_i;
        button1_synced(1) <= button1_synced(0);
        button1_synced(2) <= button1_synced(1);
        if(powerup_reset_reg(15) /= '0')then
          local_reset_n <= '0';
        elsif (button1_synced(2) = '0') then
          local_reset_n <= '0';
        else
          local_reset_n <= '1';
        end if;

        powerup_reset_reg <= powerup_reset_reg(14 downto 0) & '0';
      end if;
    end process;
  end generate gen_standalone1;




  cmp_clk_sys_buf : BUFG
    port map (
      O => clk_sys,
      I => pllout_clk_sys);

  cmp_clk_dmtd_buf : BUFG
    port map (
      O => clk_dmtd,
      I => pllout_clk_dmtd);

  cmp_clk_vcxo : BUFG
    port map (
      O => clk_20m_vcxo_buf,
      I => clk_20m_vcxo_i);



  --cmp_l_clk_gtp : IBUFDS
  --  generic map (
  --    DIFF_TERM    => true)
  --  port map (
  --    O  => wr_ref_clk_phyin,
  --    I  => wr_ref_clk_p_i,
  --    IB => wr_ref_clk_n_i
  --    );




-------------------------------------------------------------------------------
-- White Rabbit Core + PHY
-------------------------------------------------------------------------------

  U_WR_CORE : wr_core
    generic map (
      g_simulation         => 0,
      g_virtual_uart       => 0,
      g_ep_rxbuf_size_log2 => 12,
      g_dpram_initf        => "wrc_stub.ram",
      g_dpram_size         => 16384,
      g_num_gpio           => 8)
    port map (
      clk_sys_i  => clk_sys,
      clk_dmtd_i => clk_dmtd,
      clk_ref_i  => clk_125m_pllref,
      clk_aux_i => fd_clk_ref,
      rst_n_i    => local_reset_n,

      pps_p_o => pps,

      dac_hpll_load_p1_o => dac_hpll_load_p1,
      dac_hpll_data_o    => dac_hpll_data,

      dac_dpll_load_p1_o => dac_dpll_load_p1,
      dac_dpll_data_o    => dac_dpll_data,

      gpio_o     => wrc_gpio_out,
      gpio_i     => wrc_gpio_in,
      gpio_dir_o => wrc_gpio_dir,

      uart_rxd_i  => uart_rxd_i,
      uart_txd_o  => uart_txd_o,
      wb_addr_i   => cnx_out(0).adr(17 downto 0),
      wb_data_i   => cnx_out(0).dat,
      wb_data_o   => cnx_in(0).dat,
      wb_sel_i    => cnx_out(0).sel,
      wb_we_i     => cnx_out(0).we,
      wb_cyc_i    => cnx_out(0).cyc,
      wb_stb_i    => cnx_out(0).stb,
      wb_ack_o    => cnx_in(0).ack,
      rst_aux_n_o => mbone_rst_n,
      dio_o       => open,

      phy_ref_clk_i      => clk_125m_pllref,
      phy_tx_data_o      => phy_tx_data,
      phy_tx_k_o         => phy_tx_k,
      phy_tx_disparity_i => phy_tx_disparity,
      phy_tx_enc_err_i   => phy_tx_enc_err,
      phy_rx_data_i      => phy_rx_data,
      phy_rx_rbclk_i     => phy_rx_rbclk,
      phy_rx_k_i         => phy_rx_k,
      phy_rx_enc_err_i   => phy_rx_enc_err,
      phy_rx_bitslide_i  => phy_rx_bitslide,
      phy_rst_o          => phy_rst,
      phy_loopen_o       => phy_loopen,

      tm_dac_wr_o          => tm_dac_wr,
      tm_dac_value_o       => tm_dac_value,
      tm_cycles_o          => tm_cycles,
      tm_utc_o             => tm_utc,
      tm_time_valid_o      => tm_time_valid,
      tm_clk_aux_locked_o  => tm_clk_aux_locked,
      tm_clk_aux_lock_en_i => tm_clk_aux_lock_en,

      ext_snk_adr_i   => mbone_src_out.adr,
      ext_snk_dat_i   => mbone_src_out.dat,
      ext_snk_sel_i   => mbone_src_out.sel,
      ext_snk_cyc_i   => mbone_src_out.cyc,
      ext_snk_we_i    => mbone_src_out.we,
      ext_snk_stb_i   => mbone_src_out.stb,
      ext_snk_ack_o   => mbone_src_in.ack,
      ext_snk_err_o   => mbone_src_in.err,
      ext_snk_stall_o => mbone_src_in.stall,

      ext_src_adr_o   => mbone_snk_in.adr,
      ext_src_dat_o   => mbone_snk_in.dat,
      ext_src_sel_o   => mbone_snk_in.sel,
      ext_src_cyc_o   => mbone_snk_in.cyc,
      ext_src_stb_o   => mbone_snk_in.stb,
      ext_src_we_o    => mbone_snk_in.we,
      ext_src_ack_i   => mbone_snk_out.ack,
      ext_src_err_i   => mbone_snk_out.err,
      ext_src_stall_i => mbone_snk_out.stall
      );


  --chipscope_icon_1 : chipscope_icon
  --  port map (
  --    CONTROL0 => CONTROL);

  --chipscope_ila_1 : chipscope_ila
  --  port map (
  --    CONTROL => CONTROL,
  --    CLK     => clk_sys,
  --    TRIG0   => TRIG0,
  --    TRIG1   => TRIG1,
  --    TRIG2   => TRIG2,
  --    TRIG3   => TRIG3);

  --s_TRIG0(15 downto 0)  <= mbone_snk_in.dat;
  --s_TRIG0(17 downto 16) <= mbone_snk_in.adr;
  --s_TRIG0(19 downto 18) <= mbone_snk_in.sel;
  --s_TRIG0(20)           <= mbone_snk_in.cyc;
  --s_TRIG0(21)           <= mbone_snk_in.stb;
  --s_TRIG0(22)           <= mbone_snk_in.we;
  --s_TRIG0(23)           <= mbone_snk_out.ack;
  --s_TRIG0(24)           <= mbone_snk_out.stall;

  --s_TRIG1(15 downto 0)  <= mbone_src_out.dat;
  --s_TRIG1(17 downto 16) <= mbone_src_out.adr;
  --s_TRIG1(19 downto 18) <= mbone_src_out.sel;
  --s_TRIG1(20)           <= mbone_src_out.cyc;
  --s_TRIG1(21)           <= mbone_src_out.stb;
  --s_TRIG1(22)           <= mbone_src_out.we;
  --s_TRIG1(23)           <= mbone_src_in.ack;
  --s_TRIG1(24)           <= mbone_src_in.stall;

  --s_trig1(25) <= mbone_wb_out.cyc;
  --s_trig1(26) <= mbone_wb_out.stb;
  --s_trig1(27) <= mbone_wb_out.we;
  --s_trig1(28) <= mbone_wb_in.ack;

  --s_trig1(29) <= cnx_out(0).cyc;
  --s_trig1(30) <= cnx_out(0).stb;
  --s_trig1(31) <= cnx_out(0).we;
  --s_trig0(28) <= cnx_in(0).ack;

  
  --s_trig2 <= mbone_wb_out.dat;
  --s_trig3 <= mbone_wb_out.adr;


  --process(clk_sys)
  --begin
  --  if rising_edge(clk_sys) then
  --    trig0 <= s_trig0;
  --    trig1 <= s_trig1;
  --    trig2 <= s_trig2;
  --    trig3 <= s_trig3;
  --  end if;
  --end process;

  U_MiniBone : xmini_bone
    generic map (
      g_class_mask    => x"f0",
      g_our_ethertype => x"a0a0")
    port map (
      clk_sys_i => clk_sys,
      rst_n_i   => mbone_rst_n,
      src_o     => mbone_src_out,
      src_i     => mbone_src_in,
      snk_o     => mbone_snk_out,
      snk_i     => mbone_snk_in,
      master_o  => mbone_wb_out,
      master_i  => mbone_wb_in);

 -- gen_real_phy: if(g_debugging = false) generate
  U_GTP : wr_gtp_phy_spartan6
    generic map (
      g_simulation         => 0,
      g_ch1_use_refclk_out => false,
      g_ch0_use_refclk_out => false)
    port map (
      ch0_ref_clk_i      => clk_125m_pllref,
      ch0_ref_clk_o      => open,
      ch0_tx_data_i      => x"00",
      ch0_tx_k_i         => '0',
      ch0_tx_disparity_o => open,
      ch0_tx_enc_err_o   => open,
      ch0_rx_rbclk_o     => open,
      ch0_rx_data_o      => open,
      ch0_rx_k_o         => open,
      ch0_rx_enc_err_o   => open,
      ch0_rx_bitslide_o  => open,
      ch0_rst_i          => '1',
      ch0_loopen_i       => '0',

      ch1_ref_clk_i      => clk_125m_pllref,
      ch1_ref_clk_o      => open,
      ch1_tx_data_i      => phy_tx_data,
      ch1_tx_k_i         => phy_tx_k,
      ch1_tx_disparity_o => phy_tx_disparity,
      ch1_tx_enc_err_o   => phy_tx_enc_err,
      ch1_rx_data_o      => phy_rx_data,
      ch1_rx_rbclk_o     => phy_rx_rbclk,
      ch1_rx_k_o         => phy_rx_k,
      ch1_rx_enc_err_o   => phy_rx_enc_err,
      ch1_rx_bitslide_o  => phy_rx_bitslide,
      ch1_rst_i          => phy_rst,
      ch1_loopen_i       => phy_loopen,
      pad_txn0_o         => open,
      pad_txp0_o         => open,
      pad_rxn0_i         => '0',
      pad_rxp0_i         => '0',
      pad_txn1_o         => sfp_txn_o,
      pad_txp1_o         => sfp_txp_o,
      pad_rxn1_i         => sfp_rxn_i,
      pad_rxp1_i         => sfp_rxp_i);
--  end generate gen_real_phy;

  gen_debug_phy: if(g_debugging = true) generate

    U_Debug: wr_tbi_phy
      port map (
        serdes_rst_i          => phy_rst,
        serdes_loopen_i       => phy_loopen,
        serdes_prbsen_i       => '0',
        serdes_enable_i       => '1',
        serdes_syncen_i       => '1',
        serdes_tx_data_i      => phy_tx_data,
        serdes_tx_k_i         => phy_tx_k,
        serdes_tx_disparity_o => phy_tx_disparity,
        serdes_tx_enc_err_o   => phy_tx_enc_err,
        serdes_rx_data_o      => phy_rx_data,
        serdes_rx_k_o         => phy_rx_k,
        serdes_rx_enc_err_o   => phy_rx_enc_err,
        serdes_rx_bitslide_o  => phy_rx_bitslide,
        tbi_refclk_i          => clk_125m_pllref,
        tbi_rbclk_i           => phy_rx_rbclk,
        tbi_td_o              => dbg_tbi_td_o,
        tbi_rd_i              => dbg_tbi_rd_i);
    phy_rx_rbclk <= clk_125m_pllref;
  end generate gen_debug_phy;
  
  U_DAC_ARB : spec_serial_dac_arb
    generic map (
      g_invert_sclk    => false,
      g_num_extra_bits => 8)

    port map (
      clk_i   => clk_sys,
      rst_n_i => local_reset_n,

      val1_i  => dac_dpll_data,
      load1_i => dac_dpll_load_p1,

      val2_i  => dac_hpll_data,
      load2_i => dac_hpll_load_p1,

      dac_cs_n_o(0) => dac_cs1_n_o,
      dac_cs_n_o(1) => dac_cs2_n_o,
      dac_clr_n_o   => open,
      dac_sclk_o    => dac_sclk_o,
      dac_din_o     => dac_din_o);

  U_Extend_PPS : gc_extend_pulse
    generic map (
      g_width => 10000000)
    port map (
      clk_i      => clk_125m_pllref,
      rst_n_i    => local_reset_n,
      pulse_i    => pps,
      extended_o => LED_RED);

  LED_GREEN <= wrc_gpio_out(0);

  sfp_mod_def0_b <= '0';
  sfp_mod_def1_b <= '0';
  sfp_mod_def2_b <= '0';

  sfp_tx_disable_o <= '0';

-------------------------------------------------------------------------------
-- FINE DELAY INSTANTIATION
-------------------------------------------------------------------------------



  U_Fanout : xwb_bus_fanout
    generic map (
      g_num_outputs    => 2,
      g_bits_per_slave => 18)
    port map (
      clk_sys_i => clk_sys,
      rst_n_i   => local_reset_n,
      slave_i   => mbone_wb_out,
      slave_o   => mbone_wb_in,
      master_i  => cnx_in,
      master_o  => cnx_out);  

 -- cnx_in(1).ack <= '0';

  U_DELAY_CORE : fine_delay_core
    port map (
      clk_ref_i            => fd_clk_ref,
      tdc_start_i          => fd_tdc_start,
      clk_sys_i            => clk_sys,
      rst_n_i              => local_reset_n,
      trig_a_n_i           => fd_trig_a_i,
      trig_cal_o           => fd_trig_cal_o,
      led_trig_o           => fd_led_trig_o,
      acam_a_o             => fd_tdc_a_o,
      acam_d_o             => tdc_data_out,
      acam_d_i             => tdc_data_in,
      acam_d_oen_o         => tdc_data_oe,
      acam_err_i           => '0',
      acam_int_i           => '0',
      acam_emptyf_i        => fd_tdc_emptyf_i,
      acam_alutrigger_o    => fd_tdc_alutrigger_o,
      acam_cs_n_o          => fd_tdc_cs_n_o,
      acam_wr_n_o          => fd_tdc_wr_n_o,
      acam_rd_n_o          => fd_tdc_rd_n_o,
      acam_start_dis_o     => fd_tdc_start_dis_o,
      acam_stop_dis_o      => fd_tdc_stop_dis_o,
      tm_dac_value_i       => tm_dac_value,
      tm_dac_wr_i          => tm_dac_wr,
      tm_cycles_i          => tm_cycles,
      tm_time_valid_i      => tm_time_valid,
      tm_utc_i             => tm_utc,
      tm_clk_aux_lock_en_o => tm_clk_aux_lock_en,
      tm_clk_aux_locked_i  => tm_clk_aux_locked,
      spi_cs_dac_n_o       => fd_spi_cs_dac_n_o,
      spi_cs_pll_n_o       => fd_spi_cs_pll_n_o,
      spi_cs_gpio_n_o      => fd_spi_cs_gpio_n_o,
      spi_sclk_o           => fd_spi_sclk_o,
      spi_mosi_o           => fd_spi_mosi_o,
      spi_miso_i           => fd_spi_miso_i,
      i2c_scl_i            => fmc_scl_b,
      i2c_scl_o            => scl_pad_out,
      i2c_scl_oen_o        => scl_pad_oen,
      i2c_sda_i            => fmc_sda_b,
      i2c_sda_o            => sda_pad_out,
      i2c_sda_oen_o        => sda_pad_oen,
      delay_len_o          => fd_delay_len_o,
      delay_val_o          => fd_delay_val_o,
      delay_pulse_o        => fd_delay_pulse_o,
      owr_i                => onewire_b,
      owr_en_o             => onewire_en,
      wb_adr_i             => cnx_out(1).adr(7 downto 0),
      wb_dat_i             => cnx_out(1).dat,
      wb_dat_o             => cnx_in(1).dat,
      wb_cyc_i             => cnx_out(1).cyc,
      wb_stb_i             => cnx_out(1).stb,
      wb_we_i              => cnx_out(1).we,
      wb_ack_o             => cnx_in(1).ack);


  cmp_fd_refclk : IBUFGDS
    generic map (
      DIFF_TERM    => true,             -- Differential Termination
      IBUF_LOW_PWR => false,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "LVDS_25")
    port map (
      O  => fd_clk_ref,                 -- Buffer output
      I  => fd_clk_ref_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => fd_clk_ref_n_i  -- Diff_n buffer input (connect directly to top-level port)
      );

  --U_FD_CLK_wtfbuf1: BUFIO2
  --  port map (
  --    DIVCLK       => fd_clk_ref_bufio_q,
  --    IOCLK        => open,
  --    SERDESSTROBE => open,
  --    I            => fd_clk_ref_pin);

  --U_FD_CLK_wtfbuf2: BUFG
  --  port map (
  --    I => fd_clk_ref_bufio_q,
  --    O => fd_clk_ref
  --    );

process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      wrc_gpio_in(1) <= dna_dout;
      dna_din <= wrc_gpio_out(1);
      dna_read <= wrc_gpio_out(2);
      dna_shift <= wrc_gpio_out(3);
      dna_clk <= wrc_gpio_out(4);
    end if;
  end process;
  

  U_DNA: DNA_PORT
    port map (
      DOUT  => dna_dout,
      CLK   => dna_clk,
      DIN   => dna_din,
      READ  => dna_read,
      SHIFT => dna_shift);
  
  cmp_pll_refclk : IBUFGDS
    generic map (
      DIFF_TERM    => true,             -- Differential Termination
      IBUF_LOW_PWR => false,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "LVDS_25")
    port map (
      O  => clk_125m_pllref,            -- Buffer output
      I  => clk_125m_pllref_p_i,
      IB => clk_125m_pllref_n_i
      );

  
  cmp_fd_tdc_start : IBUFDS
    generic map (
      DIFF_TERM    => true,
      IBUF_LOW_PWR => false  -- Low power (TRUE) vs. performance (FALSE) setting for referenced
      )
    port map (
      O  => fd_tdc_start,               -- Buffer output
      I  => fd_tdc_start_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => fd_tdc_start_n_i  -- Diff_n buffer input (connect directly to top-level port)
      );

  
  fmc_scl_b  <= scl_pad_out when scl_pad_oen = '0' else 'Z';
  fmc_sda_b  <= sda_pad_out when sda_pad_oen = '0' else 'Z';
  scl_pad_in <= fmc_scl_b;
  sda_pad_in <= fmc_sda_b;

-- tristate buffer for the TDC data bus:
  fd_tdc_d_b    <= tdc_data_out when tdc_data_oe = '1' else (others => 'Z');
  fd_tdc_oe_n_o <= '1';
  tdc_data_in   <= fd_tdc_d_b;

  onewire_b <= '0' when onewire_en = '0' else 'Z';
  
end rtl;


