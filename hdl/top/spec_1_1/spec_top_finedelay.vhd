--------------------------------------------------------------------------------
--                                                                            --
-- CERN BE-CO-HT         GN4124 core for PCIe FMC carrier                     --
--                       http://www.ohwr.org/projects/gn4124-core             --
--------------------------------------------------------------------------------
--
-- unit name: pfc_ddr_test_top (pfc_ddr_test_top.vhd)
--
-- author: Matthieu Cattin (matthieu.cattin@cern.ch)
--
-- date: 15-12-2010
--
-- version: 0.1
--
-- description: Top entity for PFC board.
--
-- dependencies:
--
--------------------------------------------------------------------------------
-- last changes: see svn log.
--------------------------------------------------------------------------------
-- TODO: - 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.gn4124_core_pkg.all;

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
      GPIO       : inout std_logic_vector(1 downto 0);  -- GPIO[0] -> GN4124 GPIO8
                                        -- GPIO[1] -> GN4124 GPIO9
      -- PCIe to Local [Inbound Data] - RX
      P2L_RDY    : out   std_logic;     -- Rx Buffer Full Flag
      P2L_CLKn   : in    std_logic;     -- Receiver Source Synchronous Clock-
      P2L_CLKp   : in    std_logic;     -- Receiver Source Synchronous Clock+
      P2L_DATA   : in    std_logic_vector(15 downto 0);  -- Parallel receive data
      P2L_DFRAME : in    std_logic;     -- Receive Frame
      P2L_VALID  : in    std_logic;     -- Receive Data Valid

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

      fd_tdc_start_i   : in std_logic;
      fd_clk_ref_p_i : in std_logic;
      fd_clk_ref_n_i : in std_logic;

      fd_trig_a_i         : in    std_logic;
      fd_trig_cal_o       : out   std_logic;
      fd_tdc_d_b          : inout std_logic_vector(27 downto 0);
      fd_tdc_a_o          : out   std_logic_vector(3 downto 0);
      fd_tdc_err_i        : in    std_logic;
      fd_tdc_int_i        : in    std_logic;
      fd_tdc_emptyf_i     : in    std_logic;
      fd_tdc_alutrigger_o : out   std_logic;
      fd_tdc_cs_n_o       : out   std_logic;
      fd_tdc_wr_n_o       : out   std_logic;
      fd_tdc_rd_n_o       : out   std_logic;
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


      scl0_b : inout std_logic;         --fmc_scl
      sda0_b : inout std_logic          --fmc_sda
      );

end spec_top;

architecture rtl of spec_top is

  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------

  component fine_delay_core
    port (
      clk_ref_i         : in  std_logic;
      clk_sys_i         : in  std_logic;
      rst_n_i           : in  std_logic;
      tdc_start_i : in std_logic;
      trig_a_n_i        : in  std_logic;
      trig_cal_o        : out std_logic;
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
      spi_cs_dac_n_o    : out std_logic;
      spi_cs_pll_n_o    : out std_logic;
      spi_cs_gpio_n_o   : out std_logic;
      spi_sclk_o        : out std_logic;
      spi_mosi_o        : out std_logic;
      spi_miso_i        : in  std_logic;
      delay_len_o       : out std_logic_vector(3 downto 0);
      delay_val_o       : out std_logic_vector(9 downto 0);
      delay_pulse_o     : out std_logic_vector(3 downto 0);
      csync_p1_i        : in  std_logic;
      csync_coarse_i    : in  std_logic_vector(27 downto 0);
      csync_utc_i       : in  std_logic_vector(31 downto 0);
      wb_adr_i          : in  std_logic_vector(4 downto 0);
      wb_dat_i          : in  std_logic_vector(31 downto 0);
      wb_dat_o          : out std_logic_vector(31 downto 0);
      wb_cyc_i          : in  std_logic;
      wb_stb_i          : in  std_logic;
      wb_we_i           : in  std_logic;
      wb_ack_o          : out std_logic);
  end component;

  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  constant c_BAR0_APERTURE     : integer := 20;
  constant c_CSR_WB_SLAVES_NB  : integer := 2;
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

  signal irq_to_gn4124 : std_logic;

  -- SPI
  signal spi_slave_select : std_logic_vector(7 downto 0);


  signal pllout_clk_sys  : std_logic;
  signal pllout_clk_dmtd : std_logic;
  signal pllout_clk_fb   : std_logic;

  signal clk_20m_vcxo_buf : std_logic;
  signal clk_125m_pllref  : std_logic;
  signal clk_sys          : std_logic;
  signal clk_dmtd         : std_logic;
  signal dac_rst_n        : std_logic;



  component wb_gpio_port_notristates
    generic (
      g_num_pins : natural);
    port (
      wb_rst_i   : in    std_logic;
      wb_clk_i   : in    std_logic;
      wb_sel_i   : in    std_logic;
      wb_cyc_i   : in    std_logic;
      wb_stb_i   : in    std_logic;
      wb_we_i    : in    std_logic;
      wb_addr_i  : in    std_logic_vector(2 downto 0);
      wb_data_i  : in    std_logic_vector(31 downto 0);
      wb_data_o  : out   std_logic_vector(31 downto 0);
      wb_ack_o   : out   std_logic;
      gpio_o     : inout std_logic_vector(g_num_pins-1 downto 0);
      gpio_i     : inout std_logic_vector(g_num_pins-1 downto 0);
      gpio_dir_o : inout std_logic_vector(g_num_pins-1 downto 0)
      );
  end component;

  signal gpio_out     : std_logic_vector(31 downto 0);
  signal gpio_in      : std_logic_vector(31 downto 0);
  signal clk_vec_hpll : std_logic_vector(0 downto 0);

  signal hdac_data : std_logic_vector(15 downto 0);
  signal hdac_load : std_logic;

  signal led_divider : unsigned(23 downto 0);


  signal fd_clk_ref : std_logic;

  signal tdc_data_out, tdc_data_in : std_logic_vector(27 downto 0);
  signal tdc_data_oe               : std_logic;
  
  
  
