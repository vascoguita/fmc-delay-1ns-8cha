-------------------------------------------------------------------------------
-- Title      : Fine Delay Demo (non WR) - SPEC version
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : spec_top.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-04-11
-- Platform   : Xilinx Spartan-6 (XC6SLX45T)
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top level for the Fine Delay Generator FMC core example design
-- for SPEC 1.1+ carriers.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2011 CERN / BE-CO-HT
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2011-08-24  1.0      twlostow        Created
-------------------------------------------------------------------------------

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
      --  L_CLKp : in std_logic;  -- Local bus clock (frequency set in GN4124 config registers)
      --  L_CLKn : in std_logic;  -- Local bus clock (frequency set in GN4124 config registers)

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

      -------------------------------------------------------------------------
      -- Fine Delay FMC I/Os
      -------------------------------------------------------------------------

      fd_tdc_start_p_i : in std_logic;
      fd_tdc_start_n_i : in std_logic;

      fd_clk_ref_p_i : in std_logic;
      fd_clk_ref_n_i : in std_logic;

      fd_trig_a_i         : in    std_logic;
      fd_tdc_cal_pulse_o  : out   std_logic;
      fd_tdc_d_b          : inout std_logic_vector(27 downto 0);
      fd_tdc_emptyf_i     : in    std_logic;
      fd_tdc_alutrigger_o : out   std_logic;
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

      fd_dmtd_clk_o    : out std_logic;
      fd_dmtd_fb_in_i  : in  std_logic;
      fd_dmtd_fb_out_i : in  std_logic;

      fd_pll_status_i : in  std_logic;
      fd_ext_rst_n_o  : out std_logic;

      prsnt_m2c_l: in std_logic;


      fmc_scl_b : inout std_logic;
      fmc_sda_b : inout std_logic;
      onewire_b : inout std_logic;

      -- SPEC DACs
      dac_sclk_o  : out std_logic;
      dac_din_o   : out std_logic;
      dac_cs1_n_o : out std_logic;
      dac_cs2_n_o : out std_logic
      );

end spec_top;

