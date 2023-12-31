-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for Fine Delay Channel WB Slave
---------------------------------------------------------------------------------------
-- File           : fd_channel_wishbone_slave.vhd
-- Author         : auto-generated by wbgen2 from fd_channel_wishbone_slave.wb
-- Created        : Wed Mar 20 23:27:12 2019
-- Standard       : VHDL'87
---------------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE fd_channel_wishbone_slave.wb
-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fd_channel_wbgen2_pkg.all;


entity fd_channel_wb_slave is
port (
  rst_n_i                                  : in     std_logic;
  clk_sys_i                                : in     std_logic;
  wb_adr_i                                 : in     std_logic_vector(3 downto 0);
  wb_dat_i                                 : in     std_logic_vector(31 downto 0);
  wb_dat_o                                 : out    std_logic_vector(31 downto 0);
  wb_cyc_i                                 : in     std_logic;
  wb_sel_i                                 : in     std_logic_vector(3 downto 0);
  wb_stb_i                                 : in     std_logic;
  wb_we_i                                  : in     std_logic;
  wb_ack_o                                 : out    std_logic;
  wb_err_o                                 : out    std_logic;
  wb_rty_o                                 : out    std_logic;
  wb_stall_o                               : out    std_logic;
  clk_ref_i                                : in     std_logic;
  regs_i                                   : in     t_fd_channel_in_registers;
  regs_o                                   : out    t_fd_channel_out_registers
);
end fd_channel_wb_slave;

architecture syn of fd_channel_wb_slave is

signal fd_channel_dcr_enable_int                : std_logic      ;
signal fd_channel_dcr_enable_sync0              : std_logic      ;
signal fd_channel_dcr_enable_sync1              : std_logic      ;
signal fd_channel_dcr_mode_int                  : std_logic      ;
signal fd_channel_dcr_pg_arm_int                : std_logic      ;
signal fd_channel_dcr_pg_arm_int_delay          : std_logic      ;
signal fd_channel_dcr_pg_arm_sync0              : std_logic      ;
signal fd_channel_dcr_pg_arm_sync1              : std_logic      ;
signal fd_channel_dcr_pg_arm_sync2              : std_logic      ;
signal fd_channel_dcr_pg_trig_sync0             : std_logic      ;
signal fd_channel_dcr_pg_trig_sync1             : std_logic      ;
signal fd_channel_dcr_update_int                : std_logic      ;
signal fd_channel_dcr_update_int_delay          : std_logic      ;
signal fd_channel_dcr_update_sync0              : std_logic      ;
signal fd_channel_dcr_update_sync1              : std_logic      ;
signal fd_channel_dcr_update_sync2              : std_logic      ;
signal fd_channel_dcr_upd_done_sync0            : std_logic      ;
signal fd_channel_dcr_upd_done_sync1            : std_logic      ;
signal fd_channel_dcr_force_dly_int             : std_logic      ;
signal fd_channel_dcr_force_dly_int_delay       : std_logic      ;
signal fd_channel_dcr_force_dly_sync0           : std_logic      ;
signal fd_channel_dcr_force_dly_sync1           : std_logic      ;
signal fd_channel_dcr_force_dly_sync2           : std_logic      ;
signal fd_channel_dcr_no_fine_int               : std_logic      ;
signal fd_channel_dcr_force_hi_int              : std_logic      ;
signal fd_channel_frr_int                       : std_logic_vector(9 downto 0);
signal fd_channel_frr_swb                       : std_logic      ;
signal fd_channel_frr_swb_delay                 : std_logic      ;
signal fd_channel_frr_swb_s0                    : std_logic      ;
signal fd_channel_frr_swb_s1                    : std_logic      ;
signal fd_channel_frr_swb_s2                    : std_logic      ;
signal fd_channel_u_starth_int                  : std_logic_vector(7 downto 0);
signal fd_channel_u_startl_int                  : std_logic_vector(31 downto 0);
signal fd_channel_c_start_int                   : std_logic_vector(27 downto 0);
signal fd_channel_f_start_int                   : std_logic_vector(11 downto 0);
signal fd_channel_u_endh_int                    : std_logic_vector(7 downto 0);
signal fd_channel_u_endl_int                    : std_logic_vector(31 downto 0);
signal fd_channel_c_end_int                     : std_logic_vector(27 downto 0);
signal fd_channel_f_end_int                     : std_logic_vector(11 downto 0);
signal fd_channel_u_delta_int                   : std_logic_vector(3 downto 0);
signal fd_channel_c_delta_int                   : std_logic_vector(27 downto 0);
signal fd_channel_f_delta_int                   : std_logic_vector(11 downto 0);
signal fd_channel_rcr_rep_cnt_int               : std_logic_vector(15 downto 0);
signal fd_channel_rcr_cont_int                  : std_logic      ;
signal ack_sreg                                 : std_logic_vector(9 downto 0);
signal rddata_reg                               : std_logic_vector(31 downto 0);
signal wrdata_reg                               : std_logic_vector(31 downto 0);
signal bwsel_reg                                : std_logic_vector(3 downto 0);
signal rwaddr_reg                               : std_logic_vector(3 downto 0);
signal ack_in_progress                          : std_logic      ;
signal wr_int                                   : std_logic      ;
signal rd_int                                   : std_logic      ;
signal allones                                  : std_logic_vector(31 downto 0);
signal allzeros                                 : std_logic_vector(31 downto 0);

