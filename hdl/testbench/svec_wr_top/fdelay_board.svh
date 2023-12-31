// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: CERN-OHL-W-2.0+

`timescale 10fs/10fs

`include "acam_model.svh"
`include "tunable_clock_gen.svh"
`include "random_pulse_gen.svh"
`include "jittery_delay.svh"
`include "mc100ep195.vh"

`include "simdrv_defs.svh"
`include "if_wb_master.svh"

`timescale 10fs/10fs

module trivial_spi_gpio(input sclk, cs_n, mosi, output reg [7:0] gpio);

   int bit_count = 0;
   reg [7:0] sreg;
   
   always@(negedge cs_n)
     bit_count <= 0;

   always@(posedge sclk)
     begin
        bit_count <= bit_count + 1;
        sreg <= { sreg[6:0], mosi };
     end

   always@(posedge cs_n)
     if(bit_count == 24)
       gpio <= sreg[7:0];

   initial gpio = 0;
   
endmodule // trivial_spi


/* Board-level wrapper */

interface IFineDelayFMC;

   wire tdc_start_p;
   wire tdc_start_n;
   wire clk_ref_p;
   wire clk_ref_n;
   wire trig_a;
   wire tdc_cal_pulse;
   wire [27:0] tdc_d;
   wire        tdc_emptyf;
   wire        tdc_alutrigger;
   wire        tdc_wr_n;
   wire        tdc_rd_n;
   wire        tdc_oe_n;
   wire        led_trig;
   wire        tdc_start_dis;
   wire        tdc_stop_dis;
   wire        spi_cs_dac_n;
   wire        spi_cs_pll_n;
   wire        spi_cs_gpio_n;
   wire        spi_sclk;
   wire        spi_mosi;
   wire        spi_miso;
   wire [3:0]  delay_len;
   wire [9:0]  delay_val;
   wire [3:0]  delay_pulse;

   wire dmtd_clk;
   wire dmtd_fb_in;
   wire dmtd_fb_out;
   
   wire pll_status;
   wire ext_rst_n;
   wire onewire;

   modport board
     (
      output tdc_start_p, tdc_start_n, clk_ref_p, clk_ref_n, trig_a, spi_miso, 
      tdc_emptyf, dmtd_fb_in, dmtd_fb_out, pll_status,
      input  tdc_cal_pulse, tdc_wr_n, tdc_rd_n, tdc_oe_n, tdc_alutrigger, led_trig, tdc_start_dis, 
      tdc_stop_dis, spi_cs_dac_n, spi_cs_pll_n, spi_cs_gpio_n, spi_sclk, spi_mosi, 
      delay_len, delay_val, delay_pulse, dmtd_clk, ext_rst_n,
      inout  onewire, tdc_d);

   modport core
     (
      input tdc_start_p, tdc_start_n, clk_ref_p, clk_ref_n, trig_a, spi_miso, 
      tdc_emptyf, dmtd_fb_in, dmtd_fb_out, pll_status,
      output  tdc_cal_pulse, tdc_wr_n, tdc_rd_n, tdc_oe_n, tdc_alutrigger, led_trig, tdc_start_dis, 
      tdc_stop_dis, spi_cs_dac_n, spi_cs_pll_n, spi_cs_gpio_n, spi_sclk, spi_mosi, 
      delay_len, delay_val, delay_pulse, dmtd_clk, ext_rst_n,
      inout  onewire, tdc_d);
   
endinterface // IFineDelayFMC


module fdelay_board (
                     input        trig_i,
                     output [3:0] out_o,
                     IFineDelayFMC.board fmc
);

   reg                            clk_ref_250 = 0;
   reg                            clk_ref_125 = 0;
   reg                            clk_tdc = 0;
   reg [3:0]                      tdc_start_div = 0;
   reg                            tdc_start;
   
   

   always #(4ns / 2) clk_ref_250 <= ~clk_ref_250;
   always@(posedge clk_ref_250) clk_ref_125 <= ~clk_ref_125;

   always #(32ns / 2) clk_tdc <= ~clk_tdc;
   
   assign fmc.clk_ref_p = clk_ref_125;
   assign fmc.clk_ref_n = ~clk_ref_125;
   
   always@(posedge clk_ref_125) begin
      tdc_start_div <= tdc_start_div + 1;
      tdc_start    <= tdc_start_div[3];
   end

   assign fmc.tdc_start_p = tdc_start;
   assign fmc.tdc_start_n = ~tdc_start;
   
   wire trig_a_muxed;
   wire [7:0] spi_gpio_out;

   wire       trig_cal_sel = 1'b1;
   
   
   assign trig_a_muxed = (trig_cal_sel ? trig_i : fmc.tdc_cal_pulse);

   trivial_spi_gpio
     SPI_GPIO (
               .sclk(fmc.spi_sclk),
               .cs_n(fmc.spi_cs_gpio_n),
               .mosi(fmc.spi_mosi),
               .gpio(spi_gpio_out));

   acam_model
     #(
       .g_verbose(0)
       ) ACAM (
      .PuResN(fmc.ext_rst_n),
      .Alutrigger(fmc.tdc_alutrigger),
      .RefClk (clk_tdc),

      .WRN(fmc.tdc_wr_n),
      .RDN(fmc.tdc_rd_n),
      .CSN(1'b0),
      .OEN(fmc.tdc_oe_n),

      .Adr(spi_gpio_out[3:0]),
      .D(fmc.tdc_d),
	       
      .DStart(tdc_start_delayed),
      .DStop1(trig_a_muxed),
      .DStop2(1'b0),
	       
      .TStart(1'b0),
      .TStop(1'b0),

      .StartDis(fmc.tdc_start_dis),
      .StopDis(fmc.tdc_stop_dis),

      .IrFlag(),
      .ErrFlag(),

      .EF1 (fmc.tdc_emptyf),
      .LF1 ()

   );
   
   jittery_delay 
     #(
       .g_delay(3ns),
       .g_jitter(10ps)
       ) 
   DLY_TRIG 
     (
      .in_i(trig_a_muxed),
      .out_o(trig_a_n_delayed)
      );

   assign   fmc.trig_a = trig_a_n_delayed;
   
   
   jittery_delay 
     #(
       .g_delay(2.2ns),
       .g_jitter(10ps)
       ) 
   DLY_TDC_START
     (
      .in_i(tdc_start),
      .out_o(tdc_start_delayed)
      );

   genvar     gg;

   function bit[9:0] reverse_bits (bit [9:0] x);
      reg [9:0] tmp;
      int       i;

      for(i=0;i<10;i++)
        tmp[9-i]=x[i];
      
      
      return tmp;
   endfunction // reverse_bits
   

      
           
   mc100ep195
    U_delay_line0(
                  .len(fmc.delay_len[0]),
                  .i(fmc.delay_pulse[0]),
                  .delay(reverse_bits(fmc.delay_val)),
                  .o(out_o[0]));
   
   
endmodule // main

`define WIRE_FINE_DELAY_PINS(fmc_index,iface) \
.fmc``fmc_index``_fd_tdc_start_p_i (iface.core.tdc_start_p),    \
.fmc``fmc_index``_fd_tdc_start_n_i (iface.core.tdc_start_n),    \
.fmc``fmc_index``_fd_clk_ref_p_i   (iface.core.clk_ref_p),    \
.fmc``fmc_index``_fd_clk_ref_n_i   (iface.core.clk_ref_n),    \
.fmc``fmc_index``_fd_trig_a_i    (iface.core.trig_a),    \
.fmc``fmc_index``_fd_tdc_cal_pulse_o (iface.core.tdc_cal_pulse),    \
.fmc``fmc_index``_fd_tdc_d_b        (iface.core.tdc_d),    \
.fmc``fmc_index``_fd_tdc_emptyf_i   (iface.core.tdc_emptyf),    \
.fmc``fmc_index``_fd_tdc_alutrigger_o (iface.core.tdc_alutrigger),    \
.fmc``fmc_index``_fd_tdc_wr_n_o      (iface.core.tdc_wr_n),    \
.fmc``fmc_index``_fd_tdc_rd_n_o      (iface.core.tdc_rd_n),    \
.fmc``fmc_index``_fd_tdc_oe_n_o      (iface.core.tdc_oe_n),    \
.fmc``fmc_index``_fd_led_trig_o      (iface.core.led_trig),    \
.fmc``fmc_index``_fd_tdc_start_dis_o (iface.core.tdc_start_dis),    \
.fmc``fmc_index``_fd_tdc_stop_dis_o  (iface.core.tdc_stop_dis),    \
.fmc``fmc_index``_fd_spi_cs_dac_n_o  (iface.core.spi_cs_dac_n),    \
.fmc``fmc_index``_fd_spi_cs_pll_n_o  (iface.core.spi_cs_pll_n),    \
.fmc``fmc_index``_fd_spi_cs_gpio_n_o  (iface.core.spi_cs_gpio_n),    \
.fmc``fmc_index``_fd_spi_sclk_o       (iface.core.spi_sclk),    \
.fmc``fmc_index``_fd_spi_mosi_o       (iface.core.spi_mosi),    \
.fmc``fmc_index``_fd_spi_miso_i       (iface.core.spi_miso),    \
.fmc``fmc_index``_fd_delay_len_o     (iface.core.delay_len),    \
.fmc``fmc_index``_fd_delay_val_o      (iface.core.delay_val),    \
.fmc``fmc_index``_fd_delay_pulse_o    (iface.core.delay_pulse),    \
.fmc``fmc_index``_fd_dmtd_clk_o    (iface.core.dmtd_clk),    \
.fmc``fmc_index``_fd_dmtd_fb_in_i  (iface.core.dmtd_fb_in),    \
.fmc``fmc_index``_fd_dmtd_fb_out_i (iface.core.dmtd_fb_out),    \
.fmc``fmc_index``_fd_pll_status_i (iface.core.pll_status),    \
.fmc``fmc_index``_fd_ext_rst_n_o  (iface.core.ext_rst_n),    \
.fmc``fmc_index``_fd_onewire_b (iface.core.onewire)

