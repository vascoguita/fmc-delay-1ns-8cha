// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: CERN-OHL-W-2.0+

`timescale 10fs/10fs

`include "acam_model.svh"
`include "tunable_clock_gen.svh"
`include "random_pulse_gen.svh"
`include "jittery_delay.svh"
`include "ideal_timestamper.svh"
`include "mc100ep195.vh"

`include "regs/fd_main_regs.vh"
`include "regs/fd_channel_regs.vh"

`include "wb/simdrv_defs.svh"
`include "wb/if_wb_master.svh"

`timescale 10fs/10fs

interface IAcamDirect;
   logic [3:0] addr;
endinterface // IAcamDirect

typedef virtual IAcamDirect VIAcamDirect;


module clock_reset_gen
  (
   output     clk_sys_o,
   output     clk_ref_o,
   output     clk_tdc_o,
   output     clk_dmtd_o,
   output reg rst_n_o);
   
   parameter real g_ref_period 	= 8ns;
   parameter real g_dmtd_period = 15.9ns;
   parameter real g_sys_period 	= 16.31ns;
   parameter real g_ref_jitter 	= 10ps;
   parameter real g_tdc_jitter 	= 10ps;
   
   reg enable 			= 0;
   wire clk_sys_buf;

   
   tunable_clock_gen
     #(
       .g_period(g_ref_period),
       .g_jitter(g_ref_jitter)
       )
    GEN_REF
      (
       .enable_i(enable),
       .clk_o(clk_ref_o)
       );

   tunable_clock_gen 
     #(
       .g_period(4.0 * g_ref_period),
       .g_jitter(g_tdc_jitter)
       ) 
   GEN_TDC 
     (
      .enable_i(enable),
      .clk_o(clk_tdc_o)
      );

   tunable_clock_gen 
     #(
       .g_period(g_sys_period),
       .g_jitter(0)
       )
   GEN_SYS 
     (
      .enable_i(enable),
      .clk_o(clk_sys_buf)
      );

   tunable_clock_gen 
     #(
       .g_period(g_dmtd_period),
       .g_jitter(0.01)
       )
   GEN_DMTD
     (
      .enable_i(enable),
      .clk_o(clk_dmtd_o)
      );

   
   assign clk_sys_o  = clk_sys_buf;

   initial begin
      rst_n_o 	     = 0;
      #20ns enable = 1;
      repeat(3) @(posedge clk_sys_buf);
      rst_n_o  = 1;
   end
   
endmodule  // clock_reset_gen

const int SPI_PLL  = 0;
const int SPI_GPIO  = 1;
const int SPI_DAC  = 2;

int dly_seed= 10;


