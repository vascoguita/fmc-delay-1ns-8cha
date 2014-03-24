-------------------------------------------------------------------------------
-- Title      : Fine Delay FMC SVEC (Simple VME FMC Carrier) top level
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : svec_top.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2014-03-24
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top level for the SVEC 1.0 card with two Fine Delay FMCs.
-- Supports:
-- - A24/A32/D32 VME addressing
-- - SDB enumeration (SDB descriptor at 0x0)
-- - White Rabbit and Etherbone
-- - Interrupts (via vme64x-core interrupter, to be verified)
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


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.gencores_pkg.all;
use work.wrcore_pkg.all;
use work.wr_fabric_pkg.all;
use work.wishbone_pkg.all;
use work.fine_delay_pkg.all;
--use work.etherbone_pkg.all;
use work.wr_xilinx_pkg.all;

use work.synthesis_descriptor.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity svec_top is
  generic
    (
      g_with_wr_phy : integer := 1;
      g_simulation  : integer := 0
      );
  port
    (

      -------------------------------------------------------------------------
      -- Standard SVEC ports (Gennum bridge, LEDS, Etc. Do not modify
      -------------------------------------------------------------------------

      clk_20m_vcxo_i : in std_logic;    -- 20MHz VCXO clock

      clk_125m_pllref_p_i : in std_logic;  -- 125 MHz PLL reference
      clk_125m_pllref_n_i : in std_logic;

      clk_125m_gtp_p_i : in std_logic;  -- 125 MHz PLL reference
      clk_125m_gtp_n_i : in std_logic;

      rst_n_i : in std_logic;

      -- SVEC Front panel LEDs

      fp_led_line_oen_o : out std_logic_vector(1 downto 0);
      fp_led_line_o     : out std_logic_vector(1 downto 0);
      fp_led_column_o   : out std_logic_vector(3 downto 0);

      fp_gpio1_a2b_o  : out std_logic;
      fp_gpio2_a2b_o  : out std_logic;
      fp_gpio34_a2b_o : out std_logic;

      fp_gpio1_b : out std_logic;
      fp_gpio2_b : out std_logic;
      fp_gpio3_b : out std_logic;
      fp_gpio4_b : out std_logic;

      -------------------------------------------------------------------------
      -- VME Interface pins
      -------------------------------------------------------------------------

      VME_AS_n_i     : in    std_logic;
      VME_RST_n_i    : in    std_logic;
      VME_WRITE_n_i  : in    std_logic;
      VME_AM_i       : in    std_logic_vector(5 downto 0);
      VME_DS_n_i     : in    std_logic_vector(1 downto 0);
      VME_GA_i       : in    std_logic_vector(5 downto 0);
      VME_BERR_o     : inout std_logic;
      VME_DTACK_n_o  : inout std_logic;
      VME_RETRY_n_o  : out   std_logic;
      VME_RETRY_OE_o : out   std_logic;

      VME_LWORD_n_b   : inout std_logic;
      VME_ADDR_b      : inout std_logic_vector(31 downto 1);
      VME_DATA_b      : inout std_logic_vector(31 downto 0);
      VME_BBSY_n_i    : in    std_logic;
      VME_IRQ_n_o     : out   std_logic_vector(6 downto 0);
      VME_IACK_n_i    : in    std_logic;
      VME_IACKIN_n_i  : in    std_logic;
      VME_IACKOUT_n_o : out   std_logic;
      VME_DTACK_OE_o  : inout std_logic;
      VME_DATA_DIR_o  : inout std_logic;
      VME_DATA_OE_N_o : inout std_logic;
      VME_ADDR_DIR_o  : inout std_logic;
      VME_ADDR_OE_N_o : inout std_logic;

      -------------------------------------------------------------------------
      -- SFP pins
      -------------------------------------------------------------------------

      sfp_txp_o : out std_logic;
      sfp_txn_o : out std_logic;

      sfp_rxp_i : in std_logic := '0';
      sfp_rxn_i : in std_logic := '1';

      sfp_mod_def0_b    : in    std_logic;  -- detect pin
      sfp_mod_def1_b    : inout std_logic;  -- scl
      sfp_mod_def2_b    : inout std_logic;  -- sda
      sfp_rate_select_b : inout std_logic := '0';
      sfp_tx_fault_i    : in    std_logic := '0';
      sfp_tx_disable_o  : out   std_logic;
      sfp_los_i         : in    std_logic := '0';

      fmc0_prsntm2c_n_i : in std_logic;
      fmc1_prsntm2c_n_i : in std_logic;

      fmc0_scl_b : inout std_logic;
      fmc0_sda_b : inout std_logic;

      fmc1_scl_b : inout std_logic;
      fmc1_sda_b : inout std_logic;

      pll20dac_din_o    : out std_logic;
      pll20dac_sclk_o   : out std_logic;
      pll20dac_sync_n_o : out std_logic;
      pll25dac_din_o    : out std_logic;
      pll25dac_sclk_o   : out std_logic;
      pll25dac_sync_n_o : out std_logic;

      tempid_dq_b : inout std_logic;

      -------------------------------------------------------------------------
      -- Fine Delay Pins
      -------------------------------------------------------------------------

      fd0_tdc_start_p_i : in std_logic;
      fd0_tdc_start_n_i : in std_logic;

      fd0_clk_ref_p_i : in std_logic;
      fd0_clk_ref_n_i : in std_logic;

      fd0_trig_a_i         : in    std_logic;
      fd0_tdc_cal_pulse_o  : out   std_logic;
      fd0_tdc_d_b          : inout std_logic_vector(27 downto 0);
      fd0_tdc_emptyf_i     : in    std_logic;
      fd0_tdc_alutrigger_o : out   std_logic;
      fd0_tdc_wr_n_o       : out   std_logic;
      fd0_tdc_rd_n_o       : out   std_logic;
      fd0_tdc_oe_n_o       : out   std_logic;
      fd0_led_trig_o       : out   std_logic;
      fd0_tdc_start_dis_o  : out   std_logic;
      fd0_tdc_stop_dis_o   : out   std_logic;
      fd0_spi_cs_dac_n_o   : out   std_logic;
      fd0_spi_cs_pll_n_o   : out   std_logic;
      fd0_spi_cs_gpio_n_o  : out   std_logic;
      fd0_spi_sclk_o       : out   std_logic;
      fd0_spi_mosi_o       : out   std_logic;
      fd0_spi_miso_i       : in    std_logic;
      fd0_delay_len_o      : out   std_logic_vector(3 downto 0);
      fd0_delay_val_o      : out   std_logic_vector(9 downto 0);
      fd0_delay_pulse_o    : out   std_logic_vector(3 downto 0);

      fd0_dmtd_clk_o    : out std_logic;
      fd0_dmtd_fb_in_i  : in  std_logic;
      fd0_dmtd_fb_out_i : in  std_logic;

      fd0_pll_status_i : in  std_logic;
      fd0_ext_rst_n_o  : out std_logic;

      fd0_onewire_b : inout std_logic;


      fd1_tdc_start_p_i : in std_logic;
      fd1_tdc_start_n_i : in std_logic;

      fd1_clk_ref_p_i : in std_logic;
      fd1_clk_ref_n_i : in std_logic;

      fd1_trig_a_i         : in    std_logic;
      fd1_tdc_cal_pulse_o  : out   std_logic;
      fd1_tdc_d_b          : inout std_logic_vector(27 downto 0);
      fd1_tdc_emptyf_i     : in    std_logic;
      fd1_tdc_alutrigger_o : out   std_logic;
      fd1_tdc_wr_n_o       : out   std_logic;
      fd1_tdc_rd_n_o       : out   std_logic;
      fd1_tdc_oe_n_o       : out   std_logic;
      fd1_led_trig_o       : out   std_logic;
      fd1_tdc_start_dis_o  : out   std_logic;
      fd1_tdc_stop_dis_o   : out   std_logic;
      fd1_spi_cs_dac_n_o   : out   std_logic;
      fd1_spi_cs_pll_n_o   : out   std_logic;
      fd1_spi_cs_gpio_n_o  : out   std_logic;
      fd1_spi_sclk_o       : out   std_logic;
      fd1_spi_mosi_o       : out   std_logic;
      fd1_spi_miso_i       : in    std_logic;
      fd1_delay_len_o      : out   std_logic_vector(3 downto 0);
      fd1_delay_val_o      : out   std_logic_vector(9 downto 0);
      fd1_delay_pulse_o    : out   std_logic_vector(3 downto 0);

      fd1_dmtd_clk_o    : out std_logic;
      fd1_dmtd_fb_in_i  : in  std_logic;
      fd1_dmtd_fb_out_i : in  std_logic;

      fd1_pll_status_i : in  std_logic;
      fd1_ext_rst_n_o  : out std_logic;

      fd1_onewire_b : inout std_logic;

      -----------------------------------------
      -- UART
      -----------------------------------------

      uart_rxd_i : in  std_logic := '1';
      uart_txd_o : out std_logic
      );

end svec_top;

architecture rtl of svec_top is

  component xvme64x_core
    port (
      clk_i           : in  std_logic;
      rst_n_i         : in  std_logic;
      VME_AS_n_i      : in  std_logic;
      VME_RST_n_i     : in  std_logic;
      VME_WRITE_n_i   : in  std_logic;
      VME_AM_i        : in  std_logic_vector(5 downto 0);
      VME_DS_n_i      : in  std_logic_vector(1 downto 0);
      VME_GA_i        : in  std_logic_vector(5 downto 0);
      VME_BERR_o      : out std_logic;
      VME_DTACK_n_o   : out std_logic;
      VME_RETRY_n_o   : out std_logic;
      VME_RETRY_OE_o  : out std_logic;
      VME_LWORD_n_b_i : in  std_logic;
      VME_LWORD_n_b_o : out std_logic;
      VME_ADDR_b_i    : in  std_logic_vector(31 downto 1);
      VME_ADDR_b_o    : out std_logic_vector(31 downto 1);
      VME_DATA_b_i    : in  std_logic_vector(31 downto 0);
      VME_DATA_b_o    : out std_logic_vector(31 downto 0);
      VME_IRQ_n_o     : out std_logic_vector(6 downto 0);
      VME_IACKIN_n_i  : in  std_logic;
      VME_IACK_n_i    : in  std_logic;
      VME_IACKOUT_n_o : out std_logic;
      VME_DTACK_OE_o  : out std_logic;
      VME_DATA_DIR_o  : out std_logic;
      VME_DATA_OE_N_o : out std_logic;
      VME_ADDR_DIR_o  : out std_logic;
      VME_ADDR_OE_N_o : out std_logic;
      master_o        : out t_wishbone_master_out;
      master_i        : in  t_wishbone_master_in;
      irq_i           : in  std_logic;
      irq_ack_o       : out std_logic);
  end component;


  component fd_ddr_pll
    port (
      RST       : in  std_logic;
      LOCKED    : out std_logic;
      CLK_IN1_P : in  std_logic;
      CLK_IN1_N : in  std_logic;
      CLK_OUT1  : out std_logic;
      CLK_OUT2  : out std_logic);
  end component;

  component spec_serial_dac
    generic (
      g_num_data_bits  : integer;
      g_num_extra_bits : integer;
      g_num_cs_select  : integer);
    port (
      clk_i         : in  std_logic;
      rst_n_i       : in  std_logic;
      value_i       : in  std_logic_vector(g_num_data_bits-1 downto 0);
      cs_sel_i      : in  std_logic_vector(g_num_cs_select-1 downto 0);
      load_i        : in  std_logic;
      sclk_divsel_i : in  std_logic_vector(2 downto 0);
      dac_cs_n_o    : out std_logic_vector(g_num_cs_select-1 downto 0);
      dac_sclk_o    : out std_logic;
      dac_sdata_o   : out std_logic;
      xdone_o       : out std_logic);
  end component;

  component bicolor_led_ctrl
    generic (
      g_NB_COLUMN    : natural;
      g_NB_LINE      : natural;
      g_CLK_FREQ     : natural;
      g_REFRESH_RATE : natural);
    port (
      rst_n_i         : in  std_logic;
      clk_i           : in  std_logic;
      led_intensity_i : in  std_logic_vector(6 downto 0);
      led_state_i     : in  std_logic_vector((g_NB_LINE * g_NB_COLUMN * 2) - 1 downto 0);
      column_o        : out std_logic_vector(g_NB_COLUMN - 1 downto 0);
      line_o          : out std_logic_vector(g_NB_LINE - 1 downto 0);
      line_oen_o      : out std_logic_vector(g_NB_LINE - 1 downto 0));
  end component;

  signal VME_DATA_b_out                                        : std_logic_vector(31 downto 0);
  signal VME_ADDR_b_out                                        : std_logic_vector(31 downto 1);
  signal VME_LWORD_n_b_out, VME_DATA_DIR_int, VME_ADDR_DIR_int : std_logic;

  signal dac_hpll_load_p1 : std_logic;
  signal dac_dpll_load_p1 : std_logic;
  signal dac_hpll_data    : std_logic_vector(15 downto 0);
  signal dac_dpll_data    : std_logic_vector(15 downto 0);

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


  constant c_NUM_WB_MASTERS : integer := 4;
  constant c_NUM_WB_SLAVES  : integer := 2;

  constant c_MASTER_VME       : integer := 0;
  constant c_MASTER_ETHERBONE : integer := 1;

  constant c_SLAVE_FD1      : integer := 1;
  constant c_SLAVE_FD0      : integer := 0;
  constant c_SLAVE_WRCORE   : integer := 3;
  constant c_SLAVE_VIC      : integer := 2;
  constant c_DESC_SYNTHESIS : integer := 4;
  constant c_DESC_REPO_URL  : integer := 5;

  constant c_WRCORE_BRIDGE_SDB : t_sdb_bridge := f_xwb_bridge_manual_sdb(x"0003ffff", x"00030000");

  constant c_INTERCONNECT_LAYOUT : t_sdb_record_array(c_NUM_WB_MASTERS + 1 downto 0) :=
    (
      c_SLAVE_FD0      => f_sdb_embed_device(c_FD_SDB_DEVICE, x"00010000"),
      c_SLAVE_FD1      => f_sdb_embed_device(c_FD_SDB_DEVICE, x"00020000"),
      c_SLAVE_VIC      => f_sdb_embed_device(c_xwb_vic_sdb, x"00030000"),
      c_SLAVE_WRCORE   => f_sdb_embed_bridge(c_WRCORE_BRIDGE_SDB, x"00040000"),
      c_DESC_SYNTHESIS => f_sdb_embed_synthesis(c_sdb_synthesis_info),
      c_DESC_REPO_URL  => f_sdb_embed_repo_url(c_sdb_repo_url)
      );

  constant c_SDB_ADDRESS : t_wishbone_address := x"00000000";

  constant c_VIC_VECTOR_TABLE : t_wishbone_address_array(0 to 1) :=
    (0 => x"00010000",
     1 => x"00020000");

  signal cnx_master_out : t_wishbone_master_out_array(c_NUM_WB_MASTERS-1 downto 0);
  signal cnx_master_in  : t_wishbone_master_in_array(c_NUM_WB_MASTERS-1 downto 0);

  signal cnx_slave_out : t_wishbone_slave_out_array(c_NUM_WB_SLAVES-1 downto 0);
  signal cnx_slave_in  : t_wishbone_slave_in_array(c_NUM_WB_SLAVES-1 downto 0);

  signal dcm0_clk_ref_0, dcm0_clk_ref_180 : std_logic;
  signal fd0_tdc_start                    : std_logic;
  signal tdc0_data_out, tdc0_data_in      : std_logic_vector(27 downto 0);
  signal tdc0_data_oe                     : std_logic;

  signal dcm1_clk_ref_0, dcm1_clk_ref_180 : std_logic;
  signal fd1_tdc_start                    : std_logic;
  signal tdc1_data_out, tdc1_data_in      : std_logic_vector(27 downto 0);
  signal tdc1_data_oe                     : std_logic;

  signal tm_link_up         : std_logic;
  signal tm_utc             : std_logic_vector(39 downto 0);
  signal tm_cycles          : std_logic_vector(27 downto 0);
  signal tm_time_valid      : std_logic;
  signal tm_clk_aux_lock_en : std_logic_vector(1 downto 0);
  signal tm_clk_aux_locked  : std_logic_vector(1 downto 0);
  signal tm_dac_value       : std_logic_vector(23 downto 0);
  signal tm_dac_wr          : std_logic_vector(1 downto 0);

  signal ddr0_pll_reset                  : std_logic;
  signal ddr0_pll_locked, fd0_pll_status : std_logic;
  signal ddr1_pll_reset                  : std_logic;
  signal ddr1_pll_locked, fd1_pll_status : std_logic;

  signal wrc_scl_out, wrc_scl_in, wrc_sda_out, wrc_sda_in : std_logic;
  signal fd0_scl_out, fd0_scl_in, fd0_sda_out, fd0_sda_in : std_logic;
  signal fd1_scl_out, fd1_scl_in, fd1_sda_out, fd1_sda_in : std_logic;
  signal sfp_scl_out, sfp_scl_in, sfp_sda_out, sfp_sda_in : std_logic;
  signal wrc_owr_en, wrc_owr_in                           : std_logic_vector(1 downto 0);
  signal fd0_owr_en, fd0_owr_in                           : std_logic;
  signal fd1_owr_en, fd1_owr_in                           : std_logic;

  signal fd0_irq, fd1_irq : std_logic;

  signal pllout_clk_sys       : std_logic;
  signal pllout_clk_dmtd      : std_logic;
  signal pllout_clk_fb_pllref : std_logic;
  signal pllout_clk_fb_dmtd   : std_logic;

  signal clk_20m_vcxo_buf : std_logic;
  signal clk_125m_pllref  : std_logic;
  signal clk_125m_gtp     : std_logic;
  signal clk_sys          : std_logic;
  signal clk_dmtd         : std_logic;

  signal local_reset_n : std_logic;

  signal vme_master_out : t_wishbone_master_out;
  signal vme_master_in  : t_wishbone_master_in;

  signal pins : std_logic_vector(31 downto 0);
  signal pps  : std_logic;

  signal vic_master_irq : std_logic;

  function f_int2bool (x : integer) return boolean is
  begin
    if(x = 0) then
      return false;
    else
      return true;
    end if;
  end f_int2bool;

  function f_resize_slv (x : std_logic_vector; len : integer) return std_logic_vector is
    variable tmp : std_logic_vector(len-1 downto 0);
  begin
    if(len > x'length) then
      tmp(x'length-1 downto 0)   := x;
      tmp(len-1 downto x'length) := (others => '0');
    elsif(len < x'length) then
      tmp := x(len-1 downto 0);
    else
      tmp := x;
    end if;
    return tmp;
  end f_resize_slv;

  signal etherbone_rst_n   : std_logic;
  signal etherbone_src_out : t_wrf_source_out;
  signal etherbone_src_in  : t_wrf_source_in;
  signal etherbone_snk_out : t_wrf_sink_out;
  signal etherbone_snk_in  : t_wrf_sink_in;
  signal etherbone_cfg_in  : t_wishbone_slave_in;
  signal etherbone_cfg_out : t_wishbone_slave_out;

  attribute buffer_type                    : string;  --" {bufgdll | ibufg | bufgp | ibuf | bufr | none}";
  attribute buffer_type of clk_125m_pllref : signal is "BUFG";

  signal powerup_reset_cnt : unsigned(7 downto 0) := "00000000";
  signal powerup_rst_n     : std_logic            := '0';
  signal sys_locked        : std_logic;

  signal led_state        : std_logic_vector(15 downto 0);
  signal pps_led, pps_ext : std_logic;

  signal led_link   : std_logic;
  signal led_act    : std_logic;
  signal vme_access : std_logic;

  signal fd0_dbg : std_logic_vector(7 downto 0);
  
begin

  p_powerup_reset : process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      if(VME_RST_n_i = '0' or rst_n_i = '0') then
        powerup_rst_n <= '0';
      elsif sys_locked = '1' then
        if(powerup_reset_cnt = "11111111") then
          powerup_rst_n <= '1';
        else
          powerup_rst_n     <= '0';
          powerup_reset_cnt <= powerup_reset_cnt + 1;
        end if;
      else
        powerup_rst_n     <= '0';
        powerup_reset_cnt <= "00000000";
      end if;
    end if;
  end process;

  U_Buf_CLK_GTP : IBUFDS
    generic map (
      DIFF_TERM    => true,
      IBUF_LOW_PWR => false  -- Low power (TRUE) vs. performance (FALSE) setting for referenced
      )
    port map (
      O  => clk_125m_gtp,
      I  => clk_125m_gtp_p_i,
      IB => clk_125m_gtp_n_i
      );


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
      LOCKED   => sys_locked,
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
      CLKOUT0_DIVIDE     => 16,         -- 62.5 MHz
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKOUT1_DIVIDE     => 16,         -- 62.5 MHz
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
      CLKOUT1  => open,                 --pllout_clk_sys,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => open,
      RST      => '0',
      CLKFBIN  => pllout_clk_fb_dmtd,
      CLKIN    => clk_20m_vcxo_buf);

--  rst_n_a <= VME_RST_n_i and rst_n_i;
  U_Sync_Reset : gc_sync_ffs
    port map (
      clk_i    => clk_sys,
      rst_n_i  => '1',
      data_i   => powerup_rst_n,
      synced_o => local_reset_n);

  U_Buf_CLK_PLL : IBUFGDS
    generic map (
      DIFF_TERM    => true,
      IBUF_LOW_PWR => true  -- Low power (TRUE) vs. performance (FALSE) setting for referenced
      )
    port map (
      O  => clk_125m_pllref,            -- Buffer output
      I  => clk_125m_pllref_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => clk_125m_pllref_n_i  -- Diff_n buffer input (connect directly to top-level port)
      );


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


  U_VME_Core : xvme64x_core
    port map (
      clk_i           => clk_sys,
      rst_n_i         => powerup_rst_n,
      VME_AS_n_i      => VME_AS_n_i,
      VME_RST_n_i     => powerup_rst_n,
      VME_WRITE_n_i   => VME_WRITE_n_i,
      VME_AM_i        => VME_AM_i,
      VME_DS_n_i      => VME_DS_n_i,
      VME_GA_i        => VME_GA_i,
      VME_BERR_o      => VME_BERR_o,
      VME_DTACK_n_o   => VME_DTACK_n_o,
      VME_RETRY_n_o   => VME_RETRY_n_o,
      VME_RETRY_OE_o  => VME_RETRY_OE_o,
      VME_LWORD_n_b_i => VME_LWORD_n_b,
      VME_LWORD_n_b_o => VME_LWORD_n_b_out,
      VME_ADDR_b_i    => VME_ADDR_b,
      VME_DATA_b_o    => VME_DATA_b_out,
      VME_ADDR_b_o    => VME_ADDR_b_out,
      VME_DATA_b_i    => VME_DATA_b,
      VME_IRQ_n_o     => VME_IRQ_n_o,
      VME_IACK_n_i    => VME_IACK_n_i,
      VME_IACKIN_n_i  => VME_IACKIN_n_i,
      VME_IACKOUT_n_o => VME_IACKOUT_n_o,
      VME_DTACK_OE_o  => VME_DTACK_OE_o,
      VME_DATA_DIR_o  => VME_DATA_DIR_int,
      VME_DATA_OE_N_o => VME_DATA_OE_N_o,
      VME_ADDR_DIR_o  => VME_ADDR_DIR_int,
      VME_ADDR_OE_N_o => VME_ADDR_OE_N_o,
      master_o        => vme_master_out,
      master_i        => vme_master_in,
      irq_i           => vic_master_irq);

  VME_DATA_b    <= VME_DATA_b_out    when VME_DATA_DIR_int = '1' else (others => 'Z');
  VME_ADDR_b    <= VME_ADDR_b_out    when VME_ADDR_DIR_int = '1' else (others => 'Z');
  VME_LWORD_n_b <= VME_LWORD_n_b_out when VME_ADDR_DIR_int = '1' else 'Z';

  VME_ADDR_DIR_o <= VME_ADDR_DIR_int;
  VME_DATA_DIR_o <= VME_DATA_DIR_int;

  cnx_slave_in(c_MASTER_VME) <= vme_master_out;
  vme_master_in              <= cnx_slave_out(c_MASTER_VME);

  -- Tristates for FMC0 EEPROM: fixme: wire to WRCore
  fmc0_scl_b <= '0' when (fd0_scl_out = '0') else 'Z';
  fmc0_sda_b <= '0' when (fd0_sda_out = '0') else 'Z';
--  wrc_scl_in <= fmc_scl_b;
--  wrc_sda_in <= fmc_sda_b;
  fd0_scl_in <= fmc0_scl_b;
  fd0_sda_in <= fmc0_sda_b;

  -- Tristates for FMC0 EEPROM: fixme: wire to WRCore
  fmc1_scl_b <= '0' when (fd1_scl_out = '0') else 'Z';
  fmc1_sda_b <= '0' when (fd1_sda_out = '0') else 'Z';
--  wrc_scl_in <= fmc_scl_b;
--  wrc_sda_in <= fmc_sda_b;
  fd1_scl_in <= fmc1_scl_b;
  fd1_sda_in <= fmc1_sda_b;

  -- Tristates for SFP EEPROM
  sfp_mod_def1_b <= '0' when sfp_scl_out = '0' else 'Z';
  sfp_mod_def2_b <= '0' when sfp_sda_out = '0' else 'Z';
  sfp_scl_in     <= sfp_mod_def1_b;
  sfp_sda_in     <= sfp_mod_def2_b;

  tempid_dq_b   <= '0' when wrc_owr_en(0) = '1' else 'Z';
  wrc_owr_in(0) <= tempid_dq_b;

  U_WR_CORE : xwr_core
    generic map (
      g_simulation                => g_simulation,
      g_phys_uart                 => true,
      g_virtual_uart              => true,
      g_with_external_clock_input => false,
      g_aux_clks                  => 2,
      g_interface_mode            => PIPELINED,
      g_address_granularity       => BYTE,
      g_softpll_enable_debugger   => false,
      g_dpram_initf               => "wrc-release.ram")
    port map (
      clk_sys_i    => clk_sys,
      clk_dmtd_i   => clk_dmtd,
      clk_ref_i    => clk_125m_pllref,
      clk_aux_i(0) => dcm0_clk_ref_0,
      clk_aux_i(1) => dcm1_clk_ref_0,
      rst_n_i      => local_reset_n,

      dac_hpll_load_p1_o => dac_hpll_load_p1,
      dac_hpll_data_o    => dac_hpll_data,
      dac_dpll_load_p1_o => dac_dpll_load_p1,
      dac_dpll_data_o    => dac_dpll_data,

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

      led_link_o => led_link,
      led_act_o  => led_act,

      scl_o     => wrc_scl_out,
      scl_i     => wrc_scl_in,
      sda_o     => wrc_sda_out,
      sda_i     => wrc_sda_in,
      sfp_scl_o => sfp_scl_out,
      sfp_scl_i => sfp_scl_in,
      sfp_sda_o => sfp_sda_out,
      sfp_sda_i => sfp_sda_in,
      sfp_det_i => sfp_mod_def0_b,

      uart_rxd_i => uart_rxd_i,
      uart_txd_o => uart_txd_o,

      owr_en_o => wrc_owr_en,
      owr_i    => wrc_owr_in,

      slave_i => cnx_master_out(c_SLAVE_WRCORE),
      slave_o => cnx_master_in(c_SLAVE_WRCORE),

      --aux_master_o => etherbone_cfg_in,
      --aux_master_i => etherbone_cfg_out,

      --wrf_src_o => etherbone_snk_in,
      --wrf_src_i => etherbone_snk_out,
      --wrf_snk_o => etherbone_src_in,
      --wrf_snk_i => etherbone_src_out,

      btn1_i => '0',
      btn2_i => '0',

      tm_link_up_o         => tm_link_up,
      tm_dac_value_o       => tm_dac_value,
      tm_dac_wr_o          => tm_dac_wr,
      tm_clk_aux_lock_en_i => tm_clk_aux_lock_en,
      tm_clk_aux_locked_o  => tm_clk_aux_locked,
      tm_time_valid_o      => tm_time_valid,
      tm_tai_o             => tm_utc,
      tm_cycles_o          => tm_cycles,

      rst_aux_n_o => etherbone_rst_n,
      pps_p_o     => pps,
      pps_led_o   => pps_led
      );

  U_DAC_Helper : spec_serial_dac
    generic map (
      g_num_data_bits  => 16,
      g_num_extra_bits => 8,
      g_num_cs_select  => 1)
    port map (
      clk_i         => clk_sys,
      rst_n_i       => local_reset_n,
      value_i       => dac_hpll_data,
      cs_sel_i      => "1",
      load_i        => dac_hpll_load_p1,
      sclk_divsel_i => "010",
      dac_cs_n_o(0) => pll20dac_sync_n_o,
      dac_sclk_o    => pll20dac_sclk_o,
      dac_sdata_o   => pll20dac_din_o,
      xdone_o       => open);

  U_DAC_Main : spec_serial_dac
    generic map (
      g_num_data_bits  => 16,
      g_num_extra_bits => 8,
      g_num_cs_select  => 1)
    port map (
      clk_i         => clk_sys,
      rst_n_i       => local_reset_n,
      value_i       => dac_dpll_data,
      cs_sel_i      => "1",
      load_i        => dac_dpll_load_p1,
      sclk_divsel_i => "010",
      dac_cs_n_o(0) => pll25dac_sync_n_o,
      dac_sclk_o    => pll25dac_sclk_o,
      dac_sdata_o   => pll25dac_din_o,
      xdone_o       => open);

  --U_Etherbone : eb_slave_core
  --  generic map (
  --    g_sdb_address => f_resize_slv(c_sdb_address, 64))
  --  port map (
  --    clk_i       => clk_sys,
  --    nRst_i      => etherbone_rst_n,
  --    src_o       => etherbone_src_out,
  --    src_i       => etherbone_src_in,
  --    snk_o       => etherbone_snk_out,
  --    snk_i       => etherbone_snk_in,
  --    cfg_slave_o => etherbone_cfg_out,
  --    cfg_slave_i => etherbone_cfg_in,
  --    master_o    => cnx_slave_in(c_MASTER_ETHERBONE),
  --    master_i    => cnx_slave_out(c_MASTER_ETHERBONE));

  cnx_slave_in(c_MASTER_ETHERBONE).cyc <= '0';

  U_Intercon : xwb_sdb_crossbar
    generic map (
      g_num_masters => c_NUM_WB_SLAVES,
      g_num_slaves  => c_NUM_WB_MASTERS,
      g_registered  => true,
      g_wraparound  => true,
      g_layout      => c_INTERCONNECT_LAYOUT,
      g_sdb_addr    => c_SDB_ADDRESS)
    port map (
      clk_sys_i => clk_sys,
      rst_n_i   => local_reset_n,
      slave_i   => cnx_slave_in,
      slave_o   => cnx_slave_out,
      master_i  => cnx_master_in,
      master_o  => cnx_master_out);

  U_VIC : xwb_vic
    generic map (
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_num_interrupts      => 2,
      g_init_vectors        => c_VIC_VECTOR_TABLE)
    port map (
      clk_sys_i    => clk_sys,
      rst_n_i      => local_reset_n,
      slave_i      => cnx_master_out(c_SLAVE_VIC),
      slave_o      => cnx_master_in(c_SLAVE_VIC),
      irqs_i(0)    => fd0_irq,
      irqs_i(1)    => fd1_irq,
      irq_master_o => vic_master_irq);

  gen_with_phy : if(g_with_wr_phy /= 0) generate

    U_GTP : wr_gtp_phy_spartan6
      generic map (
        g_enable_ch0 => 0,
        g_enable_ch1 => 1,
        g_simulation => g_simulation)
      port map (
        gtp_clk_i          => clk_125m_gtp,
        ch0_ref_clk_i      => clk_125m_pllref,
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
        ch1_loopen_i       => '0',      --phy_loopen,
        pad_txn0_o         => open,
        pad_txp0_o         => open,
        pad_rxn0_i         => '0',
        pad_rxp0_i         => '0',
        pad_txn1_o         => sfp_txn_o,
        pad_txp1_o         => sfp_txp_o,
        pad_rxn1_i         => sfp_rxn_i,
        pad_rxp1_i         => sfp_rxp_i);

  end generate gen_with_phy;

-------------------------------------------------------------------------------
-- FINE DELAY 0 INSTANTIATION
-------------------------------------------------------------------------------

  cmp_fd_tdc_start0 : IBUFDS
    generic map (
      DIFF_TERM    => true,
      IBUF_LOW_PWR => false  -- Low power (TRUE) vs. performance (FALSE) setting for referenced
      )
    port map (
      O  => fd0_tdc_start,              -- Buffer output
      I  => fd0_tdc_start_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => fd0_tdc_start_n_i  -- Diff_n buffer input (connect directly to top-level port)
      );

  U_DDR_PLL0 : fd_ddr_pll
    port map (
      RST       => ddr0_pll_reset,
      LOCKED    => ddr0_pll_locked,
      CLK_IN1_P => fd0_clk_ref_p_i,
      CLK_IN1_N => fd0_clk_ref_n_i,
      CLK_OUT1  => dcm0_clk_ref_0,
      CLK_OUT2  => dcm0_clk_ref_180);

  ddr0_pll_reset <= not fd0_pll_status_i;
  fd0_pll_status <= fd0_pll_status_i and ddr0_pll_locked;

  U_FineDelay_Core0 : fine_delay_core
    generic map (
      g_with_wr_core        => true,
      g_simulation          => f_int2bool(g_simulation),
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE)
    port map (
      clk_ref_0_i   => dcm0_clk_ref_0,
      clk_ref_180_i => dcm0_clk_ref_180,
      clk_sys_i     => clk_sys,
      clk_dmtd_i    => clk_dmtd,
      rst_n_i       => local_reset_n,
      dcm_reset_o   => open,
      dcm_locked_i  => ddr0_pll_locked,

      trig_a_i          => fd0_trig_a_i,
      tdc_cal_pulse_o   => fd0_tdc_cal_pulse_o,
      tdc_start_i       => fd0_tdc_start,
      dmtd_fb_in_i      => fd0_dmtd_fb_in_i,
      dmtd_fb_out_i     => fd0_dmtd_fb_out_i,
      dmtd_samp_o       => fd0_dmtd_clk_o,
      led_trig_o        => fd0_led_trig_o,
      ext_rst_n_o       => fd0_ext_rst_n_o,
      pll_status_i      => fd0_pll_status,
      acam_d_o          => tdc0_data_out,
      acam_d_i          => tdc0_data_in,
      acam_d_oen_o      => tdc0_data_oe,
      acam_emptyf_i     => fd0_tdc_emptyf_i,
      acam_alutrigger_o => fd0_tdc_alutrigger_o,
      acam_wr_n_o       => fd0_tdc_wr_n_o,
      acam_rd_n_o       => fd0_tdc_rd_n_o,
      acam_start_dis_o  => fd0_tdc_start_dis_o,
      acam_stop_dis_o   => fd0_tdc_stop_dis_o,
      spi_cs_dac_n_o    => fd0_spi_cs_dac_n_o,
      spi_cs_pll_n_o    => fd0_spi_cs_pll_n_o,
      spi_cs_gpio_n_o   => fd0_spi_cs_gpio_n_o,
      spi_sclk_o        => fd0_spi_sclk_o,
      spi_mosi_o        => fd0_spi_mosi_o,
      spi_miso_i        => fd0_spi_miso_i,

      delay_len_o   => fd0_delay_len_o,
      delay_val_o   => fd0_delay_val_o,
      delay_pulse_o => fd0_delay_pulse_o,

      tm_link_up_i         => tm_link_up,
      tm_time_valid_i      => tm_time_valid,
      tm_cycles_i          => tm_cycles,
      tm_utc_i             => tm_utc,
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
      fmc_present_n_i => fmc0_prsntm2c_n_i,

      wb_adr_i   => cnx_master_out(c_SLAVE_FD0).adr,
      wb_dat_i   => cnx_master_out(c_SLAVE_FD0).dat,
      wb_dat_o   => cnx_master_in(c_SLAVE_FD0).dat,
      wb_sel_i   => cnx_master_out(c_SLAVE_FD0).sel,
      wb_cyc_i   => cnx_master_out(c_SLAVE_FD0).cyc,
      wb_stb_i   => cnx_master_out(c_SLAVE_FD0).stb,
      wb_we_i    => cnx_master_out(c_SLAVE_FD0).we,
      wb_ack_o   => cnx_master_in(c_SLAVE_FD0).ack,
      wb_stall_o => cnx_master_in(c_SLAVE_FD0).stall,
      wb_irq_o   => fd0_irq,
      dbg_o      => fd0_dbg);

  cnx_master_in(c_SLAVE_FD0).err <= '0';
  cnx_master_in(c_SLAVE_FD0).rty <= '0';


-- tristate buffer for the TDC data bus:
  fd0_tdc_d_b    <= tdc0_data_out when tdc0_data_oe = '1' else (others => 'Z');
  fd0_tdc_oe_n_o <= '1';
  tdc0_data_in   <= fd0_tdc_d_b;

  fd0_onewire_b <= '0' when fd0_owr_en = '1' else 'Z';
  fd0_owr_in    <= fd0_onewire_b;


-------------------------------------------------------------------------------
-- FINE DELAY 1 INSTANTIATION
-------------------------------------------------------------------------------

  cmp_fd_tdc_start1 : IBUFDS
    generic map (
      DIFF_TERM    => true,
      IBUF_LOW_PWR => false  -- Low power (TRUE) vs. performance (FALSE) setting for referenced
      )
    port map (
      O  => fd1_tdc_start,              -- Buffer output
      I  => fd1_tdc_start_p_i,  -- Diff_p buffer input (connect directly to top-level port)
      IB => fd1_tdc_start_n_i  -- Diff_n buffer input (connect directly to top-level port)
      );

  U_DDR_PLL1 : fd_ddr_pll
    port map (
      RST       => ddr1_pll_reset,
      LOCKED    => ddr1_pll_locked,
      CLK_IN1_P => fd1_clk_ref_p_i,
      CLK_IN1_N => fd1_clk_ref_n_i,
      CLK_OUT1  => dcm1_clk_ref_0,
      CLK_OUT2  => dcm1_clk_ref_180);

  ddr1_pll_reset <= not fd1_pll_status_i;
  fd1_pll_status <= fd1_pll_status_i and ddr1_pll_locked;

  U_FineDelay_Core1 : fine_delay_core
    generic map (
      g_with_wr_core        => true,
      g_simulation          => f_int2bool(g_simulation),
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE)
    port map (
      clk_ref_0_i   => dcm1_clk_ref_0,
      clk_ref_180_i => dcm1_clk_ref_180,
      clk_sys_i     => clk_sys,
      clk_dmtd_i    => clk_dmtd,
      rst_n_i       => local_reset_n,
      dcm_reset_o   => open,
      dcm_locked_i  => ddr1_pll_locked,

      trig_a_i          => fd1_trig_a_i,
      tdc_cal_pulse_o   => fd1_tdc_cal_pulse_o,
      tdc_start_i       => fd1_tdc_start,
      dmtd_fb_in_i      => fd1_dmtd_fb_in_i,
      dmtd_fb_out_i     => fd1_dmtd_fb_out_i,
      dmtd_samp_o       => fd1_dmtd_clk_o,
      led_trig_o        => fd1_led_trig_o,
      ext_rst_n_o       => fd1_ext_rst_n_o,
      pll_status_i      => fd1_pll_status,
      acam_d_o          => tdc1_data_out,
      acam_d_i          => tdc1_data_in,
      acam_d_oen_o      => tdc1_data_oe,
      acam_emptyf_i     => fd1_tdc_emptyf_i,
      acam_alutrigger_o => fd1_tdc_alutrigger_o,
      acam_wr_n_o       => fd1_tdc_wr_n_o,
      acam_rd_n_o       => fd1_tdc_rd_n_o,
      acam_start_dis_o  => fd1_tdc_start_dis_o,
      acam_stop_dis_o   => fd1_tdc_stop_dis_o,
      spi_cs_dac_n_o    => fd1_spi_cs_dac_n_o,
      spi_cs_pll_n_o    => fd1_spi_cs_pll_n_o,
      spi_cs_gpio_n_o   => fd1_spi_cs_gpio_n_o,
      spi_sclk_o        => fd1_spi_sclk_o,
      spi_mosi_o        => fd1_spi_mosi_o,
      spi_miso_i        => fd1_spi_miso_i,

      delay_len_o   => fd1_delay_len_o,
      delay_val_o   => fd1_delay_val_o,
      delay_pulse_o => fd1_delay_pulse_o,

      tm_link_up_i         => tm_link_up,
      tm_time_valid_i      => tm_time_valid,
      tm_cycles_i          => tm_cycles,
      tm_utc_i             => tm_utc,
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
      fmc_present_n_i => fmc1_prsntm2c_n_i,

      wb_adr_i   => cnx_master_out(c_SLAVE_FD1).adr,
      wb_dat_i   => cnx_master_out(c_SLAVE_FD1).dat,
      wb_dat_o   => cnx_master_in(c_SLAVE_FD1).dat,
      wb_sel_i   => cnx_master_out(c_SLAVE_FD1).sel,
      wb_cyc_i   => cnx_master_out(c_SLAVE_FD1).cyc,
      wb_stb_i   => cnx_master_out(c_SLAVE_FD1).stb,
      wb_we_i    => cnx_master_out(c_SLAVE_FD1).we,
      wb_ack_o   => cnx_master_in(c_SLAVE_FD1).ack,
      wb_stall_o => cnx_master_in(c_SLAVE_FD1).stall,
      wb_irq_o   => fd1_irq);

  cnx_master_in(c_SLAVE_FD1).err <= '0';
  cnx_master_in(c_SLAVE_FD1).rty <= '0';

-- tristate buffer for the TDC data bus:
  fd1_tdc_d_b    <= tdc1_data_out when tdc1_data_oe = '1' else (others => 'Z');
  fd1_tdc_oe_n_o <= '1';
  tdc1_data_in   <= fd1_tdc_d_b;

  fd1_onewire_b <= '0' when fd1_owr_en = '1' else 'Z';
  fd1_owr_in    <= fd1_onewire_b;

  U_LED_Controller : bicolor_led_ctrl
    generic map(
      g_NB_COLUMN    => 4,
      g_NB_LINE      => 2,
      g_CLK_FREQ     => 62500000,       -- in Hz
      g_REFRESH_RATE => 250             -- in Hz
      )
    port map(
      rst_n_i => local_reset_n,
      clk_i   => clk_sys,

      led_intensity_i => "1100100",     -- in %

      led_state_i => led_state,

      column_o   => fp_led_column_o,
      line_o     => fp_led_line_o,
      line_oen_o => fp_led_line_oen_o
      );

  U_Drive_VME_Access_Led : gc_extend_pulse
    generic map (
      g_width => 5000000)
    port map (
      clk_i      => clk_sys,
      rst_n_i    => local_reset_n,
      pulse_i    => cnx_slave_in(c_MASTER_VME).cyc,
      extended_o => vme_access);

  U_Drive_PPS : gc_extend_pulse
    generic map (
      g_width => 5000000)
    port map (
      clk_i      => clk_125m_pllref,
      rst_n_i    => local_reset_n,
      pulse_i    => pps,
      extended_o => pps_ext);

  -- Drive the front panel LEDs:

  -- LED 1: WR Link status
  led_state(6) <= led_link;
  led_state(7) <= '0';

  -- LED 2: WR Link activity status
  led_state(4) <= led_act;
  led_state(5) <= '0';

  -- LED 3: WR PPS blink
  led_state(2) <= pps_ext;
  led_state(3) <= '0';

  -- LED 4: WR Time validity
  led_state(0) <= tm_time_valid;
  led_state(1) <= '0';

  -- LED 5: VME access
  led_state(14) <= vme_access;
  led_state(15) <= '0';

  -- LED 6: FD0 locked to WR
  led_state(12) <= tm_clk_aux_locked(0);
  led_state(13) <= '0';

  -- LED 6: FD1 locked to WR
  led_state(10) <= tm_clk_aux_locked(1);
  led_state(11) <= '0';

  led_state(8) <= '0';
  led_state(9) <= '0';

  -- The SFP is permanently enabled.
  sfp_tx_disable_o <= '0';

  -- Debug signals assignments (FP lemos)

  fp_gpio1_a2b_o  <= '1';
  fp_gpio2_a2b_o  <= '1';
  fp_gpio34_a2b_o <= '1';

  fp_gpio1_b <= fd0_dbg(0);
  fp_gpio2_b <= fd0_dbg(1);
  fp_gpio3_b <= fd0_dbg(2);
  fp_gpio4_b <= fd0_dbg(3);
  
  
  
end rtl;