begin

  clk_20m_vcxo_buf <= clk_20m_vcxo_i;


  cmp_sys_clk_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 50,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 16,         -- 62.5 MHz
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKOUT1_DIVIDE     => 8,          -- 125 MHz
      CLKOUT1_PHASE      => 0.000,
      CLKOUT1_DUTY_CYCLE => 0.500,
      CLKOUT2_DIVIDE     => 4,
      CLKOUT2_PHASE      => 0.000,
      CLKOUT2_DUTY_CYCLE => 0.500,
      CLKIN_PERIOD       => 50.0,
      REF_JITTER         => 0.016)
    port map (
      CLKFBOUT => pllout_clk_fb,
      CLKOUT0  => pllout_clk_sys,
      CLKOUT1  => pllout_clk_dmtd,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => open,
      RST      => '0',
      CLKFBIN  => pllout_clk_fb,
      CLKIN    => clk_20m_vcxo_buf);



  cmp_clk_sys_buf : BUFG
    port map (
      O => clk_sys,
      I => pllout_clk_sys);

  cmp_clk_dmtd_buf : BUFG
    port map (
      O => clk_dmtd,
      I => pllout_clk_dmtd);

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

  cmp_pllrefclk_buf : IBUFDS
    generic map (
      DIFF_TERM    => true,             -- Differential Termination
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => clk_125m_pllref,            -- Buffer output
      I  => clk_125m_pllref_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => clk_125m_pllref_n_i  -- Diff_n buffer input (connect directly to top-level port)
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
      --   g_IS_SPARTAN6       => true,
      g_BAR0_APERTURE     => c_BAR0_APERTURE,
      g_CSR_WB_SLAVES_NB  => c_CSR_WB_SLAVES_NB,
      g_DMA_WB_SLAVES_NB  => c_DMA_WB_SLAVES_NB,
      g_DMA_WB_ADDR_WIDTH => c_DMA_WB_ADDR_WIDTH,
      g_CSR_WB_MODE => "classic"
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
      wb_clk_i => clk_sys,
      wb_adr_o => wb_adr,
      wb_dat_o => wb_dat_o,
      wb_sel_o => wb_sel,
      wb_stb_o => wb_stb,
      wb_we_o  => wb_we,
      wb_cyc_o => wb_cyc,
      wb_dat_i => wb_dat_i,
      wb_ack_i => wb_ack,

      ---------------------------------------------------------
      -- L2P DMA Interface (Pipelined Wishbone master)
      dma_clk_i   => clk_sys,
      dma_adr_o   => open,
      dma_dat_o   => open,
      dma_sel_o   => open,
      dma_stb_o   => open,
      dma_we_o    => open,
      dma_cyc_o   => open,
      dma_dat_i   => x"00000000",
      dma_ack_i   => '0',
      dma_stall_i => '0'
      );

  ------------------------------------------------------------------------------
  -- CSR wishbone bus slaves
  ------------------------------------------------------------------------------

  U_gpio_port : wb_gpio_port_notristates
    generic map (
      g_num_pins => 32)
    port map (
      wb_rst_i   => rst,
      wb_clk_i   => clk_sys,
      wb_sel_i   => '1',
      wb_cyc_i   => wb_cyc(0),
      wb_stb_i   => wb_stb,
      wb_we_i    => wb_we,
      wb_addr_i  => wb_adr(2 downto 0),
      wb_data_i  => wb_dat_o,
      wb_data_o  => wb_dat_i(31 downto 0),
      wb_ack_o   => wb_ack(0),
      gpio_o     => gpio_out,
      gpio_i     => gpio_in,
      gpio_dir_o => open);

  LED_GREEN <= gpio_out(1);

  process(clk_20m_vcxo_buf, rst)
  begin
    if rising_edge(clk_20m_vcxo_buf) then
      --     if(rst = '1') then
      --     led_divider <= (others => '0');
