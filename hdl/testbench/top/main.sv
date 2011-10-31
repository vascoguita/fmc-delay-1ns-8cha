`timescale 10fs/10fs

`include "acam_model.sv"
`include "tunable_clock_gen.sv"
`include "random_pulse_gen.sv"
`include "jittery_delay.sv"
`include "fine_delay_regs.v"
`include "ideal_timestamper.sv"
`include "mc100ep195.sv"

`include "simdrv_defs.svh"
`include "wb/if_wb_master.svh"

`timescale 10fs/10fs

module clock_reset_gen
  (
   output clk_sys_o,
   output clk_ref_o,
   output clk_tdc_o,
   output reg rst_n_o);
   
   parameter real g_ref_period 	= 8ns;
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

class CSimDrv_FineDelay;
   protected CBusAccessor m_acc;

   protected Timestamp ts_queue[$];

   const real c_acam_bin               = 27.012; // [ps]
   const real c_ref_period             = 8000; // [ps]
   const int c_frac_bits               = 12;
   const int c_scaler_shift            = 12;
   const int c_acam_start_offset       = 10000;
   const int c_acam_merge_c_threshold  = 1;
   const int c_acam_merge_f_threshold  = 2000;
   
   function new(CBusAccessor acc);
      m_acc  = acc;
   endfunction // new
   
   task acam_write(int addr, int value);
      m_acc.write(`ADDR_FD_TAR, (addr<<28) | value);
      m_acc.write(`ADDR_FD_TDCSR, `FD_TDCSR_WRITE);
   endtask // acam_write

   task acam_read(int addr, output int value);
      uint64_t rval;
      
      m_acc.write(`ADDR_FD_TAR, (addr<<28)); 
      m_acc.write(`ADDR_FD_TDCSR, `FD_TDCSR_READ);
      #(500ns);
      m_acc.read(`ADDR_FD_TAR, rval);
      value           = rval;
   endtask // acam_read


   

   task csync_int();
      m_acc.write(`ADDR_FD_GCR,  `FD_GCR_CSYNC_INT);
   endtask // csync_int

   task csync_wr();
      m_acc.write(`ADDR_FD_GCR,  `FD_GCR_CSYNC_WR);
   endtask // csync_wr
     
   task rbuf_update();
      Timestamp ts;
      uint64_t utc, coarse, seq_frac, stat;

      m_acc.read(`ADDR_FD_TSBCR, stat);

     // $display("TSBCR %x\n", stat);
      
      if((stat & `FD_TSBCR_EMPTY) == 0) begin
         
         m_acc.read(`ADDR_FD_TSBR_U, utc);
         m_acc.read(`ADDR_FD_TSBR_C, coarse);
         m_acc.read(`ADDR_FD_TSBR_FID, seq_frac);

         ts         = new (0,0,0);
         
         ts.utc     = utc;
         ts.coarse  = coarse & 'hfffffff;
         ts.seq_id  = (seq_frac >> 16) & 'hffff;
         ts.frac    = seq_frac & 'hfff;
         ts_queue.push_back(ts);
         
      end
   endtask // rbuf_read

   function int poll();
      return (ts_queue.size() > 0);
   endfunction // poll

   function Timestamp get();
      return ts_queue.pop_front();
   endfunction // get
   
    

  
   task config_output(int channel, int polarity, int delay_ps, int duration_ps);
      uint64_t dcr;
      Timestamp t_start, t_end;
      
      t_start  = new;
      t_start.unflatten(int'(real'(delay_ps) * 4096.0 / 8000.0));
      t_end  = new;
      t_end.unflatten(int'(real'(delay_ps + duration_ps) * 4096.0 / 8000.0));

      m_acc.write('h20 * channel + `ADDR_FD_FRR1, 800);
      m_acc.write('h20 * channel + `ADDR_FD_U_START1, t_start.utc);
      m_acc.write('h20 * channel + `ADDR_FD_C_START1, t_start.coarse);
      m_acc.write('h20 * channel + `ADDR_FD_F_START1, t_start.frac);
      m_acc.write('h20 * channel + `ADDR_FD_U_END1, t_end.utc);
      m_acc.write('h20 * channel + `ADDR_FD_C_END1, t_end.coarse);
      m_acc.write('h20 * channel + `ADDR_FD_F_END1, t_end.frac);

      dcr  = `FD_DCR1_ENABLE | `FD_DCR1_UPDATE | (polarity ? `FD_DCR1_POL : 0);
      
      m_acc.write('h20 * channel + `ADDR_FD_DCR1, dcr);
   endtask // config_output
   
                      
   
   
   task init();
      int rval;
      
      m_acc.write(`ADDR_FD_TDCSR, `FD_TDCSR_START_DIS | `FD_TDCSR_STOP_DIS);
      m_acc.write(`ADDR_FD_GCR, `FD_GCR_BYPASS);

      acam_write(5, c_acam_start_offset); // set StartOffset
      acam_read(5, rval);

      $display("AcamReadback %x", rval);
   

      // Clear the ring buffer
      m_acc.write(`ADDR_FD_TSBCR, `FD_TSBCR_ENABLE | `FD_TSBCR_PURGE | `FD_TSBCR_RST_SEQ);

      m_acc.write(`ADDR_FD_ADSFR, int' (real'(1<< (c_frac_bits + c_scaler_shift)) * c_acam_bin / c_ref_period));

      $display("ADSFR: %d", int' (real'(1<< (c_frac_bits + c_scaler_shift)) * c_acam_bin / c_ref_period));
      m_acc.write(`ADDR_FD_ASOR, c_acam_start_offset * 3);
      m_acc.write(`ADDR_FD_ATMCR, c_acam_merge_c_threshold | (c_acam_merge_f_threshold << 4));
      
      // Enable trigger input
      m_acc.write(`ADDR_FD_GCR,  0);

      #(200ns);
      csync_wr();
      #(100ns);
      
      // Enable trigger input
      m_acc.write(`ADDR_FD_GCR,  `FD_GCR_INPUT_EN);
      
      
   endtask // init

   task force_cal_pulse(int channel, int delay_setpoint);
      m_acc.write(`ADDR_FD_FRR1 + (channel * 'h20), delay_setpoint);
      m_acc.write(`ADDR_FD_DCR1 + (channel * 'h20), `FD_DCR1_FORCE_DLY | `FD_DCR1_POL);
      m_acc.write(`ADDR_FD_TDCSR, `FD_TDCSR_CAL_PULSE);
      
   endtask // force_cal_pulse
   
endclass // CSimDrv_FineDelay


module wr_time_counter 
  (
   input clk_ref_i,
   input rst_n_i,
   output [31:0] wr_utc_o,
   output [27:0] wr_coarse_o,
   output reg wr_time_valid_o
   );

   parameter g_coarse_range  = 256;
   
   reg [31:0] utc;
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

   wire clk_sys, clk_ref, clk_tdc, rst_n;

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

   wire [31:0] wr_utc;
   wire [27:0] wr_coarse;
   wire wr_time_valid;
   
   reg [3:0] tdc_start_div = 0;
   reg tdc_start    = 0;


   always@(posedge clk_ref) begin
      tdc_start_div <= tdc_start_div + 1;
      tdc_start    <= tdc_start_div[3];
   end

   IWishboneMaster
     #(
       .g_addr_width(8),
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
       .g_pulse_width(2000ns),
       .g_min_spacing(4000.111ns),
       .g_max_spacing(4000.112ns)
       )
     TRIG_GEN
       (
	.enable_i(1'b1),
	.pulse_o(trig_a)
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
	.trig_a_i(trig_a),
        .csync_p1_i(wr_time_valid & !wr_time_valid_d0),
        .csync_utc_i(wr_utc),
        .csync_coarse_i(wr_coarse)
	);

   acam_model
     #(
       .g_verbose(0)
       ) ACAM (
      .PuResN(rst_n),
      .Alutrigger(acam_alutrigger),
      .RefClk (clk_tdc),

      .WRN(acam_wr_n),
      .RDN(acam_rd_n),
      .CSN(acam_cs_n),
      .OEN(acam_rd_n),

      .Adr(acam_adr),
      .D(acam_data),
	       
      .DStart(tdc_start),
      .DStop1(trig_a),
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
      .in_i(~trig_a),
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
   
   
   fine_delay_core
     DUT (
	  .clk_ref_i(clk_ref),
	  .tdc_start_i(tdc_start),
	  .clk_sys_i(clk_sys),
	  .rst_n_i (rst_n),
	  .trig_a_n_i (trig_a_n_delayed),
	  .trig_cal_o (trig_cal),

	  .acam_a_o(acam_adr),
	  .acam_d_o     (tdc_d_o),
	  .acam_d_i     (acam_data),
	  .acam_d_oen_o (tdc_d_oe),

	  .acam_err_i    (1'b0),
	  .acam_int_i    (1'b0),
	  .acam_emptyf_i (acam_ef1),
	  .acam_alutrigger_o  (acam_alutrigger),

	  .acam_cs_n_o (acam_cs_n),
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

          .wr_utc_i(wr_utc),
          .wr_coarse_i(wr_coarse),
          .wr_time_valid_i(wr_time_valid),

	  .wb_adr_i (wb_master.master.adr[7:0]),
	  .wb_dat_i (wb_master.master.dat_o),
	  .wb_dat_o (wb_master.master.dat_i),
	  .wb_cyc_i (wb_master.master.cyc),
	  .wb_stb_i (wb_master.master.stb),
	  .wb_we_i  (wb_master.master.we),
	  .wb_ack_o (wb_master.master.ack)
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
      int rval;
      

      wait(rst_n != 0);
      @(posedge clk_sys);
      

      wb      = wb_master.get_accessor();
      fd_drv  = new(wb);
      fd_drv.init();
      
//      fd_drv.config_output(0,1, 1000000, 200000);
      // fd_drv.config_output(1,1, 1100500, 200000);
      //  fd_drv.config_output(2,1, 1100900, 200000);
      // fd_drv.config_output(3,1, 1110100, 200000);

      fd_drv.force_cal_pulse(0, 100);
  //    #(320ns);
    //  fd_drv.force_cal_pulse(0, 200);

      forever fd_drv.rbuf_update();
   end

   Timestamp prev  = null;

   always@(posedge clk_ref) 
     if (fd_drv != null)
       begin
          if(fd_drv.poll() && IDEAL_TSU.poll() && Output_TSU0.poll()/* && Output_TSU1.poll()*/)
            begin
               real delta, delta2, delta3;
               
               Timestamp t_acam;
               Timestamp t_ideal;
               Timestamp t_out0, t_out1;
               
               t_acam   = fd_drv.get();
               t_ideal  = IDEAL_TSU.get();
               t_out0    = Output_TSU0.get();
//               t_out1    = Output_TSU1.get();

               
               delta    = t_acam.flatten() - t_ideal.flatten();
               delta2   = t_out0.flatten() - t_ideal.flatten();
//               delta3   = t_out1.flatten() - t_ideal.flatten();
               
               
               $display("TS: seq %d delta %.4f delta_out %.4f %.4f", t_acam.seq_id, delta, delta2, delta3);
               if(delta > 0.1 || delta < -0.1)
                 begin
                    $display("TS Failure");
                    $stop;
                 end
            end
       end
   
endmodule // main