architecture rtl of spec_top is

  component spec_serial_dac_arb
    generic (
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

  component fd_ddr_pll
    port (
      RST       : in  std_logic;
      LOCKED    : out std_logic;
      CLK_IN1_P : in  std_logic;
      CLK_IN1_N : in  std_logic;
      CLK_OUT1  : out std_logic;
      CLK_OUT2  : out std_logic);
  end component;

  component fine_delay_core
    generic (
      g_with_wr_core        : boolean                        := false;
      g_simulation          : boolean                        := false;
      g_interface_mode      : t_wishbone_interface_mode      := PIPELINED;
      g_address_granularity : t_wishbone_address_granularity := WORD);
    port (
      clk_ref_0_i          : in  std_logic;
      clk_ref_180_i        : in  std_logic;
      clk_sys_i            : in  std_logic;
      clk_dmtd_i           : in  std_logic;
      rst_n_i              : in  std_logic;
      dcm_reset_o          : out std_logic;
      dcm_locked_i         : in  std_logic;
      trig_a_i             : in  std_logic;
      tdc_cal_pulse_o      : out std_logic;
      tdc_start_i          : in  std_logic;
      dmtd_fb_in_i         : in  std_logic;
      dmtd_fb_out_i        : in  std_logic;
      dmtd_samp_o          : out std_logic;
      led_trig_o           : out std_logic;
      ext_rst_n_o          : out std_logic;
      pll_status_i         : in  std_logic;
      acam_d_o             : out std_logic_vector(27 downto 0);
      acam_d_i             : in  std_logic_vector(27 downto 0);
      acam_d_oen_o         : out std_logic;
      acam_emptyf_i        : in  std_logic;
      acam_alutrigger_o    : out std_logic;
      acam_wr_n_o          : out std_logic;
      acam_rd_n_o          : out std_logic;
      acam_start_dis_o     : out std_logic;
      acam_stop_dis_o      : out std_logic;
      spi_cs_dac_n_o       : out std_logic;
      spi_cs_pll_n_o       : out std_logic;
      spi_cs_gpio_n_o      : out std_logic;
      spi_sclk_o           : out std_logic;
      spi_mosi_o           : out std_logic;
      spi_miso_i           : in  std_logic;
      delay_len_o          : out std_logic_vector(3 downto 0);
      delay_val_o          : out std_logic_vector(9 downto 0);
      delay_pulse_o        : out std_logic_vector(3 downto 0);
      tm_link_up_i         : in  std_logic                     := '0';
      tm_time_valid_i      : in  std_logic                     := '0';
      tm_cycles_i          : in  std_logic_vector(27 downto 0) := x"0000000";
      tm_utc_i             : in  std_logic_vector(39 downto 0) := x"0000000000";
      tm_clk_aux_lock_en_o : out std_logic;
      tm_clk_aux_locked_i  : in  std_logic                     := '0';
      tm_clk_dmtd_locked_i : in  std_logic                     := '0';
      tm_dac_value_i       : in  std_logic_vector(23 downto 0) := x"000000";
      tm_dac_wr_i          : in  std_logic                     := '0';
      dmtd_dac_value_o     : out std_logic_vector(23 downto 0);
      dmtd_dac_wr_o        : out std_logic;
      owr_en_o             : out std_logic;
      owr_i                : in  std_logic;
      i2c_scl_o            : out std_logic;
      i2c_scl_oen_o        : out std_logic;
      i2c_scl_i            : in  std_logic;
      i2c_sda_o            : out std_logic;
      i2c_sda_oen_o        : out std_logic;
      i2c_sda_i            : in  std_logic;
      fmc_present_n_i      : in  std_logic;
      wb_adr_i             : in  std_logic_vector(c_wishbone_address_width-1 downto 0);
      wb_dat_i             : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
      wb_dat_o             : out std_logic_vector(c_wishbone_data_width-1 downto 0);
      wb_sel_i             : in  std_logic_vector((c_wishbone_data_width+7)/8-1 downto 0);
      wb_cyc_i             : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_we_i              : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_stall_o           : out std_logic;
      wb_irq_o             : out std_logic);
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

  signal cnx_slave_in  : t_wishbone_slave_in_array(0 to 0);
  signal cnx_slave_out : t_wishbone_slave_out_array(0 to 0);

  signal fd_clk_ref   : std_logic;
  signal fd_tdc_start : std_logic;

  signal onewire_en : std_logic;

  signal dcm_clk_fb, dcm_clk_ref_0, dcm_clk_ref_180 : std_logic;
  signal dcm_clk_ref_0_int, dcm_clk_ref_180_int     : std_logic;

  signal rst_n : std_logic;

  signal powerup_rst_counter                : std_logic_vector(10 downto 0) := "00000000000";
  signal dcm_reset_n, dcm_reset, dcm_locked : std_logic;

  signal ddr_pll_reset                 : std_logic;
  signal ddr_pll_locked, fd_pll_status : std_logic;

  signal dac_hpll_load_p1 : std_logic;
  signal dac_hpll_data    : std_logic_vector(23 downto 0);
  
begin

  process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      powerup_rst_counter <= '1' & powerup_rst_counter(10 downto 1);
    end if;
  end process;

  rst_n <= powerup_rst_counter(0);

  U_DDR_PLL : fd_ddr_pll
    port map (
      RST       => ddr_pll_reset,
      LOCKED    => ddr_pll_locked,
      CLK_IN1_P => fd_clk_ref_p_i,
      CLK_IN1_N => fd_clk_ref_n_i,
      CLK_OUT1  => dcm_clk_ref_0,
      CLK_OUT2  => dcm_clk_ref_180);

  ddr_pll_reset <= not fd_pll_status_i;
  fd_pll_status <= fd_pll_status_i and ddr_pll_locked;


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
      g_CSR_WB_MODE       => "pipelined"
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
      wb_adr_o    => cnx_slave_in(0).adr(18 downto 0),
      wb_dat_o    => cnx_slave_in(0).dat,
      wb_sel_o    => cnx_slave_in(0).sel,
      wb_stb_o    => cnx_slave_in(0).stb,
      wb_we_o     => cnx_slave_in(0).we,
      wb_cyc_o(0) => cnx_slave_in(0).cyc,
      wb_dat_i    => cnx_slave_out(0).dat,
      wb_ack_i(0) => cnx_slave_out(0).ack,
--      wb_stall_i(0) => cnx_slave_out(0).stall,

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

  fmc_scl_b <= scl_pad_out when scl_pad_oen = '0' else 'Z';
  fmc_sda_b <= sda_pad_out when sda_pad_oen = '0' else 'Z';

  U_DELAY_CORE : fine_delay_core
    
    port map (
      clk_ref_0_i   => dcm_clk_ref_0,
      clk_ref_180_i => dcm_clk_ref_180,
      clk_sys_i     => clk_sys,
      clk_dmtd_i    => pllout_clk_dmtd,

      tdc_start_i  => fd_tdc_start,
      dcm_reset_o  => dcm_reset,
      dcm_locked_i => dcm_locked,

      rst_n_i         => RST_N,
      trig_a_i        => fd_trig_a_i,
      tdc_cal_pulse_o => fd_tdc_cal_pulse_o,

      led_trig_o        => fd_led_trig_o,
      acam_d_o          => tdc_data_out,
      acam_d_i          => tdc_data_in,
      acam_d_oen_o      => tdc_data_oe,
      acam_emptyf_i     => fd_tdc_emptyf_i,
      acam_alutrigger_o => fd_tdc_alutrigger_o,
      acam_wr_n_o       => fd_tdc_wr_n_o,
      acam_rd_n_o       => fd_tdc_rd_n_o,
      acam_start_dis_o  => fd_tdc_start_dis_o,
      acam_stop_dis_o   => fd_tdc_stop_dis_o,
      dmtd_fb_out_i     => fd_dmtd_fb_out_i,
      dmtd_fb_in_i      => fd_dmtd_fb_in_i,
      dmtd_samp_o       => fd_dmtd_clk_o,
      pll_status_i      => fd_pll_status,
      ext_rst_n_o       => fd_ext_rst_n_o,
      tm_time_valid_i   => '0',
      spi_cs_dac_n_o    => fd_spi_cs_dac_n_o,
      spi_cs_pll_n_o    => fd_spi_cs_pll_n_o,
      spi_cs_gpio_n_o   => fd_spi_cs_gpio_n_o,
      spi_sclk_o        => fd_spi_sclk_o,
      spi_mosi_o        => fd_spi_mosi_o,
      spi_miso_i        => fd_spi_miso_i,
      delay_len_o       => fd_delay_len_o,
      delay_val_o       => fd_delay_val_o,
      delay_pulse_o     => fd_delay_pulse_o,
      i2c_scl_i         => fmc_scl_b,
      i2c_scl_o         => scl_pad_out,
      i2c_scl_oen_o     => scl_pad_oen,
      i2c_sda_i         => fmc_sda_b,
      i2c_sda_o         => sda_pad_out,
      i2c_sda_oen_o     => sda_pad_oen,
      fmc_present_n_i => prsnt_m2c_l,
      owr_i             => onewire_b,
      owr_en_o          => onewire_en,
      wb_adr_i          => cnx_slave_in(0).adr,
      wb_dat_i          => cnx_slave_in(0).dat,
      wb_dat_o          => cnx_slave_out(0).dat,
      wb_sel_i          => x"f",
      wb_cyc_i          => cnx_slave_in(0).cyc,
      wb_stb_i          => cnx_slave_in(0).stb,
      wb_we_i           => cnx_slave_in(0).we,
      wb_ack_o          => cnx_slave_out(0).ack,
      wb_stall_o        => cnx_slave_out(0).stall,
      dmtd_dac_value_o  => dac_hpll_data,
      dmtd_dac_wr_o     => dac_hpll_load_p1
      );




-- tristate buffer for the TDC data bus:
  fd_tdc_d_b    <= tdc_data_out when tdc_data_oe = '1' else (others => 'Z');
  fd_tdc_oe_n_o <= '1';
  tdc_data_in   <= fd_tdc_d_b;

  onewire_b <= '0' when onewire_en = '1' else 'Z';

  -- Control of DMTD VCXO DAC
  U_DAC_ARB : spec_serial_dac_arb
    generic map (
      g_invert_sclk    => false,
      g_num_extra_bits => 8)

    port map (
      clk_i   => clk_sys,
      rst_n_i => RST_N,

      val1_i  => x"0000",
      load1_i => '0',

      val2_i  => dac_hpll_data(15 downto 0),
      load2_i => dac_hpll_load_p1,

      dac_cs_n_o(0) => dac_cs1_n_o,
      dac_cs_n_o(1) => dac_cs2_n_o,
      dac_clr_n_o   => open,
      dac_sclk_o    => dac_sclk_o,
      dac_din_o     => dac_din_o);


end rtl;


