-------------------------------------------------------------------------------
-- Title      : Fine Delay VHDL Core (main package)
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fine_delay_pkg.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2012-06-06
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Main package.
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.fd_main_wbgen2_pkg.all;
use work.fd_channel_wbgen2_pkg.all;


package fine_delay_pkg is

  -----------------------------------------------------------------------------
  -- User editable constants
  -----------------------------------------------------------------------------

  -- Timestamp field bits (if you change them, you must also change the WB files)
  constant c_TIMESTAMP_UTC_BITS    : integer := 40;
  constant c_TIMESTAMP_COARSE_BITS : integer := 28;
  constant c_TIMESTAMP_FRAC_BITS   : integer := 12;

  -- log2(Number of entries in the timestamp buffer)
  constant c_RING_BUFFER_SIZE_LOG2 : integer := 10;

  -- Reference clock frequency in Hz
  constant c_REF_CLK_FREQ : integer := 125000000;

  -- System clock frequency in Hz
  constant c_SYS_CLK_FREQ : integer := 62500000;

  -- Reference clock period in picoseconds
  constant c_REF_CLK_PERIOD_PS : integer := 8000;

  -- Number of card outputs 
  constant c_FD_NUM_OUTPUTS : integer := 4;

  -- Number of reference clock cycles per one DDMTD calibration period
  constant c_FD_DMTD_CALIBRATION_PERIOD : integer := 144;

  -- Calibration pulse width
  constant c_FD_DMTD_CALIBRATION_PWIDTH : integer := 10;


  constant c_fine_delay_core_sdwb : t_sdwb_device := (
    wbd_begin     => x"0000000000000000",
    wbd_end       => x"00000000000003ff",
    sdwb_child    => x"0000000000000000",
    wbd_flags     => x"01",             -- big-endian, no-child, present
    wbd_width     => x"07",             -- 8/16/32-bit port granularity
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    abi_class     => x"00000000",       -- undocumented device
    dev_vendor    => x"0000CE42",       -- CERN
    dev_device    => x"f19ede1a",
    dev_version   => x"00000001",
    dev_date      => x"20120425",
    description   => "Fine Delay Core ");

  type t_fd_timestamp is record
    u     : std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
    c     : std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
    f     : std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);
    valid : std_logic;
  end record;

  type t_fd_timestamp_array is array (0 to c_FD_NUM_OUTPUTS-1) of t_fd_timestamp;


  -------------------------------------------------------------------------------
  -- Component declarations
  -----------------------------------------------------------------------------  
  component fd_ts_adder
    generic (
      g_frac_bits    : integer := c_TIMESTAMP_FRAC_BITS;
      g_coarse_bits  : integer := c_TIMESTAMP_COARSE_BITS;
      g_utc_bits     : integer := c_TIMESTAMP_UTC_BITS;
      g_coarse_range : integer := c_REF_CLK_FREQ);
    port (
      clk_i      : in  std_logic;
      rst_n_i    : in  std_logic;
      valid_i    : in  std_logic;
      enable_i   : in  std_logic := '1';
      a_utc_i    : in  std_logic_vector(g_utc_bits-1 downto 0);
      a_coarse_i : in  std_logic_vector(g_coarse_bits-1 downto 0);
      a_frac_i   : in  std_logic_vector(g_frac_bits-1 downto 0);
      b_utc_i    : in  std_logic_vector(g_utc_bits-1 downto 0);
      b_coarse_i : in  std_logic_vector(g_coarse_bits-1 downto 0);
      b_frac_i   : in  std_logic_vector(g_frac_bits-1 downto 0);
      valid_o    : out std_logic;
      q_utc_o    : out std_logic_vector(g_utc_bits-1 downto 0);
      q_coarse_o : out std_logic_vector(g_coarse_bits-1 downto 0);
      q_frac_o   : out std_logic_vector(g_frac_bits-1 downto 0));
  end component;

  component fd_ts_normalizer
    generic (
      g_frac_bits    : integer := c_TIMESTAMP_FRAC_BITS;
      g_coarse_bits  : integer := c_TIMESTAMP_COARSE_BITS;
      g_utc_bits     : integer := c_TIMESTAMP_UTC_BITS;
      g_coarse_range : integer := c_REF_CLK_FREQ);
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
      ext_rst_n_o : out std_logic;
      regs_i      : in  t_fd_main_out_registers);
  end component;

  component fd_acam_timestamper
    generic (
      g_min_pulse_width : natural;
      g_clk_ref_freq    : integer;
      g_frac_bits       : integer);
    port (
      clk_ref_i         : in  std_logic;
      rst_n_i           : in  std_logic;
      trig_a_i          : in  std_logic;
      tdc_start_i       : in  std_logic;
      acam_d_o          : out std_logic_vector(27 downto 0);
      acam_d_i          : in  std_logic_vector(27 downto 0);
      acam_d_oe_o       : out std_logic;
      acam_rd_n_o       : out std_logic;
      acam_wr_n_o       : out std_logic;
      acam_ef_i         : in  std_logic;
      acam_stop_dis_o   : out std_logic;
      acam_start_dis_o  : out std_logic;
      acam_alutrigger_o : out std_logic;
      tag_frac_o        : out std_logic_vector(g_frac_bits-1 downto 0);
      tag_coarse_o      : out std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
      tag_utc_o         : out std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
      tag_rearm_p1_i    : in  std_logic;
      tag_dbg_raw_o     : out std_logic_vector(31 downto 0);
      tag_valid_o       : out std_logic;
      csync_coarse_i    : in  std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
      csync_utc_i       : in  std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
      csync_p1_i        : in  std_logic;
      regs_i            : in  t_fd_main_out_registers;
      regs_o            : out t_fd_main_in_registers;
      dbg_o             : out std_logic_vector(3 downto 0));
  end component;

  component fd_csync_generator
    generic (
      g_simulation   : boolean;
      g_with_wr_core : boolean);
    port (
      clk_ref_i            : in  std_logic;
      clk_sys_i            : in  std_logic;
      rst_n_sys_i          : in  std_logic;
      rst_n_ref_i          : in  std_logic;
      wr_link_up_i         : in  std_logic;
      wr_time_valid_i      : in  std_logic;
      wr_clk_aux_lock_en_o : out std_logic;
      wr_clk_aux_locked_i  : in  std_logic;
      wr_clk_dmtd_locked_i : in  std_logic;
      wr_utc_i             : in  std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
      wr_coarse_i          : in  std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
      csync_p1_o           : out std_logic;
      csync_utc_o          : out std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
      csync_coarse_o       : out std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
      regs_i               : in  t_fd_main_out_registers;
      regs_o               : out t_fd_main_in_registers;
      tcr_rd_ack_i         : in  std_logic;
      csync_pps_o          : out std_logic;
      irq_sync_o           : out std_logic);
  end component;

  component fd_channel_wb_slave
    port (
      rst_n_i    : in  std_logic;
      clk_sys_i  : in  std_logic;
      wb_adr_i   : in  std_logic_vector(3 downto 0);
      wb_dat_i   : in  std_logic_vector(31 downto 0);
      wb_dat_o   : out std_logic_vector(31 downto 0);
      wb_cyc_i   : in  std_logic;
      wb_sel_i   : in  std_logic_vector(3 downto 0);
      wb_stb_i   : in  std_logic;
      wb_we_i    : in  std_logic;
      wb_ack_o   : out std_logic;
      wb_stall_o : out std_logic;
      clk_ref_i  : in  std_logic;
      regs_i     : in  t_fd_channel_in_registers;
      regs_o     : out t_fd_channel_out_registers);
  end component;

  component fd_main_wb_slave
    port (
      rst_n_i               : in  std_logic;
      clk_sys_i             : in  std_logic;
      wb_adr_i              : in  std_logic_vector(5 downto 0);
      wb_dat_i              : in  std_logic_vector(31 downto 0);
      wb_dat_o              : out std_logic_vector(31 downto 0);
      wb_cyc_i              : in  std_logic;
      wb_sel_i              : in  std_logic_vector(3 downto 0);
      wb_stb_i              : in  std_logic;
      wb_we_i               : in  std_logic;
      wb_ack_o              : out std_logic;
      wb_stall_o            : out std_logic;
      wb_int_o              : out std_logic;
      clk_ref_i             : in  std_logic;
      tcr_rd_ack_o          : out std_logic;
      dmtr_in_rd_ack_o      : out std_logic;
      dmtr_out_rd_ack_o     : out std_logic;
      tsbcr_read_ack_o      : out std_logic;
      fid_read_ack_o        : out std_logic;
      irq_ts_buf_notempty_i : in  std_logic;
      irq_dmtd_spll_i       : in  std_logic;
      irq_sync_status_i     : in  std_logic;
      regs_i                : in  t_fd_main_in_registers;
      regs_o                : out t_fd_main_out_registers);
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

  component fd_delay_channel_driver
    generic(
      g_index : integer);
    port (
      clk_ref_i         : in  std_logic;
      clk_sys_i         : in  std_logic;
      rst_n_ref_i       : in  std_logic;
      rst_n_sys_i       : in  std_logic;
      csync_p1_i        : in  std_logic;
      csync_utc_i       : in  std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
      csync_coarse_i    : in  std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
      gen_cal_i         : in  std_logic;
      tag_valid_i       : in  std_logic;
      tag_utc_i         : in  std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
      tag_coarse_i      : in  std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
      tag_frac_i        : in  std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);
      pstart_valid_o    : out std_logic;
      pstart_utc_o      : out std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
      pstart_coarse_o   : out std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
      pstart_frac_o     : out std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);
      delay_pulse0_o    : out std_logic;
      delay_pulse1_o    : out std_logic;
      delay_value_o     : out std_logic_vector(9 downto 0);
      delay_load_o      : out std_logic;
      delay_load_done_i : in  std_logic;
      delay_idle_o      : out std_logic;
      wb_i              : in  t_wishbone_slave_in;
      wb_o              : out t_wishbone_slave_out);
  end component;

  component fd_dmtd_insertion_calibrator
    port (
      clk_ref_i         : in  std_logic;
      clk_dmtd_i        : in  std_logic;
      clk_sys_i         : in  std_logic;
      rst_n_sys_i       : in  std_logic;
      rst_n_ref_i       : in  std_logic;
      regs_i            : in  t_fd_main_out_registers;
      regs_o            : out t_fd_main_in_registers;
      dmtd_fb_in_i      : in  std_logic;
      dmtd_fb_out_i     : in  std_logic;
      dmtd_samp_o       : out std_logic;
      dmtd_pattern_o    : out std_logic;
      dmtr_in_rd_ack_i  : in  std_logic;
      dmtr_out_rd_ack_i : in  std_logic;
      dbg_tag_in_o      : out std_logic;
      dbg_tag_out_o     : out std_logic);
  end component;
  
  component fd_ring_buffer
    generic (
      g_size_log2 : integer);
    port (
      rst_n_sys_i      : in  std_logic;
      rst_n_ref_i      : in  std_logic;
      clk_ref_i        : in  std_logic;
      clk_sys_i        : in  std_logic;
      tag_valid_i      : in  std_logic;
      tag_source_i     : in  std_logic_vector(3 downto 0);
      tag_utc_i        : in  std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
      tag_coarse_i     : in  std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
      tag_frac_i       : in  std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);
      tag_dbg_raw_i    : in  std_logic_vector(31 downto 0);
      tsbcr_read_ack_i : in  std_logic;
      fid_read_ack_i   : in  std_logic;
      buf_irq_o        : out std_logic;
      regs_i           : in  t_fd_main_out_registers;
      regs_o           : out t_fd_main_in_registers);
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
      regs_i          : in  t_fd_main_out_registers;
      regs_o          : out t_fd_main_in_registers);
  end component;

  component fd_ddr_driver
    port (
      clk0_i : in  std_logic;
      clk1_i : in  std_logic;
      d0_i   : in  std_logic;
      d1_i   : in  std_logic;
      q_o    : out std_logic);
  end component;

  component fine_delay_core
    generic (
      g_with_wr_core        : boolean;
      g_simulation          : boolean;
      g_interface_mode      : t_wishbone_interface_mode;
      g_address_granularity : t_wishbone_address_granularity);
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
      tm_link_up_i         : in  std_logic;
      tm_time_valid_i      : in  std_logic;
      tm_cycles_i          : in  std_logic_vector(27 downto 0);
      tm_utc_i             : in  std_logic_vector(39 downto 0);
      tm_clk_aux_lock_en_o : out std_logic;
      tm_clk_aux_locked_i  : in  std_logic;
      tm_clk_dmtd_locked_i : in  std_logic;
      tm_dac_value_i       : in  std_logic_vector(23 downto 0);
      tm_dac_wr_i          : in  std_logic;
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
  
  function f_to_internal_time (
    t_u : std_logic_vector;
    t_c : std_logic_vector;
    t_f : std_logic_vector := "0"
    ) return t_fd_timestamp;

  function f_reverse_bits(x : std_logic_vector)
    return std_logic_vector;

  function to_stdLogicVector(ts : t_fd_timestamp) return std_logic_vector;
  function to_fd_timestamp(x    : std_logic_vector) return t_fd_timestamp;

