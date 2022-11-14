-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

-------------------------------------------------------------------------------
-- Title      : Timestamp Ring Buffer
-- Project    : Fine Delay FMC (fmc-delay-1ns-4cha)
-------------------------------------------------------------------------------
-- File       : fd_ring_buffer.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2018-08-02
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Host-accessible buffer for timestamp readout:
-- - takes the timestamps from the TDC or delay channel drivers,
-- - passes the timestamps to the system clock domain using a FIFO,
-- - drops oldest timestamps if buffer is full
-- - visible to the host as a FIFO register
-- - drives an interrupt line (with simple threshold/timeout coalescing).
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

use work.genram_pkg.all;
use work.fine_delay_pkg.all;
use work.fd_main_wbgen2_pkg.all;

entity fd_ring_buffer is
  
  generic (
    -- log2 (number of timestamps in the buffer)
    g_size_log2 : integer := 8);

  port (

    rst_n_sys_i : in std_logic;
    rst_n_ref_i : in std_logic;

    clk_ref_i : in std_logic;
    clk_sys_i : in std_logic;

    ---------------------------------------------------------------------------
    -- Input tags (clk_ref_i domain)
    ---------------------------------------------------------------------------
    tag_valid_i   : in std_logic;
    -- Tag source : 0 = TDC, 1..4 = output channels
    tag_source_i  : in std_logic_vector(3 downto 0);
    tag_utc_i     : in std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
    tag_coarse_i  : in std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
    tag_frac_i    : in std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);
    tag_dbg_raw_i : in std_logic_vector(31 downto 0);

    -- Flushes the latest timestamp to the output registers
   tsbcr_read_ack_i:  in std_logic;
   fid_read_ack_i:  in std_logic;
    
    -- Buffer interrupt (level-sensitive)
    buf_irq_o : out std_logic;

    regs_i : in  t_fd_main_out_registers;
    regs_o : out t_fd_main_in_registers
    );


end fd_ring_buffer;

architecture behavioral of fd_ring_buffer is

  constant c_PACKED_TS_SIZE : integer := 32 + 4 + c_TIMESTAMP_UTC_BITS + c_TIMESTAMP_COARSE_BITS + c_TIMESTAMP_FRAC_BITS + 16;
  constant c_FIFO_SIZE      : integer := 8;

  type t_internal_timestamp is record
    src    : std_logic_vector(3 downto 0);
    utc    : std_logic_vector(c_TIMESTAMP_UTC_BITS-1 downto 0);
    coarse : std_logic_vector(c_TIMESTAMP_COARSE_BITS-1 downto 0);
    frac   : std_logic_vector(c_TIMESTAMP_FRAC_BITS-1 downto 0);
    seq_id : std_logic_vector(15 downto 0);
    dbg    : std_logic_vector(31 downto 0);
  end record;

  function f_pack_timestamp(ts : t_internal_timestamp) return std_logic_vector is
  begin
    return ts.dbg & ts.utc & ts.coarse & ts.frac & ts.seq_id & ts.src;
  end f_pack_timestamp;


  function f_unpack_timestamp(ts : std_logic_vector)return t_internal_timestamp is
    variable tmp : t_internal_timestamp;
  begin
    tmp.dbg    := ts(c_PACKED_TS_SIZE-1 downto c_PACKED_TS_SIZE-32);
    tmp.utc    := ts(-32 + c_PACKED_TS_SIZE-1 downto -32 + c_PACKED_TS_SIZE-c_TIMESTAMP_UTC_BITS);
    tmp.coarse := ts(-32 + c_PACKED_TS_SIZE-c_TIMESTAMP_UTC_BITS-1 downto -32 + c_PACKED_TS_SIZE-c_TIMESTAMP_UTC_BITS-c_TIMESTAMP_COARSE_BITS);
    tmp.frac   := ts(16+4+c_TIMESTAMP_FRAC_BITS-1 downto 16+4);
    tmp.seq_id := ts(16+4-1 downto 4);
    tmp.src    := ts(3 downto 0);
    return tmp;
  end f_unpack_timestamp;

  signal fifo_in, fifo_out     : std_logic_vector(c_PACKED_TS_SIZE-1 downto 0);
  signal fifo_write, fifo_read : std_logic;
  signal fifo_empty, fifo_full : std_logic;

  signal ts_fifo_in : t_internal_timestamp;
  signal cur_seq_id : unsigned(15 downto 0);

  signal buf_wr_ptr               : unsigned(g_size_log2-1 downto 0);
  signal buf_rd_ptr               : unsigned(g_size_log2-1 downto 0);
  signal buf_count                : unsigned(g_size_log2 downto 0);
  signal buf_full, buf_empty      : std_logic;
  signal buf_wr_data, buf_rd_data : std_logic_vector(c_PACKED_TS_SIZE-1 downto 0);
  signal buf_write, buf_read, buf_overflow      : std_logic;

  signal buf_ram_out, buf_out_reg : t_internal_timestamp;

  signal fifo_read_d0 : std_logic;
  signal update_oreg  : std_logic;



  signal tmr_div                  : unsigned(f_log2_size(c_REF_CLK_FREQ/1000+1)-1 downto 0);
  signal tmr_tick                 : std_logic;
  signal tmr_timeout              : unsigned(9 downto 0);
  signal buf_irq_int              : std_logic;
  signal buf_read_d0, buf_read_d1 : std_logic;

  signal empty_d : std_logic_vector(4 downto 0);

  signal read_ack, read_ack_d, read_ack_p : std_logic;
  
