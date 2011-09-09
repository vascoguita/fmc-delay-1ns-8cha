
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.gn4124_core_pkg.all;
use work.wishbone_pkg.all;

library UNISIM;
use UNISIM.vcomponents.all;



entity spec_top is
  generic
    (
      TAR_ADDR_WDTH : integer := 13     -- not used for this project
      );
  port
    (
      -- Global ports
      clk_20m_vcxo_i : in std_logic;    -- 20MHz VCXO clock

      clk_125m_pllref_p_i : in std_logic;  -- 125 MHz PLL reference
      clk_125m_pllref_n_i : in std_logic;


      -- From GN4124 Local bus
      L_CLKp : in std_logic;  -- Local bus clock (frequency set in GN4124 config registers)
      L_CLKn : in std_logic;  -- Local bus clock (frequency set in GN4124 config registers)

      L_RST_N : in std_logic;           -- Reset from GN4124 (RSTOUT18_N)

      -- General Purpose Interface
      GPIO : inout std_logic_vector(1 downto 0);  -- GPIO[0] -> GN4124 GPIO8
                                                  -- GPIO[1] -> GN4124 GPIO9

      -- PCIe to Local [Inbound Data] - RX
      P2L_RDY    : out std_logic;       -- Rx Buffer Full Flag
      P2L_CLKn   : in  std_logic;       -- Receiver Source Synchronous Clock-
      P2L_CLKp   : in  std_logic;       -- Receiver Source Synchronous Clock+
      P2L_DATA   : in  std_logic_vector(15 downto 0);  -- Parallel receive data
      P2L_DFRAME : in  std_logic;       -- Receive Frame
      P2L_VALID  : in  std_logic;       -- Receive Data Valid

      -- Inbound Buffer Request/Status
      P_WR_REQ : in  std_logic_vector(1 downto 0);  -- PCIe Write Request
      P_WR_RDY : out std_logic_vector(1 downto 0);  -- PCIe Write Ready
      RX_ERROR : out std_logic;                     -- Receive Error

      -- Local to Parallel [Outbound Data] - TX
      L2P_DATA   : out std_logic_vector(15 downto 0);  -- Parallel transmit data
      L2P_DFRAME : out std_logic;       -- Transmit Data Frame
      L2P_VALID  : out std_logic;       -- Transmit Data Valid
      L2P_CLKn   : out std_logic;  -- Transmitter Source Synchronous Clock-
      L2P_CLKp   : out std_logic;  -- Transmitter Source Synchronous Clock+
      L2P_EDB    : out std_logic;       -- Packet termination and discard

      -- Outbound Buffer Status
      L2P_RDY    : in std_logic;        -- Tx Buffer Full Flag
      L_WR_RDY   : in std_logic_vector(1 downto 0);  -- Local-to-PCIe Write
      P_RD_D_RDY : in std_logic_vector(1 downto 0);  -- PCIe-to-Local Read Response Data Ready
      TX_ERROR   : in std_logic;        -- Transmit Error
      VC_RDY     : in std_logic_vector(1 downto 0);  -- Channel ready

      -- Font panel LEDs
      LED_RED   : out std_logic;
      LED_GREEN : out std_logic;

      fd_tdc_start_p_i : in std_logic;
      fd_tdc_start_n_i : in std_logic;

      fd_clk_ref_p_i : in std_logic;
      fd_clk_ref_n_i : in std_logic;

      fd_trig_a_i         : in    std_logic;
      fd_trig_cal_o       : out   std_logic;
      fd_tdc_d_b          : inout std_logic_vector(27 downto 0);
      fd_tdc_a_o          : out   std_logic_vector(3 downto 0);
      fd_tdc_emptyf_i     : in    std_logic;
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
      fd_spi_miso_i       : in    std_logic;
      fd_delay_len_o      : out   std_logic_vector(3 downto 0);
      fd_delay_val_o      : out   std_logic_vector(9 downto 0);
      fd_delay_pulse_o    : out   std_logic_vector(3 downto 0);

      fmc_scl_b : inout std_logic;
      fmc_sda_b : inout std_logic;
      onewire_b : inout std_logic
      );

