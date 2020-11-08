-------------------------------------------------------------------------------
-- Title      : Fine Delay VHDL Core (top level block)
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fine_delay_core.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2014-03-24
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: See Implementation manual.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2011 CERN / BE-CO-HT
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Fsoundation; 
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;
use work.genram_pkg.all;
use work.wishbone_pkg.all;
use work.fd_main_wbgen2_pkg.all;
use work.fine_delay_pkg.all;

entity fine_delay_core is
  generic (
    -- when true, the FD core can take its' internal timebase from an
    -- associated White Rabbit core
    g_with_wr_core : boolean := false;

    -- when true, some timeouts are reduced to speed up simulations
    g_simulation : boolean := false;

    -- when true, the card does not operate as a Delay, but instead
    -- provides direct output from the TDC and direct inputs to the channel
    -- drivers.
    g_with_direct_timestamp_io : boolean := false;

    -- Wishbone slave settings
    g_interface_mode      : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity : t_wishbone_address_granularity := WORD;

    g_with_debug_output : boolean := false;

    -- index of the slot the core is assigned to, written to
    -- FMC_SLOT_ID register
    g_fmc_slot_id : integer := 0
    );
  port (

    ---------------------------------------------------------------------------
    -- Clocks & Triggers
    ---------------------------------------------------------------------------

    -- 125 MHz FMC reference clock (from AD9516)
    clk_ref_0_i   : in std_logic;
    -- 180deg phase shifted reference clock
    clk_ref_180_i : in std_logic;

    -- System clock. Clk_sys_i frequency must be lower than the one of clk_ref_i.
    clk_sys_i : in std_logic;

    -- DMTD offset clock (125.x MHz) used for calibration
    clk_dmtd_i : in std_logic;

    -- System reset (clk_sys_i domain)
    rst_n_i : in std_logic;

    -- Reference reset output (for FPGA DCM/PLLs)
    dcm_reset_o  : out std_logic;
    dcm_locked_i : in  std_logic;

    -- asynchronous TDC trigger (for coarse timestamping)
    trig_a_i : in std_logic;

    -- calibration mode TDC start signal / DMTD trigger waveform
    tdc_cal_pulse_o : out std_logic;

    -- TDC start signal (copy)
    tdc_start_i : in std_logic;

    -- DMTD insertion delay calibration signals:

    -- Sampled pattern (input side)
    dmtd_fb_in_i : in std_logic;

    -- Sampled pattern (output side)
    dmtd_fb_out_i : in std_logic;

    -- Sampling clock
    dmtd_samp_o : out std_logic;

    -- LED indicating trigger pulses
    led_trig_o : out std_logic;

    -- board reset
    ext_rst_n_o : out std_logic;

    -- PLL lock status
    pll_status_i : in std_logic;

    ---------------------------------------------------------------------------
    -- ACAM TDC-GPX signals (all asynchronous)
    ---------------------------------------------------------------------------

    -- data bus (bidirectional, put the tristates in the top entity)
    acam_d_o     : out std_logic_vector(27 downto 0);
    acam_d_i     : in  std_logic_vector(27 downto 0);
    acam_d_oen_o : out std_logic;

    -- TDC FIFO empty flag
    acam_emptyf_i     : in  std_logic;
    -- TDC FIFO load level flag
    acam_alutrigger_o : out std_logic;

    -- TDC chip select/write/read
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
    -- WhiteRabbit time/frequency sync (see WR Core documentation)
    ---------------------------------------------------------------------------

    tm_link_up_i         : in  std_logic;
    tm_time_valid_i      : in  std_logic;
    tm_cycles_i          : in  std_logic_vector(27 downto 0);
    tm_utc_i             : in  std_logic_vector(39 downto 0);
    tm_clk_aux_lock_en_o : out std_logic;
    tm_clk_aux_locked_i  : in  std_logic;
    tm_clk_dmtd_locked_i : in  std_logic;
    tm_dac_value_i       : in  std_logic_vector(23 downto 0);
    tm_dac_wr_i          : in  std_logic;

    ---------------------------------------------------------------------------
    -- Temeperature sensor (1-wire)
    ---------------------------------------------------------------------------

    owr_en_o : out std_logic;
    owr_i    : in  std_logic;

    ---------------------------------------------------------------------------
    -- Misc signals: I2C EEPROM, FMC presence, I/O calibration
    ---------------------------------------------------------------------------

    i2c_scl_o     : out std_logic;
    i2c_scl_oen_o : out std_logic;
    i2c_scl_i     : in  std_logic;
    i2c_sda_o     : out std_logic;
    i2c_sda_oen_o : out std_logic;
    i2c_sda_i     : in  std_logic;

    fmc_present_n_i : in std_logic;

    idelay_inc_o : out std_logic;
    idelay_cal_o : out std_logic;
    idelay_ce_o : out std_logic;
    idelay_rst_o : out std_logic;


    ---------------------------------------------------------------------------
    -- Wishbone slave (classic/pipelined)
    ---------------------------------------------------------------------------

    wb_adr_i   : in  std_logic_vector(c_wishbone_address_width-1 downto 0);
    wb_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_sel_i   : in  std_logic_vector((c_wishbone_data_width+7)/8-1 downto 0);
    wb_cyc_i   : in  std_logic;
    wb_stb_i   : in  std_logic;
    wb_we_i    : in  std_logic;
    wb_ack_o   : out std_logic;
    wb_stall_o : out std_logic;
    wb_irq_o   : out std_logic;

    ---------------------------------------------------------------------------
    -- Input/Output timestamp I/O
    ---------------------------------------------------------------------------

    tdc_seconds_o : out std_logic_vector(39 downto 0);
    tdc_cycles_o  : out std_logic_vector(27 downto 0);
    tdc_frac_o    : out std_logic_vector(11 downto 0);
    tdc_valid_o   : out std_logic;

    outx_seconds_i : in std_logic_vector(40 * 4 - 1 downto 0) := f_gen_dummy_vec('0', 40 * 4);
    outx_cycles_i  : in std_logic_vector(28 * 4 - 1 downto 0) := f_gen_dummy_vec('0', 28 * 4);
    outx_frac_i    : in std_logic_vector(12 * 4 - 1 downto 0) := f_gen_dummy_vec('0', 12 * 4);
    outx_valid_i   : in std_logic_vector(3 downto 0)          := x"0";

    dbg_o : out std_logic_vector(7 downto 0)
    );

