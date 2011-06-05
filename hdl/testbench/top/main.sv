`timescale 10fs/10fs

`include "acam_model.sv"
`include "tunable_clock_gen.sv"
`include "random_pulse_gen.sv"
`include "jittery_delay.sv"
`include "if_wishbone.sv"
`include "fine_delay_regs.v"
`include "ideal_timestamper.sv"

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

   reg [3:0] tdc_start_div = 0;
   reg tdc_start    = 0;


   always@(posedge clk_ref) begin
      tdc_start_div <= tdc_start_div + 1;
      tdc_start    <= tdc_start_div[3];
   end
   
   
   IWishbone WB 
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

   random_pulse_gen
     #(
       .g_pulse_width(30ns),
       .g_min_spacing(251.111ns),
       .g_max_spacing(251.112ns)
       )
     TRIG_GEN
       (
	.enable_i(1'b1),
	.pulse_o(trig_a)
	);

   ideal_timestamper
     IDEAL_TSU
       (
	.rst_n_i(rst_n),
	.clk_ref_i(clk_ref),
	.enable_i(!acam_stop_dis),
	.trig_a_i(trig_a)
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
	  .spi_mosi_o (),
	  .spi_miso_i (1'b0),

	  .delay_len_o (),
	  .delay_val_o (),
	  .delay_pulse_o (),


	  .wb_adr_i (WB.master.adr[4:0]),
	  .wb_dat_i (WB.master.dat_o),
	  .wb_dat_o (WB.master.dat_i),
	  .wb_cyc_i (WB.master.cyc),
	  .wb_stb_i (WB.master.stb),
	  .wb_we_i  (WB.master.we),
	  .wb_ack_o (WB.master.ack)
	  );

   initial begin
      real ts_prev;
      
      reg[31:0] rval;
      int f;
      
      @(posedge rst_n);
      repeat(3) @(posedge clk_sys);

      
      
      WB.write32(`ADDR_FD_TDCSR, `FD_TDCSR_START_DIS | `FD_TDCSR_STOP_DIS);
      WB.write32(`ADDR_FD_GCR, `FD_GCR_BYPASS);
      WB.write32(`ADDR_FD_TAR, (5<<28) | 10000); // Startoffset= 10000
      WB.write32(`ADDR_FD_TDCSR, `FD_TDCSR_WRITE);
      WB.write32(`ADDR_FD_PGCR, 10 | (1<<31));

      WB.write32(`ADDR_FD_GCR, 0);
      #(1000ns);
      WB.write32(`ADDR_FD_GCR,  `FD_GCR_INPUT_EN);



      f	 =$fopen("/home/slayer/1.dlm","w");

     
      while(1)
	begin
	   WB.read32(`ADDR_FD_TSFIFO_CSR,  rval);      
	   if(!(rval & `FD_TSFIFO_CSR_EMPTY)) begin
	      real ts;
	      
	      int r0, r1, r2;
	      int m;
	      
	      const real acam_bin  = 80.96 / 3.0;
	      int fine;
	      int ts_r, ts_f;
	      int ahead;
	      
	      WB.read32(`ADDR_FD_TSFIFO_R0,  r0);      
	      WB.read32(`ADDR_FD_TSFIFO_R1,  r1);    
	      WB.read32(`ADDR_FD_TSFIFO_R2,  r2);
	      

	      $display("utc %d coarse %d fine %d", r0, r1, r2);

	      ts_prev  = ts;
	      ts       = real'(r2)/4096.0 * 8000.0 + real'(r1) * 8000.0;
	      
	      $display("dts %.1f", ts-ts_prev);
	      
	   end   
	end
      
      
   end // initial begin
   
   
endmodule // main