class CSimDrv_FineDelay;
   protected CBusAccessor m_acc;
   protected VIAcamDirect m_acam;
   protected Timestamp ts_queue[$];

   const real c_acam_bin               = 27.012; // [ps]
   const real c_ref_period             = 8000; // [ps]
   const int c_frac_bits               = 12;
   const int c_scaler_shift            = 12;
   const int c_acam_start_offset       = 10000;
   const int c_acam_merge_c_threshold  = 1;
   const int c_acam_merge_f_threshold  = 2000;
   
   function new(CBusAccessor acc, input VIAcamDirect _acam);
      m_acc  = acc;
      m_acam = _acam;
   endfunction // new
   
   task acam_write(int addr, int value);
      m_acam.addr = addr;
      #10ns;
      m_acc.write(`ADDR_FD_TDR, value);
      m_acc.write(`ADDR_FD_TDCSR, `FD_TDCSR_WRITE);
   endtask // acam_write

   task acam_read(int addr, output int value);
      uint64_t rval;
      m_acam.addr = addr;
      #10ns;
      m_acc.write(`ADDR_FD_TDR, (addr<<28)); 
      m_acc.write(`ADDR_FD_TDCSR, `FD_TDCSR_READ);
      #(500ns);
      m_acc.read(`ADDR_FD_TDR, rval);
      value           = rval;
   endtask // acam_read


   task get_time(ref Timestamp t);
      uint64_t tcr, secl, sech, cycles;
      
      m_acc.read(`ADDR_FD_TCR, tcr);
      m_acc.write(`ADDR_FD_TCR, tcr | `FD_TCR_CAP_TIME);
      m_acc.read(`ADDR_FD_TM_SECL, secl);
      m_acc.read(`ADDR_FD_TM_SECH, sech);
      m_acc.read(`ADDR_FD_TM_CYCLES, cycles);
      
      t.utc = (sech << 32) | secl;
      t.coarse = cycles;
      t.frac = 0;
   endtask // get_time

   task set_time(Timestamp t);
      uint64_t tcr;
      
      m_acc.read(`ADDR_FD_TCR, tcr);
      m_acc.write(`ADDR_FD_TM_SECL, t.utc & 32'hffffffff);
      m_acc.write(`ADDR_FD_TM_SECH, t.utc >> 32);
      m_acc.write(`ADDR_FD_TM_CYCLES, t.coarse);
      m_acc.write(`ADDR_FD_TCR, tcr | `FD_TCR_SET_TIME);
   endtask // set_time
   

   task set_reference(int wr);
      if(wr)
        begin
           uint64_t rval;
           
           $display("Enabling White Rabbit time reference...");
           m_acc.write(`ADDR_FD_TCR, `FD_TCR_WR_ENABLE);
           forever begin
              m_acc.read(`ADDR_FD_TCR, rval);
              if(rval & `FD_TCR_WR_LOCKED) break;
           end
           $display("WR Locked");
        end
      else begin
         Timestamp t = new(0,0,0);
         set_time(t);
         end
      endtask // set_reference
   

   task rbuf_update();
      Timestamp ts;
      uint64_t utc, coarse, seq_frac, stat, sech, secl;

      m_acc.read(`ADDR_FD_TSBCR, stat);

      if((stat & `FD_TSBCR_EMPTY) == 0) begin

         m_acc.write(`ADDR_FD_TSBR_ADVANCE, 1);
         
         m_acc.read(`ADDR_FD_TSBR_SECH, sech);
         m_acc.read(`ADDR_FD_TSBR_SECL, secl);
         m_acc.read(`ADDR_FD_TSBR_CYCLES,   coarse);
         m_acc.read(`ADDR_FD_TSBR_FID,  seq_frac);
         
         ts         = new (0,0,0);

         ts.source = seq_frac & 'h7;
         ts.utc     = (sech << 32) | secl;
         ts.coarse  = coarse & 'hfffffff;
         ts.seq_id  = (seq_frac >> 16) & 'hffff;
         ts.frac    = (seq_frac>>4) & 'hfff;
         ts_queue.push_back(ts);
         
      end
   endtask // rbuf_read

   function int poll();
      return (ts_queue.size() > 0);
   endfunction // poll

   function Timestamp get();
      return ts_queue.pop_front();
   endfunction // get
   
    
   typedef enum 
        {
         DELAY = 0,
         PULSE_GEN = 1
         } channel_mode_t;
      
  
   task config_output( int channel,channel_mode_t mode, int enable, Timestamp start_delay, uint64_t width_ps, uint64_t delta_ps=0, int rep_count=1);
      uint64_t dcr, base, rep;
      Timestamp t_start, t_end, t_delta, t_width;

      t_width = new;
      t_width.unflatten(int'(real'(width_ps) * 4096.0 / 8000.0));
      t_start  = start_delay;
      t_end  = start_delay.add(t_width);
      t_delta  = new;
      t_delta.unflatten(int'(real'(delta_ps) * 4096.0 / 8000.0));

      base = 'h100 + 'h100 * channel;
      
      m_acc.write(base + `ADDR_FD_FRR, 800);
      m_acc.write(base + `ADDR_FD_U_STARTH, t_start.utc >> 32);
      m_acc.write(base + `ADDR_FD_U_STARTL, t_start.utc & 'hffffffff);
      m_acc.write(base + `ADDR_FD_C_START, t_start.coarse);
      m_acc.write(base + `ADDR_FD_F_START, t_start.frac);
      m_acc.write(base + `ADDR_FD_U_ENDH, t_end.utc >> 32);
      m_acc.write(base + `ADDR_FD_U_ENDL, t_end.utc & 'hffffffff);
      m_acc.write(base + `ADDR_FD_C_END, t_end.coarse);
      m_acc.write(base + `ADDR_FD_F_END, t_end.frac);
      m_acc.write(base + `ADDR_FD_U_DELTA, t_delta.utc & 'hf);
      m_acc.write(base + `ADDR_FD_C_DELTA, t_delta.coarse);
      m_acc.write(base + `ADDR_FD_F_DELTA, t_delta.frac);

      if(rep_count < 0)
        rep = `FD_RCR_CONT;
      else
        rep = (rep_count-1) << `FD_RCR_REP_CNT_OFFSET;
  
      m_acc.write(base + `ADDR_FD_RCR, rep);
      

      dcr  = (enable? `FD_DCR_ENABLE : 0) | `FD_DCR_UPDATE ;
      if(mode == PULSE_GEN)
                  dcr |= `FD_DCR_MODE;
      if((width_ps < 200000) || (((delta_ps-width_ps) < 150000) && (rep_count > 1)))
        dcr |= `FD_DCR_NO_FINE;
      
      m_acc.write('h100 + 'h100 * channel + `ADDR_FD_DCR, dcr);
      if(mode == PULSE_GEN)
        m_acc.write('h100 + 'h100 * channel + `ADDR_FD_DCR, dcr | `FD_DCR_PG_ARM);
   endtask // config_output
   
   task init();
      int rval;
      Timestamp t = new;
            
      m_acc.write(`ADDR_FD_RSTR, 'hdeadffff); /* Un-reset the card */

      
      m_acc.write(`ADDR_FD_TDCSR, `FD_TDCSR_START_DIS | `FD_TDCSR_STOP_DIS);
      m_acc.write(`ADDR_FD_GCR, `FD_GCR_BYPASS);

      acam_write(5, c_acam_start_offset); // set StartOffset
      acam_read(5, rval);

      m_acam.addr= 8; /* permanently select FIFO1 */

      // Clear the ring buffer
      m_acc.write(`ADDR_FD_TSBCR, `FD_TSBCR_ENABLE | `FD_TSBCR_PURGE | `FD_TSBCR_RST_SEQ | (3 << `FD_TSBCR_CHAN_MASK_OFFSET));

      m_acc.write(`ADDR_FD_ADSFR, int' (real'(1<< (c_frac_bits + c_scaler_shift)) * c_acam_bin / c_ref_period));

      m_acc.write(`ADDR_FD_ASOR, c_acam_start_offset * 3);
      m_acc.write(`ADDR_FD_ATMCR, c_acam_merge_c_threshold | (c_acam_merge_f_threshold << 4));
      
      // Enable trigger input
      m_acc.write(`ADDR_FD_GCR,  0);
      
      t.utc = 0;
      t.coarse = 0;
      set_time(t);
      
      // Enable trigger input
      m_acc.write(`ADDR_FD_GCR,  `FD_GCR_INPUT_EN);
   endtask // init

   task force_cal_pulse(int channel, int delay_setpoint);
      m_acc.write(`ADDR_FD_FRR + (channel * 'h20), delay_setpoint);
      m_acc.write(`ADDR_FD_DCR + (channel * 'h20), `FD_DCR_FORCE_DLY);
      m_acc.write(`ADDR_FD_CALR, `FD_CALR_CAL_PULSE | ((1<<channel) << `FD_CALR_PSEL_OFFSET));
   endtask // force_cal_pulse
   
endclass // CSimDrv_FineDelay


module wr_time_counter 
  (
   input clk_ref_i,
   input rst_n_i,
   output [39:0] wr_utc_o,
   output [27:0] wr_coarse_o,
   output reg wr_time_valid_o
   );

   parameter g_coarse_range  = 125000000;
   
   reg [39:0] utc;
   reg [27:0] coarse;

   always@(posedge clk_ref_i)
     if (!rst_n_i)
       begin
          coarse          <= 0;
          utc             <= 0;
          wr_time_valid_o <= 0;
       end else begin
          if(coarse == g_coarse_range - 1)
            begin
               coarse     <= 0;
               utc        <=utc + 1;
            end else 
              coarse      <= coarse+ 1;

          wr_time_valid_o <= 1;
       end

   assign wr_utc_o               = utc;
   assign wr_coarse_o            = coarse;
   
endmodule // wr_time_counter

  
module main;

   wire clk_sys, clk_ref, clk_tdc, clk_dmtd, rst_n;

   wire trig_a;
   wire trig_cal;
   wire acam_wr_n;
   wire acam_cs_n;
   wire acam_rd_n;
   wire acam_oe_n = 1'b1; 
   wire [3:0] acam_adr;
   wire [27:0] acam_data;
   wire [27:0] tdc_d_o;
   wire tdc_d_oe;
   wire acam_start_dis;
   wire [4:1] acam_stop_dis;
   wire acam_alutrigger;
   wire trig_a_n_delayed;
   wire tdc_start_delayed;

   wire [39:0] wr_utc;
   wire [27:0] wr_coarse;
   wire wr_time_valid;
   
   reg [3:0] tdc_start_div = 0;
   reg tdc_start    = 0;

   wire trig_a_muxed;
   wire trig_cal_fpga, trig_a_lemo;
   reg  trig_cal_sel = 1;

   always@(posedge clk_ref) begin
      tdc_start_div <= tdc_start_div + 1;
      tdc_start    <= tdc_start_div[3];
   end

   IWishboneMaster
     #(
       .g_addr_width(32),
       .g_data_width(32)
       ) wb_master 
       (
        .clk_i(clk_sys),
        .rst_n_i(rst_n)
        );
   
   clock_reset_gen
     CLK_GEN
     (
      .clk_sys_o(clk_sys),
      .clk_ref_o(clk_ref),
      .clk_tdc_o(clk_tdc),
      .clk_dmtd_o(clk_dmtd),
      .rst_n_o(rst_n)
      );

   
   
   wr_time_counter
     time_counter 
       (
        .clk_ref_i(clk_ref),
        .rst_n_i(rst_n),
        .wr_utc_o(wr_utc),
        .wr_coarse_o(wr_coarse),
        .wr_time_valid_o(wr_time_valid)
        );

   random_pulse_gen
     #(
       .g_pulse_width(40ns),
       .g_min_spacing(5000.111ns),
       .g_max_spacing(5010.112ns)
       )
     TRIG_GEN
       (
	.enable_i(1'b1),
	.pulse_o(trig_a_lemo)
	);

//   assign trig_a  = 0;

   reg wr_time_valid_d0;

   always@(posedge clk_ref)
     wr_time_valid_d0 <= wr_time_valid;
   
   ideal_timestamper
     IDEAL_TSU
       (
	.rst_n_i(rst_n),
	.clk_ref_i(clk_ref),
	.enable_i(~acam_stop_dis[1]),
	.trig_a_i(trig_a_lemo),
        .csync_p1_i(wr_time_valid & !wr_time_valid_d0),
        .csync_utc_i(wr_utc),
        .csync_coarse_i(wr_coarse)
	);

   IAcamDirect acam_direct();


   assign trig_a_muxed = (trig_cal_sel ? trig_a_lemo : trig_cal_fpga);
   
   
   acam_model
     #(
       .g_verbose(0)
       ) ACAM (
      .PuResN(rst_n),
      .Alutrigger(acam_alutrigger),
      .RefClk (clk_tdc),

      .WRN(acam_wr_n),
      .RDN(acam_rd_n),
      .CSN(1'b0),
      .OEN(acam_rd_n),

      .Adr(acam_direct.addr),
      .D(acam_data),
	       
      .DStart(tdc_start),
      .DStop1(trig_a_muxed),
      .DStop2(1'b0),

	       
      .TStart(1'b0),
      .TStop(1'b0),

      .StartDis(acam_start_dis),
      .StopDis(acam_stop_dis),

      .IrFlag(),
      .ErrFlag(),

      .EF1 (acam_ef1),
      .LF1 ()

   );

   // tri-state driver for the data bus
   assign acam_data  = (tdc_d_oe ? tdc_d_o : 28'bz);

   
   jittery_delay 
     #(
       .g_delay(3ns),
       .g_jitter(10ps)
       ) 
   DLY_TRIG 
     (
      .in_i(~trig_a_muxed),
      .out_o(trig_a_n_delayed)
      );

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

   wire [3:0] delay_len, delay_pulse;
   wire [9:0] delay_val;
   wire [3:0] d_out;

   reg        dmtd_fb_in, dmtd_fb_out;
   wire       dmtd_samp;
   
   
   
   fine_delay_core
     #(
       .g_simulation(1),
       .g_with_wr_core(1))
     DUT (
	  .clk_ref_0_i(clk_ref),
	  .clk_ref_180_i(~clk_ref),
          .clk_dmtd_i(clk_dmtd),
	  .tdc_start_i(tdc_start),
	  .clk_sys_i(clk_sys),
	  .rst_n_i (rst_n),
	  .trig_a_i (~trig_a_n_delayed),
	  .tdc_cal_pulse_o (trig_cal_fpga),

	  .acam_d_o     (tdc_d_o),
	  .acam_d_i     (acam_data),
	  .acam_d_oen_o (tdc_d_oe),

	  .acam_emptyf_i (acam_ef1),
	  .acam_alutrigger_o  (acam_alutrigger),

	  .acam_wr_n_o (acam_wr_n),
	  .acam_rd_n_o (acam_rd_n),

	  .acam_start_dis_o (acam_start_dis),
	  .acam_stop_dis_o  (acam_stop_dis[1]),

	  .spi_cs_dac_n_o (),
	  .spi_cs_pll_n_o (), 
	  .spi_cs_gpio_n_o  (),

	  .spi_sclk_o (),
	  .spi_mosi_o (spi_loop),
	  .spi_miso_i (spi_loop),

	  .delay_len_o (delay_len),
	  .delay_val_o (delay_val),
	  .delay_pulse_o (delay_pulse),

          .tm_utc_i(wr_utc),
          .tm_cycles_i(wr_coarse),
          .tm_time_valid_i(wr_time_valid),
          .tm_link_up_i(1'b1),
          .tm_clk_aux_locked_i(1'b1),
          
          .dmtd_samp_o(dmtd_samp),
          .dmtd_fb_in_i(dmtd_fb_in),
          .dmtd_fb_out_i(dmtd_fb_out),
          
	  .wb_adr_i (wb_master.adr[31:0]),
	  .wb_dat_i (wb_master.dat_o),
	  .wb_dat_o (wb_master.dat_i),
	  .wb_cyc_i (wb_master.cyc),
	  .wb_stb_i (wb_master.stb),
	  .wb_we_i  (wb_master.we),
	  .wb_ack_o (wb_master.ack),
          .wb_stall_o(wb_master.stall)
          
	  );


   
   mc100ep195
     U_delay_line0(
                 .len(delay_len[0]),
                 .i(delay_pulse[0]),
                 .delay(delay_val),
                 .o(d_out[0])
                 ); mc100ep195

     U_delay_line1(
                 .len(delay_len[1]),
                 .i(delay_pulse[1]),
                 .delay(delay_val),
                 .o(d_out[1])
                 );

     ideal_timestamper
     Output_TSU0
       (
	.rst_n_i(rst_n),
	.clk_ref_i(clk_ref),
	.enable_i(~acam_stop_dis[1]),
	.trig_a_i(d_out[0]),
        .csync_p1_i(wr_time_valid & !wr_time_valid_d0),
        .csync_utc_i(wr_utc),
        .csync_coarse_i(wr_coarse)
	);
   
     ideal_timestamper
     Output_TSU1
       (
	.rst_n_i(rst_n),
	.clk_ref_i(clk_ref),
	.enable_i(~acam_stop_dis[1]),
	.trig_a_i(d_out[1]),
        .csync_p1_i(wr_time_valid & !wr_time_valid_d0),
        .csync_utc_i(wr_utc),
        .csync_coarse_i(wr_coarse)
	);
   
   const uint64_t c_coarse_range  = 256;

   Timestamp ts_queue[$];


   /* DMTD Calibrator */

   reg [3:0]  dmtd_out_chx;
   
   
   always@(posedge dmtd_samp)
     begin
        dmtd_fb_in <= ~trig_a_muxed;
        dmtd_out_chx[0] <= ~d_out[0];
        dmtd_out_chx[1] <= ~d_out[1];
     end
  
 assign dmtd_fb_out = dmtd_out_chx[0] & dmtd_out_chx[1];
   
   
   always@(posedge clk_ref)
     if(DUT.tag_valid)
       begin
          Timestamp t;
          t  = new(signed'(DUT.tag_utc), signed'(DUT.tag_coarse), DUT.tag_frac);
          ts_queue.push_back(t);
       end
   
   CSimDrv_FineDelay fd_drv;
   CWishboneAccessor wb;
   
   initial begin
      uint64_t rval;
      Timestamp t_cur = new; 
      

      wait(rst_n != 0);
      @(posedge clk_sys);
      

      $display("Initializing FD Testbench!");

      wb      = wb_master.get_accessor();
      wb_master.settings.cyc_on_stall = 1;
      
      wb.set_mode(PIPELINED);
      
      fd_drv  = new(wb, VIAcamDirect'(acam_direct));
      fd_drv.init();
      fd_drv.get_time(t_cur);

      fd_drv.set_reference(1);


      $display("GetTime: %d:%d",t_cur.utc, t_cur.coarse);


      t_cur.unflatten(600000.0 * 4096.0 / 8000.0);
      fd_drv.config_output(0, CSimDrv_FineDelay::DELAY, 1, t_cur, 200000, 100000, 1);

      wb.write(`ADDR_FD_CALR, `FD_CALR_CAL_DMTD);
      trig_cal_sel = 0;
      
      
      
      forever fd_drv.rbuf_update();
   end

   Timestamp prev  = null;

   int prev_seqid = -1;
   
   
   always@(posedge clk_ref) 
     if (fd_drv != null)
       begin
          if(fd_drv.poll())
            begin
               Timestamp t_acam;
               t_acam   = fd_drv.get();
               $display("TS: seq %d [%d:%d:%d src %d]", t_acam.seq_id, t_acam.utc, t_acam.coarse, t_acam.frac, t_acam.source);

               if((prev_seqid+1)&'hffff != t_acam.seq_id)
                 begin
                    $error("Seqid mismatch");
                    $stop;
                 end
            end
       end
   
endmodule // main