end fine_delay_core;

architecture rtl of fine_delay_core is

  type t_dly_array is array (integer range <>) of std_logic_vector(9 downto 0);
  type t_timestamp_array is array(integer range <>) of t_fd_timestamp;

  constant c_TIMESTAMP_TOTAL_BITS : integer := c_TIMESTAMP_FRAC_BITS + c_TIMESTAMP_COARSE_BITS + c_TIMESTAMP_UTC_BITS;

  constant c_cnx_base_addr : t_wishbone_address_array(5 downto 0) :=
    (x"00000000",                       -- Base regs
     x"00000040",                       -- Out 1
     x"00000080",
     x"000000c0",
     x"00000100",                       -- Out 4
     x"00000140"                        -- 1Wire
     );

  constant c_cnx_base_mask : t_wishbone_address_array(5 downto 0) :=
    (x"000003c0",
     x"000003c0",
     x"000003c0",
     x"000003c0",
     x"000003c0",
     x"000003c0");

  function f_select_spi_rate return integer is
  begin
    if(g_simulation) then
      return 1;
    else
      return 8;
    end if;
  end f_select_spi_rate;

  signal tag_frac   : std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);
  signal tag_coarse : std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
  signal tag_utc    : std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
  signal tag_dbg    : std_logic_vector(31 downto 0);
  signal tag_valid  : std_logic;

  signal rbuf_mux_ts                           : t_timestamp_array(0 to 4);
  signal rbuf_mux_valid, rbuf_mux_valid_masked : std_logic_vector(4 downto 0);
  signal rbuf_in_ts                            : t_fd_timestamp;
  signal rbuf_source                           : std_logic_vector(3 downto 0);
  signal rbuf_valid                            : std_logic;

  signal rbuf_mux_d : std_logic_vector(5*c_TIMESTAMP_TOTAL_BITS-1 downto 0);
  signal rbuf_mux_q : std_logic_vector(c_TIMESTAMP_TOTAL_BITS-1 downto 0);


  signal master_csync_p1     : std_logic;
  signal master_csync_utc    : std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
  signal master_csync_coarse : std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);

  signal rst_n_sys, rst_n_ref : std_logic;

  signal tsbcr_read_ack, fid_read_ack : std_logic;
  signal irq_rbuf, irq_spll, irq_sync : std_logic;

  type t_delay_channel is record
    idle           : std_logic;
    pulse0, pulse1 : std_logic;
    value          : std_logic_vector(9 downto 0);
    load           : std_logic;
    load_done      : std_logic;
    tag            : t_fd_timestamp;
    dbg            : std_logic_vector(7 downto 0);
  end record;

  type t_delay_channel_array is array (integer range <>) of t_delay_channel;

  signal channels : t_delay_channel_array(3 downto 0);

  signal chx_delay_idle : std_logic_vector(3 downto 0);

  signal cnx_out : t_wishbone_master_out_array(0 to 5);
  signal cnx_in  : t_wishbone_master_in_array(0 to 5);

  signal slave_in  : t_wishbone_slave_in_array(0 to 0);
  signal slave_out : t_wishbone_slave_out_array(0 to 0);

  signal regs_fromwb     : t_fd_main_out_registers;
  signal regs_towb_csync : t_fd_main_in_registers;
  signal regs_towb_spi   : t_fd_main_in_registers;
  signal regs_towb_tsu   : t_fd_main_in_registers;
  signal regs_towb_rbuf  : t_fd_main_in_registers;
  signal regs_towb_local : t_fd_main_in_registers;
  signal regs_towb_dmtd  : t_fd_main_in_registers;
  signal regs_towb       : t_fd_main_in_registers;


  signal owr_en_int : std_logic_vector(0 downto 0);
  signal owr_int    : std_logic_vector(0 downto 0);
  signal dbg_acam   : std_logic_vector(3 downto 0);

  signal gen_cal_pulse     : std_logic_vector(3 downto 0);
  signal cal_pulse_mask    : std_logic_vector(3 downto 0);
  signal cal_pulse_trigger : std_logic;

  signal tm_dac_val_int : std_logic_vector(31 downto 0);
  signal tcr_rd_ack     : std_logic;

  signal tag_valid_masked : std_logic;

  signal dmtd_pattern                    : std_logic;
  signal csync_pps                       : std_logic;
  signal tdc_cal_pulse                   : std_logic;
  signal dmtr_in_rd_ack, dmtr_out_rd_ack : std_logic;


  signal pwm_count : unsigned(11 downto 0);
  signal pwm_out   : std_logic;

  signal spi_cs_dac_n, spi_cs_pll_n, spi_cs_gpio_n, spi_mosi : std_logic;

  signal dmtd_tag_stb, dbg_tag_in, dbg_tag_out : std_logic;
  
  signal iodelay_ntaps : std_logic_vector(5 downto 0);
  signal iodelay_cnt : unsigned(5 downto 0);
  signal iodelay_div : unsigned(4 downto 0);
  signal iodelay_tick : std_logic;
  signal iodelay_cal_done : std_logic;
  