begin  -- behavioral


  p_count_seq_id : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_ref_i = '0' or regs_i.tsbcr_rst_seq_o = '1' then
        cur_seq_id <= (others => '0');
      elsif(tag_valid_i = '1') then
        cur_seq_id <= cur_seq_id + 1;
      end if;
    end if;
  end process;

  fifo_in <= f_pack_timestamp(ts_fifo_in);

  ts_fifo_in.dbg    <= tag_dbg_raw_i;
  ts_fifo_in.utc    <= tag_utc_i;
  ts_fifo_in.coarse <= tag_coarse_i;
  ts_fifo_in.frac   <= tag_frac_i;
  ts_fifo_in.src    <= tag_source_i;
  ts_fifo_in.seq_id <= std_logic_vector(cur_seq_id);

  fifo_write <= not fifo_full and tag_valid_i;

  U_Clock_Adjustment_Fifo : generic_async_fifo_dual_rst
    generic map (
      g_data_width => fifo_in'length,
      g_size       => c_FIFO_SIZE)
    port map (
      rst_wr_n_i => rst_n_ref_i,
      clk_wr_i   => clk_ref_i,
      d_i        => fifo_in,
      we_i       => fifo_write,
      wr_full_o  => fifo_full,
      rst_rd_n_i => rst_n_sys_i,
      clk_rd_i   => clk_sys_i,
      q_o        => fifo_out,
      rd_i       => fifo_read,
      rd_empty_o => fifo_empty);

  buf_wr_data <= fifo_out;

  U_Buffer_RAM : generic_dpram
    generic map (
      g_data_width => c_PACKED_TS_SIZE,
      g_size       => 2**g_size_log2,
      g_dual_clock => false)
    port map (
      rst_n_i => rst_n_sys_i,
      clka_i  => clk_sys_i,
      bwea_i  => (others => '1'),
      wea_i   => buf_write,
      aa_i    => std_logic_vector(buf_wr_ptr),
      da_i    => buf_wr_data,
      qa_o    => open,
      clkb_i  => clk_sys_i,
      bweb_i  => (others => '0'),
      web_i   => '0',
      ab_i    => std_logic_vector(buf_rd_ptr),
      db_i    => (others => '0'),
      qb_o    => buf_rd_data);


  fifo_read <= not fifo_empty;

  buf_full    <= '1' when (buf_wr_ptr + 1 = buf_rd_ptr)                                                      else '0';
  buf_empty   <= '1' when (buf_wr_ptr = buf_rd_ptr)                                                          else '0';
  buf_write   <= regs_i.tsbcr_enable_o and fifo_read_d0;
  buf_overflow <= '1' when (buf_write = '1' and buf_full = '1') else '0';
  buf_read    <= '1' when (regs_i.tsbr_advance_adv_o = '1' and buf_empty = '0') or buf_overflow = '1' else '0';
  buf_ram_out <= f_unpack_timestamp(buf_rd_data);

  -- drive WB registers
  regs_o.tsbcr_full_i  <= buf_full;
  regs_o.tsbcr_empty_i <= buf_empty;

  p_buffer_control : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_sys_i = '0' or regs_i.tsbcr_purge_o = '1' then
        buf_rd_ptr   <= (others => '0');
        buf_wr_ptr   <= (others => '0');
        buf_count    <= (others => '0');
        fifo_read_d0 <= '0';
   
      else


        fifo_read_d0 <= fifo_read;
    
        if(buf_write = '1') then
          buf_wr_ptr <= buf_wr_ptr + 1;
        end if;

        if(buf_read = '1') then
          buf_rd_ptr <= buf_rd_ptr + 1;
        end if;

        if(buf_write = '1' and buf_read = '0') then
          buf_count <= buf_count + 1;
        end if;

        if(buf_write = '0' and buf_read = '1') then
          buf_count <= buf_count - 1;
        end if;
      end if;
    end if;
  end process;

  p_output_register : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if(buf_read  = '1' and buf_overflow = '0') then
        buf_out_reg <= buf_ram_out;
      end if;
    end if;
  end process;


  p_coalesce_tick : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_sys_i = '0' then
        tmr_div  <= (others => '0');
        tmr_tick <= '0';
      else
        if(tmr_div /= c_SYS_CLK_FREQ/1000-1) then
          tmr_div  <= tmr_div + 1;
          tmr_tick <= '1';
        else
          tmr_div  <= (others => '0');
          tmr_tick <= '0';
        end if;
      end if;
    end if;
  end process;

  p_coalesce_irq : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_sys_i = '0' then
        buf_irq_int <= '0';
      else
        if(buf_count = 0) then
          buf_irq_int <= '0';
          tmr_timeout <= (others => '0');
        else
          -- Simple interrupt coalescing :

          -- Case 1: There is some data in the buffer 
          -- (but not exceeding the threshold) - assert the IRQ line after a
          -- certain timeout.
          if(buf_irq_int = '0') then
            if(tmr_timeout = unsigned(regs_i.tsbir_timeout_o)) then
              buf_irq_int <= '1';
              tmr_timeout <= (others => '0');
            elsif(tmr_tick = '1') then
              tmr_timeout <= tmr_timeout + 1;
            end if;
          end if;

          -- Case 2: amount of data exceeded the threshold - assert the IRQ
          -- line immediately.
          if(buf_count > unsigned(regs_i.tsbir_threshold_o)) then
            buf_irq_int <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;


 
  regs_o.tsbr_sech_i        <= buf_out_reg.utc(39 downto 32);
  regs_o.tsbr_secl_i        <= buf_out_reg.utc(31 downto 0);
  regs_o.tsbr_cycles_i      <= buf_out_reg.coarse;
  regs_o.tsbr_fid_fine_i    <= buf_out_reg.frac;
  regs_o.tsbr_fid_seqid_i   <= buf_out_reg.seq_id;
  regs_o.tsbr_fid_channel_i <= buf_out_reg.src;
  regs_o.tsbr_debug_i       <= buf_out_reg.dbg;
  regs_o.tsbcr_count_i      <= std_logic_vector(resize(buf_count, regs_o.tsbcr_count_i'length));

  buf_irq_o <= buf_irq_int;
  
end behavioral;