--      else
      led_divider <= led_divider + 1;
    end if;
  end process;

  LED_RED <= std_logic(led_divider(led_divider'high));

  scl0_b <= '0' when gpio_out(28) = '0' else 'Z';
  sda0_b <= '0' when gpio_out(29) = '0' else 'Z';
  gpio_in(27 downto 0) <= (others => '0');
  
                         
  gpio_in(28) <= scl0_b;
  gpio_in(29) <= sda0_b;

  --cmp_fd_refclk : IBUFDS
  -- generic map (
  --   DIFF_TERM    => true,             -- Differential Termination
  --   IBUF_LOW_PWR => false,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
  --   IOSTANDARD   => "LVDS_25")
  -- port map (
  --   O  => fd_clk_ref,            -- Buffer output
  --   I  => fd_clk_ref_p_i,  -- Diff_p buffer input (connect directly to top-level port)
  --   IB => fd_clk_ref_n_i  -- Diff_n buffer input (connect directly to top-level port)
  --   );

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

  U_DELAY_CORE : fine_delay_core
    port map (
      clk_ref_i         => fd_clk_ref,
      tdc_start_i => fd_tdc_start_i,
      clk_sys_i         => clk_sys,
      rst_n_i           => L_RST_N,
      trig_a_n_i        => fd_trig_a_i,
      trig_cal_o        => fd_trig_cal_o,
      acam_a_o          => fd_tdc_a_o,
      acam_d_o          => tdc_data_out,
      acam_d_i          => tdc_data_in,
      acam_d_oen_o      => tdc_data_oe,
      acam_err_i        => fd_tdc_err_i,
      acam_int_i        => fd_tdc_int_i,
      acam_emptyf_i     => fd_tdc_emptyf_i,
      acam_alutrigger_o => fd_tdc_alutrigger_o,
      acam_cs_n_o       => fd_tdc_cs_n_o,
      acam_wr_n_o       => fd_tdc_wr_n_o,
      acam_rd_n_o       => fd_tdc_rd_n_o,
      acam_start_dis_o  => fd_tdc_start_dis_o,
      acam_stop_dis_o   => fd_tdc_stop_dis_o,
      csync_p1_i => '0',
      csync_utc_i => x"00000000",
      csync_coarse_i => x"0000000",
      spi_cs_dac_n_o    => fd_spi_cs_dac_n_o,
      spi_cs_pll_n_o    => fd_spi_cs_pll_n_o,
      spi_cs_gpio_n_o   => fd_spi_cs_gpio_n_o,
      spi_sclk_o        => fd_spi_sclk_o,
      spi_mosi_o        => fd_spi_mosi_o,
      spi_miso_i        => fd_spi_miso_i,
      delay_len_o       => fd_delay_len_o,
      delay_val_o       => fd_delay_val_o,
      delay_pulse_o     => fd_delay_pulse_o,
      wb_adr_i          => wb_adr(4 downto 0),
      wb_dat_i          => wb_dat_o,
      wb_dat_o          => wb_dat_i(63 downto 32),
      wb_cyc_i          => wb_cyc(1),
      wb_stb_i          => wb_stb,
      wb_we_i           => wb_we,
      wb_ack_o          => wb_ack(1));

-- tristate buffer for the TDC data bus:
  fd_tdc_d_b  <= tdc_data_out when tdc_data_oe = '1' else (others => 'Z');
  tdc_data_in <= fd_tdc_d_b;
  
  
end rtl;