end spec_top;

architecture rtl of spec_top is
  component spec_gbit_tester
    port (
      clk_ref_gtp0_i : in  std_logic;
      clk_ref_gtp1_i : in  std_logic;
      clk_sys_i      : in  std_logic;
      rst_n_i        : in  std_logic;
      sfp_txp_o      : out std_logic;
      sfp_txn_o      : out std_logic;
      sfp_rxp_i      : in  std_logic;
      sfp_rxn_i      : in  std_logic;
      sata1_txp_o    : out std_logic;
      sata1_txn_o    : out std_logic;
      sata1_rxp_i    : in  std_logic;
      sata1_rxn_i    : in  std_logic;
      sata2_txp_o    : out std_logic;
      sata2_txn_o    : out std_logic;
      sata2_rxp_i    : in  std_logic;
      sata2_rxn_i    : in  std_logic;
      fmc_txp_o      : out std_logic;
      fmc_txn_o      : out std_logic;
      fmc_rxp_i      : in  std_logic;
      fmc_rxn_i      : in  std_logic;
      fmc_gbtclk_i   : in  std_logic;


      wb_addr_i : in  std_logic_vector(2 downto 0);
      wb_data_i : in  std_logic_vector(31 downto 0);
      wb_data_o : out std_logic_vector(31 downto 0);
      wb_cyc_i  : in  std_logic;
      wb_sel_i  : in  std_logic_vector(3 downto 0);
      wb_stb_i  : in  std_logic;
      wb_we_i   : in  std_logic;
      wb_ack_o  : out std_logic);
  end component;

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
  signal clk_125m_gtp0    : std_logic;
  signal clk_125m_gtp1    : std_logic;
  signal clk_sys          : std_logic;
  signal clk_dmtd         : std_logic;

  signal led_divider : unsigned(23 downto 0);

  signal scl_pad_out : std_logic;
  signal scl_pad_in  : std_logic;
  signal scl_pad_oen : std_logic;

  signal sda_pad_out : std_logic;
  signal sda_pad_in  : std_logic;
  signal sda_pad_oen : std_logic;

  signal tdc_data_out, tdc_data_in : std_logic_vector(27 downto 0);
  signal tdc_data_oe               : std_logic;

  constant c_NUM_WISHBONE_DEVS : integer := 3;

  signal cnx_slave_in  : t_wishbone_slave_in;
  signal cnx_slave_out : t_wishbone_slave_out;
  signal cnx_out       : t_wishbone_master_out_array (0 to c_NUM_WISHBONE_DEVS-1);
  signal cnx_in        : t_wishbone_master_in_array (0 to c_NUM_WISHBONE_DEVS-1);


  signal fd_clk_ref   : std_logic;
  signal fd_tdc_start : std_logic;

  signal onewire_en : std_logic;


  component fine_delay_core
    port (
      clk_ref_i         : in  std_logic;
      clk_sys_i         : in  std_logic;
      rst_n_i           : in  std_logic;
      trig_a_n_i        : in  std_logic;
      trig_cal_o        : out std_logic;
      tdc_start_i       : in  std_logic;
      acam_a_o          : out std_logic_vector(3 downto 0);
      acam_d_o          : out std_logic_vector(27 downto 0);
      acam_d_i          : in  std_logic_vector(27 downto 0);
      acam_d_oen_o      : out std_logic;
      acam_err_i        : in  std_logic;
      acam_int_i        : in  std_logic;
      acam_emptyf_i     : in  std_logic;
      acam_alutrigger_o : out std_logic;
      acam_cs_n_o       : out std_logic;
      acam_wr_n_o       : out std_logic;
      acam_rd_n_o       : out std_logic;
      acam_start_dis_o  : out std_logic;
      acam_stop_dis_o   : out std_logic;
      led_trig_o        : out std_logic;
      spi_cs_dac_n_o    : out std_logic;
      spi_cs_pll_n_o    : out std_logic;
      spi_cs_gpio_n_o   : out std_logic;
      spi_sclk_o        : out std_logic;
      spi_mosi_o        : out std_logic;
      spi_miso_i        : in  std_logic;
      delay_len_o       : out std_logic_vector(3 downto 0);
      delay_val_o       : out std_logic_vector(9 downto 0);
      delay_pulse_o     : out std_logic_vector(3 downto 0);
      owr_en_o          : out std_logic;
      owr_i             : in  std_logic;
      wr_time_valid_i   : in  std_logic;
      wr_coarse_i       : in  std_logic_vector(27 downto 0);
      wr_utc_i          : in  std_logic_vector(31 downto 0);
      wb_adr_i          : in  std_logic_vector(7 downto 0);
      wb_dat_i          : in  std_logic_vector(31 downto 0);
      wb_dat_o          : out std_logic_vector(31 downto 0);
      wb_cyc_i          : in  std_logic;
      wb_stb_i          : in  std_logic;
      wb_we_i           : in  std_logic;
      wb_ack_o          : out std_logic;
      wb_irq_o          : out std_logic);
  end component;

  signal rst_n : std_logic;

  signal powerup_rst_counter : std_logic_vector(10 downto 0) := "00000000000";
  