end fine_delay_pkg;

package body fine_delay_pkg is
  
  function f_reverse_bits(x : std_logic_vector)
    return std_logic_vector is
    variable tmp : std_logic_vector(x'left downto 0);
  begin
    for i in 0 to x'left loop
      tmp(x'left-i) := x(i);
    end loop;  -- i
    return tmp;
  end f_reverse_bits;
  
  function f_to_internal_time (
    t_u : std_logic_vector;
    t_c : std_logic_vector;
    t_f : std_logic_vector := "0"
    ) return t_fd_timestamp is
    variable rval : t_fd_timestamp;
  begin
    rval.u                         := (others => '0');
    rval.c                         := (others => '0');
    rval.f                         := (others => '0');
    rval.u (t_u'length-1 downto 0) := t_u;
    rval.c (t_c'length-1 downto 0) := t_c;
    rval.f (t_f'length-1 downto 0) := t_f;
    return rval;
  end f_to_internal_time;

  function to_stdLogicVector(ts : t_fd_timestamp) return std_logic_vector is
  begin
    return ts.u & ts.c & ts.f;
  end to_stdLogicVector;

  function to_fd_timestamp(x : std_logic_vector) return t_fd_timestamp is
    variable tmp : t_fd_timestamp;
  begin
    tmp.u := x(c_TIMESTAMP_UTC_BITS+c_TIMESTAMP_COARSE_BITS+c_TIMESTAMP_FRAC_BITS-1 downto c_TIMESTAMP_COARSE_BITS+c_TIMESTAMP_FRAC_BITS);
    tmp.c := x(c_TIMESTAMP_COARSE_BITS+c_TIMESTAMP_FRAC_BITS-1 downto c_TIMESTAMP_FRAC_BITS);
    tmp.f := x(c_TIMESTAMP_FRAC_BITS-1 downto 0);
    return tmp;
  end to_fd_timestamp;

  

end fine_delay_pkg;