begin
-- Some internal signals assignments
wrdata_reg <= wb_dat_i;
-- 
-- Main register bank access process.
process (clk_sys_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    ack_sreg <= "0000000000";
    ack_in_progress <= '0';
    rddata_reg <= "00000000000000000000000000000000";
    fd_channel_dcr_enable_int <= '0';
    fd_channel_dcr_mode_int <= '0';
    fd_channel_dcr_pg_arm_int <= '0';
    fd_channel_dcr_pg_arm_int_delay <= '0';
    fd_channel_dcr_update_int <= '0';
    fd_channel_dcr_update_int_delay <= '0';
    fd_channel_dcr_force_dly_int <= '0';
    fd_channel_dcr_force_dly_int_delay <= '0';
    fd_channel_dcr_no_fine_int <= '0';
    fd_channel_dcr_force_hi_int <= '0';
    fd_channel_frr_int <= "0000000000";
    fd_channel_frr_swb <= '0';
    fd_channel_frr_swb_delay <= '0';
    fd_channel_u_starth_int <= "00000000";
    fd_channel_u_startl_int <= "00000000000000000000000000000000";
    fd_channel_c_start_int <= "0000000000000000000000000000";
    fd_channel_f_start_int <= "000000000000";
    fd_channel_u_endh_int <= "00000000";
    fd_channel_u_endl_int <= "00000000000000000000000000000000";
    fd_channel_c_end_int <= "0000000000000000000000000000";
    fd_channel_f_end_int <= "000000000000";
    fd_channel_u_delta_int <= "0000";
    fd_channel_c_delta_int <= "0000000000000000000000000000";
    fd_channel_f_delta_int <= "000000000000";
    fd_channel_rcr_rep_cnt_int <= "0000000000000000";
    fd_channel_rcr_cont_int <= '0';
  elsif rising_edge(clk_sys_i) then
-- advance the ACK generator shift register
    ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
    ack_sreg(9) <= '0';
    if (ack_in_progress = '1') then
      if (ack_sreg(0) = '1') then
        ack_in_progress <= '0';
      else
        fd_channel_dcr_pg_arm_int <= fd_channel_dcr_pg_arm_int_delay;
        fd_channel_dcr_pg_arm_int_delay <= '0';
        fd_channel_dcr_update_int <= fd_channel_dcr_update_int_delay;
        fd_channel_dcr_update_int_delay <= '0';
        fd_channel_dcr_force_dly_int <= fd_channel_dcr_force_dly_int_delay;
        fd_channel_dcr_force_dly_int_delay <= '0';
        fd_channel_frr_swb <= fd_channel_frr_swb_delay;
        fd_channel_frr_swb_delay <= '0';
      end if;
    else
      if ((wb_cyc_i = '1') and (wb_stb_i = '1')) then
        case rwaddr_reg(3 downto 0) is
        when "0000" => 
          if (wb_we_i = '1') then
            fd_channel_dcr_enable_int <= wrdata_reg(0);
            fd_channel_dcr_mode_int <= wrdata_reg(1);
            fd_channel_dcr_pg_arm_int <= wrdata_reg(2);
            fd_channel_dcr_pg_arm_int_delay <= wrdata_reg(2);
            fd_channel_dcr_update_int <= wrdata_reg(4);
            fd_channel_dcr_update_int_delay <= wrdata_reg(4);
            fd_channel_dcr_force_dly_int <= wrdata_reg(6);
            fd_channel_dcr_force_dly_int_delay <= wrdata_reg(6);
            fd_channel_dcr_no_fine_int <= wrdata_reg(7);
            fd_channel_dcr_force_hi_int <= wrdata_reg(8);
          end if;
          rddata_reg(0) <= fd_channel_dcr_enable_int;
          rddata_reg(1) <= fd_channel_dcr_mode_int;
          rddata_reg(2) <= '0';
          rddata_reg(3) <= fd_channel_dcr_pg_trig_sync1;
          rddata_reg(4) <= '0';
          rddata_reg(5) <= fd_channel_dcr_upd_done_sync1;
          rddata_reg(6) <= '0';
          rddata_reg(7) <= fd_channel_dcr_no_fine_int;
          rddata_reg(8) <= fd_channel_dcr_force_hi_int;
          rddata_reg(9) <= 'X';
          rddata_reg(10) <= 'X';
          rddata_reg(11) <= 'X';
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(4) <= '1';
          ack_in_progress <= '1';
        when "0001" => 
          if (wb_we_i = '1') then
            fd_channel_frr_int <= wrdata_reg(9 downto 0);
            fd_channel_frr_swb <= '1';
            fd_channel_frr_swb_delay <= '1';
          end if;
          rddata_reg(9 downto 0) <= fd_channel_frr_int;
          rddata_reg(10) <= 'X';
          rddata_reg(11) <= 'X';
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(3) <= '1';
          ack_in_progress <= '1';
        when "0010" => 
          if (wb_we_i = '1') then
            fd_channel_u_starth_int <= wrdata_reg(7 downto 0);
          end if;
          rddata_reg(7 downto 0) <= fd_channel_u_starth_int;
          rddata_reg(8) <= 'X';
          rddata_reg(9) <= 'X';
          rddata_reg(10) <= 'X';
          rddata_reg(11) <= 'X';
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "0011" => 
          if (wb_we_i = '1') then
            fd_channel_u_startl_int <= wrdata_reg(31 downto 0);
          end if;
          rddata_reg(31 downto 0) <= fd_channel_u_startl_int;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "0100" => 
          if (wb_we_i = '1') then
            fd_channel_c_start_int <= wrdata_reg(27 downto 0);
          end if;
          rddata_reg(27 downto 0) <= fd_channel_c_start_int;
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "0101" => 
          if (wb_we_i = '1') then
            fd_channel_f_start_int <= wrdata_reg(11 downto 0);
          end if;
          rddata_reg(11 downto 0) <= fd_channel_f_start_int;
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "0110" => 
          if (wb_we_i = '1') then
            fd_channel_u_endh_int <= wrdata_reg(7 downto 0);
          end if;
          rddata_reg(7 downto 0) <= fd_channel_u_endh_int;
          rddata_reg(8) <= 'X';
          rddata_reg(9) <= 'X';
          rddata_reg(10) <= 'X';
          rddata_reg(11) <= 'X';
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "0111" => 
          if (wb_we_i = '1') then
            fd_channel_u_endl_int <= wrdata_reg(31 downto 0);
          end if;
          rddata_reg(31 downto 0) <= fd_channel_u_endl_int;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "1000" => 
          if (wb_we_i = '1') then
            fd_channel_c_end_int <= wrdata_reg(27 downto 0);
          end if;
          rddata_reg(27 downto 0) <= fd_channel_c_end_int;
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "1001" => 
          if (wb_we_i = '1') then
            fd_channel_f_end_int <= wrdata_reg(11 downto 0);
          end if;
          rddata_reg(11 downto 0) <= fd_channel_f_end_int;
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "1010" => 
          if (wb_we_i = '1') then
            fd_channel_u_delta_int <= wrdata_reg(3 downto 0);
          end if;
          rddata_reg(3 downto 0) <= fd_channel_u_delta_int;
          rddata_reg(4) <= 'X';
          rddata_reg(5) <= 'X';
          rddata_reg(6) <= 'X';
          rddata_reg(7) <= 'X';
          rddata_reg(8) <= 'X';
          rddata_reg(9) <= 'X';
          rddata_reg(10) <= 'X';
          rddata_reg(11) <= 'X';
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "1011" => 
          if (wb_we_i = '1') then
            fd_channel_c_delta_int <= wrdata_reg(27 downto 0);
          end if;
          rddata_reg(27 downto 0) <= fd_channel_c_delta_int;
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "1100" => 
          if (wb_we_i = '1') then
            fd_channel_f_delta_int <= wrdata_reg(11 downto 0);
          end if;
          rddata_reg(11 downto 0) <= fd_channel_f_delta_int;
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "1101" => 
          if (wb_we_i = '1') then
            fd_channel_rcr_rep_cnt_int <= wrdata_reg(15 downto 0);
            fd_channel_rcr_cont_int <= wrdata_reg(16);
          end if;
          rddata_reg(15 downto 0) <= fd_channel_rcr_rep_cnt_int;
          rddata_reg(16) <= fd_channel_rcr_cont_int;
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when others =>
-- prevent the slave from hanging the bus on invalid address
          ack_in_progress <= '1';
          ack_sreg(0) <= '1';
        end case;
      end if;
    end if;
  end if;
end process;


-- Drive the data output bus
wb_dat_o <= rddata_reg;
-- Enable channel
-- synchronizer chain for field : Enable channel (type RW/RO, clk_sys_i <-> clk_ref_i)
process (clk_ref_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    regs_o.dcr_enable_o <= '0';
    fd_channel_dcr_enable_sync0 <= '0';
    fd_channel_dcr_enable_sync1 <= '0';
  elsif rising_edge(clk_ref_i) then
    fd_channel_dcr_enable_sync0 <= fd_channel_dcr_enable_int;
    fd_channel_dcr_enable_sync1 <= fd_channel_dcr_enable_sync0;
    regs_o.dcr_enable_o <= fd_channel_dcr_enable_sync1;
  end if;
end process;


-- Delay mode select
regs_o.dcr_mode_o <= fd_channel_dcr_mode_int;
-- Pulse generator arm
process (clk_ref_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    regs_o.dcr_pg_arm_o <= '0';
    fd_channel_dcr_pg_arm_sync0 <= '0';
    fd_channel_dcr_pg_arm_sync1 <= '0';
    fd_channel_dcr_pg_arm_sync2 <= '0';
  elsif rising_edge(clk_ref_i) then
    fd_channel_dcr_pg_arm_sync0 <= fd_channel_dcr_pg_arm_int;
    fd_channel_dcr_pg_arm_sync1 <= fd_channel_dcr_pg_arm_sync0;
    fd_channel_dcr_pg_arm_sync2 <= fd_channel_dcr_pg_arm_sync1;
    regs_o.dcr_pg_arm_o <= fd_channel_dcr_pg_arm_sync2 and (not fd_channel_dcr_pg_arm_sync1);
  end if;
end process;


-- Pulse generator triggered
-- synchronizer chain for field : Pulse generator triggered (type RO/WO, clk_ref_i -> clk_sys_i)
process (clk_ref_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    fd_channel_dcr_pg_trig_sync0 <= '0';
    fd_channel_dcr_pg_trig_sync1 <= '0';
  elsif rising_edge(clk_ref_i) then
    fd_channel_dcr_pg_trig_sync0 <= regs_i.dcr_pg_trig_i;
    fd_channel_dcr_pg_trig_sync1 <= fd_channel_dcr_pg_trig_sync0;
  end if;
end process;


-- Update delay/absolute trigger time
process (clk_ref_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    regs_o.dcr_update_o <= '0';
    fd_channel_dcr_update_sync0 <= '0';
    fd_channel_dcr_update_sync1 <= '0';
    fd_channel_dcr_update_sync2 <= '0';
  elsif rising_edge(clk_ref_i) then
    fd_channel_dcr_update_sync0 <= fd_channel_dcr_update_int;
    fd_channel_dcr_update_sync1 <= fd_channel_dcr_update_sync0;
    fd_channel_dcr_update_sync2 <= fd_channel_dcr_update_sync1;
    regs_o.dcr_update_o <= fd_channel_dcr_update_sync2 and (not fd_channel_dcr_update_sync1);
  end if;
end process;


-- Delay update done flag
-- synchronizer chain for field : Delay update done flag (type RO/WO, clk_ref_i -> clk_sys_i)
process (clk_ref_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    fd_channel_dcr_upd_done_sync0 <= '0';
    fd_channel_dcr_upd_done_sync1 <= '0';
  elsif rising_edge(clk_ref_i) then
    fd_channel_dcr_upd_done_sync0 <= regs_i.dcr_upd_done_i;
    fd_channel_dcr_upd_done_sync1 <= fd_channel_dcr_upd_done_sync0;
  end if;
end process;


-- Force calibration delay
process (clk_ref_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    regs_o.dcr_force_dly_o <= '0';
    fd_channel_dcr_force_dly_sync0 <= '0';
    fd_channel_dcr_force_dly_sync1 <= '0';
    fd_channel_dcr_force_dly_sync2 <= '0';
  elsif rising_edge(clk_ref_i) then
    fd_channel_dcr_force_dly_sync0 <= fd_channel_dcr_force_dly_int;
    fd_channel_dcr_force_dly_sync1 <= fd_channel_dcr_force_dly_sync0;
    fd_channel_dcr_force_dly_sync2 <= fd_channel_dcr_force_dly_sync1;
    regs_o.dcr_force_dly_o <= fd_channel_dcr_force_dly_sync2 and (not fd_channel_dcr_force_dly_sync1);
  end if;
end process;


-- Disable fine part update
regs_o.dcr_no_fine_o <= fd_channel_dcr_no_fine_int;
-- Force output high
regs_o.dcr_force_hi_o <= fd_channel_dcr_force_hi_int;
-- Fine range in SY89825 taps.
-- asynchronous std_logic_vector register : Fine range in SY89825 taps. (type RW/RO, clk_ref_i <-> clk_sys_i)
process (clk_ref_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    fd_channel_frr_swb_s0 <= '0';
    fd_channel_frr_swb_s1 <= '0';
    fd_channel_frr_swb_s2 <= '0';
    regs_o.frr_o <= "0000000000";
  elsif rising_edge(clk_ref_i) then
    fd_channel_frr_swb_s0 <= fd_channel_frr_swb;
    fd_channel_frr_swb_s1 <= fd_channel_frr_swb_s0;
    fd_channel_frr_swb_s2 <= fd_channel_frr_swb_s1;
    if ((fd_channel_frr_swb_s2 = '0') and (fd_channel_frr_swb_s1 = '1')) then
      regs_o.frr_o <= fd_channel_frr_int;
    end if;
  end if;
end process;


-- TAI seconds (MSB)
regs_o.u_starth_o <= fd_channel_u_starth_int;
-- TAI seconds (LSB)
regs_o.u_startl_o <= fd_channel_u_startl_int;
-- Reference clock cycles
regs_o.c_start_o <= fd_channel_c_start_int;
-- Fractional part
regs_o.f_start_o <= fd_channel_f_start_int;
-- TAI seconds (MSB)
regs_o.u_endh_o <= fd_channel_u_endh_int;
-- TAI seconds (LSB)
regs_o.u_endl_o <= fd_channel_u_endl_int;
-- Reference clock cycles
regs_o.c_end_o <= fd_channel_c_end_int;
-- Fractional part
regs_o.f_end_o <= fd_channel_f_end_int;
-- TAI seconds
regs_o.u_delta_o <= fd_channel_u_delta_int;
-- Reference clock cycles
regs_o.c_delta_o <= fd_channel_c_delta_int;
-- Fractional part
regs_o.f_delta_o <= fd_channel_f_delta_int;
-- Repeat Count
regs_o.rcr_rep_cnt_o <= fd_channel_rcr_rep_cnt_int;
-- Continuous Waveform Mode
regs_o.rcr_cont_o <= fd_channel_rcr_cont_int;
rwaddr_reg <= wb_adr_i;
wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
wb_err_o <= '0';
wb_rty_o <= '0';
-- ACK signal generation. Just pass the LSB of ACK counter.
wb_ack_o <= ack_sreg(0);
end syn;