begin

  process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      powerup_rst_counter <= '1' & powerup_rst_counter(10 downto 1);
    end if;
  end process;

  rst_n <= powerup_rst_counter(0);

  --cmp_sys_clk_pll : PLL_BASE
  --  generic map (
  --    BANDWIDTH          => "OPTIMIZED",
  --    CLK_FEEDBACK       => "CLKFBOUT",
  --    COMPENSATION       => "INTERNAL",
  --    DIVCLK_DIVIDE      => 1,
  --    CLKFBOUT_MULT      => 8,
  --    CLKFBOUT_PHASE     => 0.000,
  --    CLKOUT0_DIVIDE     => 16,         -- 62.5 MHz
  --    CLKOUT0_PHASE      => 0.000,
  --    CLKOUT0_DUTY_CYCLE => 0.500,
  --    CLKOUT1_DIVIDE     => 16,         -- 125 MHz
  --    CLKOUT1_PHASE      => 0.000,
  --    CLKOUT1_DUTY_CYCLE => 0.500,
  --    CLKOUT2_DIVIDE     => 16,
  --    CLKOUT2_PHASE      => 0.000,
  --    CLKOUT2_DUTY_CYCLE => 0.500,
  --    CLKIN_PERIOD       => 8.0,
  --    REF_JITTER         => 0.016)
  --  port map (
  --    CLKFBOUT => pllout_clk_fb_pllref,
  --    CLKOUT0  => pllout_clk_sys,
  --    CLKOUT1  => open,
  --    CLKOUT2  => open,
  --    CLKOUT3  => open,
  --    CLKOUT4  => open,
  --    CLKOUT5  => open,
  --    LOCKED   => open,
  --    RST      => '0',
  --    CLKFBIN  => pllout_clk_fb_pllref,
  --    CLKIN    => clk_125m_pllref);

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
      CLKOUT1  => pllout_clk_sys,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => open,
      RST      => '0',
      CLKFBIN  => pllout_clk_fb_dmtd,
      CLKIN    => clk_20m_vcxo_i);



  cmp_clk_sys_buf : BUFG
    port map (
      O => clk_sys,
      I => pllout_clk_sys);

  cmp_clk_dmtd_buf : BUFG
    port map (
      O => clk_dmtd,
      I => pllout_clk_dmtd);

  --cmp_clk_vcxo : BUFG
  --  port map (
  --    O => clk_20m_vcxo_buf,
  --    I => clk_20m_vcxo_i);

  ------------------------------------------------------------------------------
  -- Local clock from gennum LCLK
  ------------------------------------------------------------------------------
  cmp_l_clk_buf : IBUFDS
    generic map (
      DIFF_TERM    => false,            -- Differential Termination
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => l_clk,                      -- Buffer output
      I  => L_CLKp,  -- Diff_p buffer input (connect directly to top-level port)
      IB => L_CLKn  -- Diff_n buffer input (connect directly to top-level port)
      );