begin  -- rtl

  U_WB_Adapter : wb_slave_adapter
    generic map (
      g_master_use_struct  => true,
      g_master_mode        => PIPELINED,
      g_master_granularity => WORD,
      g_slave_use_struct   => false,
      g_slave_mode         => g_interface_mode,
      g_slave_granularity  => g_address_granularity)
    port map (
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_n_i,
      sl_adr_i   => wb_adr_i,
      sl_dat_i   => wb_dat_i,
      sl_sel_i   => wb_sel_i,
      sl_cyc_i   => wb_cyc_i,
      sl_stb_i   => wb_stb_i,
      sl_we_i    => wb_we_i,
      sl_dat_o   => wb_dat_o,
      sl_ack_o   => wb_ack_o,
      sl_stall_o => wb_stall_o,

      master_i => slave_out(0),
      master_o => slave_in(0));

  tm_dac_val_int <= x"00" & tm_dac_value_i;

  U_Intercon : xwb_crossbar
    generic map (
      g_num_masters => 1,
      g_num_slaves  => 6,
      g_registered  => true,
      g_address     => c_cnx_base_addr,
      g_mask        => c_cnx_base_mask)
    port map (
      clk_sys_i => clk_sys_i,
      rst_n_i   => rst_n_i,
      slave_i   => slave_in,
      slave_o   => slave_out,
      master_i  => cnx_in,
      master_o  => cnx_out);


  U_Reset_Generator : fd_reset_generator
    port map (
      clk_sys_i   => clk_sys_i,
      clk_ref_i   => clk_ref_0_i,
      rst_n_i     => rst_n_i,
      rst_n_sys_o => rst_n_sys,
      rst_n_ref_o => rst_n_ref,
      ext_rst_n_o => ext_rst_n_o,
      regs_i      => regs_fromwb);

  U_Csync_generator : fd_csync_generator
    generic map (
      g_with_wr_core => g_with_wr_core,
      g_simulation   => g_simulation)
    port map (
      clk_ref_i            => clk_ref_0_i,
      clk_sys_i            => clk_sys_i,
      rst_n_sys_i          => rst_n_sys,
      rst_n_ref_i          => rst_n_ref,
      wr_time_valid_i      => tm_time_valid_i,
      wr_utc_i             => tm_utc_i,
      wr_coarse_i          => tm_cycles_i,
      csync_p1_o           => master_csync_p1,
      csync_utc_o          => master_csync_utc,
      csync_coarse_o       => master_csync_coarse,
      wr_link_up_i         => tm_link_up_i,
      wr_clk_aux_lock_en_o => tm_clk_aux_lock_en_o,
      wr_clk_dmtd_locked_i => tm_clk_dmtd_locked_i,
      wr_clk_aux_locked_i  => tm_clk_aux_locked_i,

      irq_sync_o   => irq_sync,
      tcr_rd_ack_i => tcr_rd_ack,
      csync_pps_o  => csync_pps,
      regs_i       => regs_fromwb,
      regs_o       => regs_towb_csync);

  U_SPI_Arbiter : fd_spi_dac_arbiter
    generic map (
      g_div_ratio_log2 => f_select_spi_rate)
    port map (
      clk_sys_i       => clk_sys_i,
      rst_n_i         => rst_n_sys,
      tm_dac_value_i  => tm_dac_val_int,
      tm_dac_wr_i     => tm_dac_wr_i,
      spi_cs_dac_n_o  => spi_cs_dac_n,
      spi_cs_pll_n_o  => spi_cs_pll_n,
      spi_cs_gpio_n_o => spi_cs_gpio_n,
      spi_sclk_o      => spi_sclk_o,
      spi_mosi_o      => spi_mosi,
      spi_miso_i      => spi_miso_i,
      regs_i          => regs_fromwb,
      regs_o          => regs_towb_spi);


  U_Onewire : xwb_onewire_master
    generic map (
      g_interface_mode      => PIPELINED,
      g_address_granularity => WORD,
      g_num_ports           => 1)
    port map (
      clk_sys_i   => clk_sys_i,
      rst_n_i     => rst_n_i,
      slave_i     => cnx_out(5),
      slave_o     => cnx_in(5),
      desc_o      => open,
      owr_pwren_o => open,
      owr_en_o    => owr_en_int,
      owr_i       => owr_int);

  owr_en_o   <= owr_en_int(0);
  owr_int(0) <= owr_i;

  regs_towb <= regs_towb_csync or regs_towb_tsu or regs_towb_rbuf or regs_towb_local or regs_towb_spi or regs_towb_dmtd;

  U_Wishbone_Slave : fd_main_wb_slave
    port map (
      rst_n_i    => rst_n_i,
      clk_sys_i  => clk_sys_i,
      wb_adr_i   => cnx_out(0).adr(5 downto 0),
      wb_dat_i   => cnx_out(0).dat,
      wb_dat_o   => cnx_in(0).dat,
      wb_cyc_i   => cnx_out(0).cyc,
      wb_sel_i   => cnx_out(0).sel,
      wb_stb_i   => cnx_out(0).stb,
      wb_we_i    => cnx_out(0).we,
      wb_ack_o   => cnx_in(0).ack,
      wb_stall_o => cnx_in(0).stall,
      wb_int_o   => wb_irq_o,

      clk_ref_i => clk_ref_0_i,

      tcr_rd_ack_o          => tcr_rd_ack,
      regs_o                => regs_fromwb,
      regs_i                => regs_towb,
      irq_ts_buf_notempty_i => irq_rbuf,
      irq_dmtd_spll_i       => '0',
      irq_sync_status_i     => irq_sync,
      dmtr_out_rd_ack_o     => dmtr_out_rd_ack,
      dmtr_in_rd_ack_o      => dmtr_in_rd_ack
      );


  
  
  U_Acam_TSU : fd_acam_timestamper
    generic map (
      g_min_pulse_width => 3,
      g_clk_ref_freq    => c_REF_CLK_FREQ,
      g_frac_bits       => c_TIMESTAMP_FRAC_BITS)
    port map (
      clk_ref_i => clk_ref_0_i,
      rst_n_i   => rst_n_ref,

      tdc_start_i => tdc_start_i,
      trig_a_i    => trig_a_i,

      acam_d_o          => acam_d_o,
      acam_d_i          => acam_d_i,
      acam_d_oe_o       => acam_d_oen_o,
      acam_rd_n_o       => acam_rd_n_o,
      acam_wr_n_o       => acam_wr_n_o,
      acam_ef_i         => acam_emptyf_i,
      acam_stop_dis_o   => acam_stop_dis_o,
      acam_start_dis_o  => acam_start_dis_o,
      acam_alutrigger_o => acam_alutrigger_o,

      tag_frac_o    => tag_frac,
      tag_coarse_o  => tag_coarse,
      tag_utc_o     => tag_utc,
      tag_valid_o   => tag_valid,
      tag_dbg_raw_o => tag_dbg,

      tag_rearm_p1_i => '1',

      csync_coarse_i => master_csync_coarse,
      csync_utc_i    => master_csync_utc,
      csync_p1_i     => master_csync_p1,


      regs_i => regs_fromwb,
      regs_o => regs_towb_tsu,
      dbg_o  => dbg_acam);

  rbuf_mux_ts(0).u      <= tag_utc;
  rbuf_mux_ts(0).c      <= tag_coarse;
  rbuf_mux_ts(0).f      <= tag_frac;
  rbuf_mux_valid(0)     <= tag_valid;
  rbuf_mux_valid_masked <= rbuf_mux_valid and regs_fromwb.tsbcr_chan_mask_o;


  gen_with_direct_io_tdc : if(g_with_direct_timestamp_io) generate
    
    U_Sync_TDC_Valid_Out : gc_pulse_synchronizer2
      port map (
        clk_in_i  => clk_ref_0_i,
        rst_in_n_i  => rst_n_ref,
        clk_out_i => clk_sys_i,
        rst_out_n_i => rst_n_sys,
        d_p_i     => tag_valid,
        q_p_o     => tdc_valid_o);

    process(clk_ref_0_i)
    begin
      if rising_edge(clk_ref_0_i) then
        if(tag_valid = '1') then
          tdc_cycles_o  <= tag_coarse;
          tdc_seconds_o <= tag_utc;
          tdc_frac_o    <= tag_frac;
        end if;
      end if;
    end process;
  end generate gen_with_direct_io_tdc;

  gen_pack_rbuf_mux : for i in 0 to 4 generate
    rbuf_mux_d(c_TIMESTAMP_TOTAL_BITS * (i+1) -1 downto c_TIMESTAMP_TOTAL_BITS * i) <= to_stdLogicVector(rbuf_mux_ts(i));
  end generate gen_pack_rbuf_mux;

  U_Rbuf_Mux : gc_arbitrated_mux
    generic map (
      g_num_inputs => 5,
      g_width      => c_TIMESTAMP_TOTAL_BITS)
    port map (
      clk_i        => clk_ref_0_i,
      rst_n_i      => rst_n_ref,
      d_i          => rbuf_mux_d,
      d_valid_i    => rbuf_mux_valid_masked,
      q_o          => rbuf_mux_q,
      q_valid_o    => rbuf_valid,
      q_input_id_o => rbuf_source(2 downto 0));

  
  rbuf_in_ts <= to_fd_timestamp(rbuf_mux_q);

  U_Ring_Buffer : fd_ring_buffer
    generic map (
      g_size_log2 => c_RING_BUFFER_SIZE_LOG2)
    port map (
      rst_n_sys_i => rst_n_sys,
      rst_n_ref_i => rst_n_ref,
      clk_ref_i   => clk_ref_0_i,
      clk_sys_i   => clk_sys_i,

      tag_source_i  => rbuf_source,
      tag_valid_i   => rbuf_valid,
      tag_utc_i     => rbuf_in_ts.u,
      tag_coarse_i  => rbuf_in_ts.c,
      tag_frac_i    => rbuf_in_ts.f,
      tag_dbg_raw_i => tag_dbg,

      tsbcr_read_ack_i => tsbcr_read_ack,
      fid_read_ack_i   => fid_read_ack,
      buf_irq_o        => irq_rbuf,
      regs_i           => regs_fromwb,
      regs_o           => regs_towb_rbuf);

  U_Extend_Cal_Pulse : gc_extend_pulse
    generic map (
      g_width => 3)
    port map (
      clk_i      => clk_ref_0_i,
      rst_n_i    => rst_n_ref,
      pulse_i    => regs_fromwb.calr_cal_pulse_o,
      extended_o => cal_pulse_trigger);

  cal_pulse_mask <= (others => cal_pulse_trigger);
  gen_cal_pulse  <= cal_pulse_mask and regs_fromwb.calr_psel_o;

  gen_output_channels : for i in 0 to 3 generate

    gen_with_direct_io : if g_with_direct_timestamp_io generate
      
      U_Sync_Valid_Pulse : gc_pulse_synchronizer2
        port map (
          clk_in_i  => clk_sys_i,
          rst_in_n_i  => rst_n_sys,
          clk_out_i => clk_ref_0_i,
          rst_out_n_i => rst_n_ref,
          d_p_i     => outx_valid_i(i),
          q_p_o     => channels(i).tag.valid);

      process(clk_sys_i)
      begin
        if rising_edge(Clk_sys_i) then
          if(outx_valid_i(i) = '1')then
            channels(i).tag.u <= outx_seconds_i(40 * (i+1) - 1 downto 40 * i);
            channels(i).tag.c <= outx_cycles_i(28 * (i+1) - 1 downto 28 * i);
            channels(i).tag.f <= outx_frac_i(12 * (i+1) -1 downto 12 * i);
          end if;
        end if;
      end process;
    end generate gen_with_direct_io;

    gen_without_direct_io : if not g_with_direct_timestamp_io generate
      channels(i).tag.valid <= tag_valid_masked;
      channels(i).tag.u     <= tag_utc;
      channels(i).tag.c     <= tag_coarse;
      channels(i).tag.f     <= tag_frac;
    end generate gen_without_direct_io;

    U_Output_ChannelX : fd_delay_channel_driver
      generic map (
        g_index => i)
      port map (
        clk_ref_i         => clk_ref_0_i,
        clk_sys_i         => clk_sys_i,
        rst_n_ref_i       => rst_n_ref,
        rst_n_sys_i       => rst_n_sys,
        csync_p1_i        => master_csync_p1,
        csync_utc_i       => master_csync_utc,
        csync_coarse_i    => master_csync_coarse,
        gen_cal_i         => gen_cal_pulse(i),
        tag_valid_i       => channels(i).tag.valid,
        tag_utc_i         => channels(i).tag.u,
        tag_coarse_i      => channels(i).tag.c,
        tag_frac_i        => channels(i).tag.f,
        pstart_valid_o    => rbuf_mux_valid(i+1),
        pstart_utc_o      => rbuf_mux_ts(i+1).u,
        pstart_coarse_o   => rbuf_mux_ts(i+1).c,
        pstart_frac_o     => rbuf_mux_ts(i+1).f,
        delay_pulse0_o    => channels(i).pulse0,
        delay_pulse1_o    => channels(i).pulse1,
        delay_value_o     => channels(i).value,
        delay_load_o      => channels(i).load,
        delay_idle_o      => channels(i).idle,
        delay_load_done_i => channels(i).load_done,
        wb_i              => cnx_out(i+1),
        wb_o              => cnx_in(i+1),
        dbg_o             => channels(i).dbg);

    chx_delay_idle(i) <= channels(i).idle;

    U_DDR_Output : fd_ddr_driver
      port map (
        clk0_i => clk_ref_0_i,
        clk1_i => clk_ref_180_i,
        d0_i   => channels(i).pulse0,
        d1_i   => channels(i).pulse1,
        q_o    => delay_pulse_o(i));

  end generate gen_output_channels;

  U_Delay_Line_Arbiter : fd_delay_line_arbiter
    port map (
      clk_ref_i => clk_ref_0_i,
      rst_n_i   => rst_n_ref,
      load_i(0) => channels(0).load,
      load_i(1) => channels(1).load,
      load_i(2) => channels(2).load,
      load_i(3) => channels(3).load,

      done_o(0) => channels(0).load_done,
      done_o(1) => channels(1).load_done,
      done_o(2) => channels(2).load_done,
      done_o(3) => channels(3).load_done,

      delay_val0_i => f_reverse_bits(channels(0).value),
      delay_val1_i => channels(1).value,
      delay_val2_i => f_reverse_bits(channels(2).value),
      delay_val3_i => channels(3).value,
      delay_val_o  => delay_val_o,
      delay_len_o  => delay_len_o);

  U_DMTD_Calibrator : fd_dmtd_insertion_calibrator
    port map (
      clk_ref_i         => clk_ref_0_i,
      clk_dmtd_i        => clk_dmtd_i,
      clk_sys_i         => clk_sys_i,
      rst_n_sys_i       => rst_n_sys,
      rst_n_ref_i       => rst_n_ref,
      regs_i            => regs_fromwb,
      regs_o            => regs_towb_dmtd,
      dmtd_fb_in_i      => dmtd_fb_in_i,
      dmtd_fb_out_i     => dmtd_fb_out_i,
      dmtd_samp_o       => dmtd_samp_o,
      dmtd_pattern_o    => dmtd_pattern,
      dmtr_in_rd_ack_i  => dmtr_in_rd_ack,
      dmtr_out_rd_ack_i => dmtr_out_rd_ack,
      dbg_tag_in_o      => dbg_tag_in,
      dbg_tag_out_o     => dbg_tag_out
      );


  
  tag_valid_masked <= tag_valid when unsigned(not chx_delay_idle) = 0 else '0';

  U_LED_Driver : gc_extend_pulse
    generic map (
      g_width => 10000000)
    port map (
      clk_i      => clk_ref_0_i,
      rst_n_i    => rst_n_ref,
      pulse_i    => tag_valid,
      extended_o => led_trig_o);

  p_gen_cal_trigger : process(clk_ref_0_i)
  begin
    if rising_edge(clk_ref_0_i) then
      if rst_n_ref = '0' then
        tdc_cal_pulse <= '0';
      else
        tdc_cal_pulse <= regs_fromwb.calr_cal_pulse_o or (dmtd_pattern and regs_fromwb.calr_cal_dmtd_o)
                         or (regs_fromwb.calr_cal_pps_o and csync_pps);
        tdc_cal_pulse_o <= tdc_cal_pulse;
      end if;
    end if;
  end process;

  regs_towb_local.tdcsr_empty_i <= acam_emptyf_i;

  i2c_scl_o     <= '0';
  i2c_scl_oen_o <= regs_fromwb.i2cr_scl_out_o;
  i2c_sda_o     <= '0';
  i2c_sda_oen_o <= regs_fromwb.i2cr_sda_out_o;

  regs_towb_local.i2cr_sda_in_i <= i2c_sda_i;
  regs_towb_local.i2cr_scl_in_i <= i2c_scl_i;

  regs_towb_local.gcr_ddr_locked_i  <= pll_status_i;
  regs_towb_local.gcr_fmc_present_i <= not fmc_present_n_i;

  regs_towb_local.fmc_slot_id_slot_id_i <= std_logic_vector(to_unsigned(g_fmc_slot_id, 4 ));

  -- Debug PWM driver for adjusting Peltier temperature. Drivers SPI MOSI line
  -- with PWM waveform when none of the SPI peripherals is in use (we have no
  -- spare pins in the FMC connector left)

  p_peltier_pwm : process(clk_sys_i)
  begin
    if rising_edge(Clk_sys_i) then
      if rst_n_sys = '0' then
        pwm_count <= (others => '0');
      else
        pwm_count <= pwm_count + 1;
        if(pwm_count > unsigned(regs_fromwb.tder2_pelt_drive_o(15 downto 0))) then
          pwm_out <= '1';
        else
          pwm_out <= '0';
        end if;
      end if;
    end if;
  end process;

  -- VCXO Frequency measuremnt (for DAC testing purposes)

  U_VCXO_Freq_Meter : gc_frequency_meter
    generic map (
      g_with_internal_timebase => true,
      g_clk_sys_freq           => c_SYS_CLK_FREQ,
      g_counter_bits           => 31)
    port map (
      clk_sys_i    => clk_sys_i,
      clk_in_i     => clk_ref_0_i,
      rst_n_i      => rst_n_sys,
      pps_p1_i     => '0',
      freq_o       => regs_towb_local.tder1_vcxo_freq_i(30 downto 0),
      freq_valid_o => regs_towb_local.tder1_vcxo_freq_i(31));

  spi_mosi_o      <= spi_mosi when (spi_cs_gpio_n and spi_cs_pll_n and spi_cs_dac_n) = '0' else pwm_out;
  spi_cs_gpio_n_o <= spi_cs_gpio_n;
  spi_cs_dac_n_o  <= spi_cs_dac_n;
  spi_cs_pll_n_o  <= spi_cs_pll_n;

  gen_with_dbg_out : if(g_with_debug_output) generate
    
    process(clk_ref_0_i)
    begin
      if rising_edge(clk_ref_0_i) then
        
        dbg_o(0) <= dbg_acam(1);         -- trig_d(2)
        dbg_o(1) <= dbg_acam(2);         -- acam tag valid
        dbg_o(2) <= channels(0).dbg(0);  -- out0 ARB_START
        dbg_o(3) <= channels(0).dbg(1);  -- out0 WAIT_START
      end if;
    end process;

  end generate gen_with_dbg_out;

  gen_without_dbg_out : if(not g_with_debug_output) generate
    dbg_o <= (others => '0');
  end generate gen_without_dbg_out;

  p_handle_iodelay: process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_sys = '0' then
        idelay_cal_o <= '0';
        idelay_inc_o <= '1';
        idelay_rst_o <= '0';
        idelay_ce_o <= '0';
        iodelay_cal_done <= '0';
        iodelay_cnt <= (others => '0');
        iodelay_div <= (others => '0');
        iodelay_tick <= '0';
      else

        if iodelay_cal_done = '0' then
          idelay_cal_o <= '1';
          iodelay_cnt <= iodelay_cnt + 1;
          if iodelay_cnt = 15 then
            iodelay_cnt <= (others => '0');
            iodelay_cal_done <= '1';
          end if;
        else
          idelay_cal_o <= '0';
        end if;

        iodelay_div <= iodelay_div + 1;
        if iodelay_div = 0 then
          iodelay_tick <= '1';
        else
          iodelay_tick <= '0';
        end if;

        if regs_fromwb.iodelay_adj_n_taps_load_o = '1' then
          iodelay_cnt <= unsigned(regs_fromwb.iodelay_adj_n_taps_o);
          idelay_rst_o <= '1';
          iodelay_ntaps <= regs_fromwb.iodelay_adj_n_taps_o;
        else
          idelay_rst_o <= '0';
        end if;

        if iodelay_cal_done = '1' and iodelay_tick = '1' and iodelay_cnt /= 0 then
          idelay_ce_o <= '1';
          iodelay_cnt <= iodelay_cnt - 1;
        else
          idelay_ce_o <= '0';
        end if;
        
        
        
      end if;
      
    end if;
      
    end process;
  regs_towb_local.iodelay_adj_n_taps_i <= iodelay_ntaps;
  
  
end rtl;