------------------------------------------------------------------------------
  -- Active high reset
  ------------------------------------------------------------------------------
  rst <= not(L_RST_N);

  ------------------------------------------------------------------------------
  -- GN4124 interface
  ------------------------------------------------------------------------------
  cmp_gn4124_core : gn4124_core
    generic map (
      -- g_IS_SPARTAN6       => true,
      g_BAR0_APERTURE     => c_BAR0_APERTURE,
      g_CSR_WB_SLAVES_NB  => c_CSR_WB_SLAVES_NB,
      g_DMA_WB_SLAVES_NB  => c_DMA_WB_SLAVES_NB,
      g_DMA_WB_ADDR_WIDTH => c_DMA_WB_ADDR_WIDTH,
      g_CSR_WB_MODE       => "classic"
      )
    port map
    (
      ---------------------------------------------------------
      -- Control and status
      --
      -- Asynchronous reset from GN4124
      rst_n_a_i      => L_RST_N,
      -- P2L clock PLL locked
      p2l_pll_locked => p2l_pll_locked,
      -- Debug outputs
      debug_o        => open,

      ---------------------------------------------------------
      -- P2L Direction
      --
      -- Source Sync DDR related signals
      p2l_clk_p_i  => P2L_CLKp,
      p2l_clk_n_i  => P2L_CLKn,
      p2l_data_i   => P2L_DATA,
      p2l_dframe_i => P2L_DFRAME,
      p2l_valid_i  => P2L_VALID,

      -- P2L Control
      p2l_rdy_o  => P2L_RDY,
      p_wr_req_i => P_WR_REQ,
      p_wr_rdy_o => P_WR_RDY,
      rx_error_o => RX_ERROR,

      ---------------------------------------------------------
      -- L2P Direction
      --
      -- Source Sync DDR related signals
      l2p_clk_p_o  => L2P_CLKp,
      l2p_clk_n_o  => L2P_CLKn,
      l2p_data_o   => L2P_DATA,
      l2p_dframe_o => L2P_DFRAME,
      l2p_valid_o  => L2P_VALID,
      l2p_edb_o    => L2P_EDB,

      -- L2P Control
      l2p_rdy_i    => L2P_RDY,
      l_wr_rdy_i   => L_WR_RDY,
      p_rd_d_rdy_i => P_RD_D_RDY,
      tx_error_i   => TX_ERROR,
      vc_rdy_i     => VC_RDY,

      ---------------------------------------------------------
      -- Interrupt interface
      dma_irq_o => open,
      irq_p_i   => '0',
      irq_p_o   => GPIO(0),

      ---------------------------------------------------------
      -- Target Interface (Wishbone master)
      wb_clk_i    => clk_sys,
      wb_adr_o    => cnx_slave_in.adr(18 downto 0),
      wb_dat_o    => cnx_slave_in.dat,
      wb_sel_o    => cnx_slave_in.sel,
      wb_stb_o    => cnx_slave_in.stb,
      wb_we_o     => cnx_slave_in.we,
      wb_cyc_o(0) => cnx_slave_in.cyc,
      wb_dat_i    => cnx_slave_out.dat,
      wb_ack_i(0) => cnx_slave_out.ack,

      ---------------------------------------------------------
      -- L2P DMA Interface (Pipelined Wishbone master)
      dma_clk_i   => clk_sys,
      dma_adr_o   => dma_adr,
      dma_dat_o   => dma_dat_o,
      dma_sel_o   => dma_sel,
      dma_stb_o   => dma_stb,
      dma_we_o    => dma_we,
      dma_cyc_o   => dma_cyc,
      dma_dat_i   => dma_dat_i,
      dma_ack_i   => dma_ack,
      dma_stall_i => dma_stall
      );

  process(clk_sys, rst)
  begin
    if rising_edge(clk_sys) then
      if(rst_n = '0') then
        led_divider <= (others => '0');
      else
        led_divider <= led_divider + 1;
        LED_RED     <= std_logic(led_divider(led_divider'high));
        LED_GREEN   <= std_logic(led_divider(led_divider'high));
      end if;
    end if;
  end process;

  --fd_tdc_oe_n_o <= '1';



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


  U_Fanout : xwb_bus_fanout
    generic map (
      g_num_outputs    => c_NUM_WISHBONE_DEVS,
      g_bits_per_slave => 8)
    port map (
      clk_sys_i => clk_sys,
      rst_n_i   => rst_n,
      slave_i   => cnx_slave_in,
      slave_o   => cnx_slave_out,
      master_i  => cnx_in,
      master_o  => cnx_out);  

  cnx_in(2).int <= '0';
  cnx_in(2).ack <= '0';
  cnx_in(2).rty <= '0';
  cnx_in(2).err <= '0';



  U_I2C : xwb_i2c_master
    generic map (
      g_interface_mode => CLASSIC)

    port map (
      clk_sys_i    => clk_sys,
      rst_n_i      => rst_n,
      slave_i      => cnx_out(0),
      slave_o      => cnx_in(0),
      desc_o       => open,
      scl_pad_i    => scl_pad_in,
      scl_pad_o    => scl_pad_out,
      scl_padoen_o => scl_pad_oen,
      sda_pad_i    => sda_pad_in,
      sda_pad_o    => sda_pad_out,
      sda_padoen_o => sda_pad_oen);

  fmc_scl_b  <= scl_pad_out when scl_pad_oen = '0' else 'Z';
  fmc_sda_b  <= sda_pad_out when sda_pad_oen = '0' else 'Z';
  scl_pad_in <= fmc_scl_b;
  sda_pad_in <= fmc_sda_b;



  U_DELAY_CORE : fine_delay_core
    port map (
      clk_ref_i         => fd_clk_ref,
      tdc_start_i       => fd_tdc_start,
      clk_sys_i         => clk_sys,
      rst_n_i           => RST_N,
      trig_a_n_i        => fd_trig_a_i,
      trig_cal_o        => fd_trig_cal_o,
      led_trig_o        => fd_led_trig_o,
      acam_a_o          => fd_tdc_a_o,
      acam_d_o          => tdc_data_out,
      acam_d_i          => tdc_data_in,
      acam_d_oen_o      => tdc_data_oe,
      acam_err_i        => '0',
      acam_int_i        => '0',
      acam_emptyf_i     => fd_tdc_emptyf_i,
      acam_alutrigger_o => fd_tdc_alutrigger_o,
      acam_cs_n_o       => fd_tdc_cs_n_o,
      acam_wr_n_o       => fd_tdc_wr_n_o,
      acam_rd_n_o       => fd_tdc_rd_n_o,
      acam_start_dis_o  => fd_tdc_start_dis_o,
      acam_stop_dis_o   => fd_tdc_stop_dis_o,
      wr_time_valid_i   => '0',
      wr_utc_i          => x"00000000",
      wr_coarse_i       => x"0000000",
      spi_cs_dac_n_o    => fd_spi_cs_dac_n_o,
      spi_cs_pll_n_o    => fd_spi_cs_pll_n_o,
      spi_cs_gpio_n_o   => fd_spi_cs_gpio_n_o,
      spi_sclk_o        => fd_spi_sclk_o,
      spi_mosi_o        => fd_spi_mosi_o,
      spi_miso_i        => fd_spi_miso_i,
      delay_len_o       => fd_delay_len_o,
      delay_val_o       => fd_delay_val_o,
      delay_pulse_o     => fd_delay_pulse_o,
      owr_i             => onewire_b,
      owr_en_o          => onewire_en,
      wb_adr_i          => cnx_out(1).adr(7 downto 0),
      wb_dat_i          => cnx_out(1).dat,
      wb_dat_o          => cnx_in(1).dat,
      wb_cyc_i          => cnx_out(1).cyc,
      wb_stb_i          => cnx_out(1).stb,
      wb_we_i           => cnx_out(1).we,
      wb_ack_o          => cnx_in(1).ack);

-- tristate buffer for the TDC data bus:
  fd_tdc_d_b    <= tdc_data_out when tdc_data_oe = '1' else (others => 'Z');
  fd_tdc_oe_n_o <= '1';
  tdc_data_in   <= fd_tdc_d_b;

  onewire_b <= '0' when onewire_en = '0' else 'Z';
  
end rtl;


