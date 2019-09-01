`include "vme64x_bfm.svh"
`include "svec_vme_buffers.svh"

`include "fdelay_board.svh"
`include "simdrv_fine_delay.svh"


module delay_meas(input enable, input a, input b);

   mailbox tag_a, tag_b;

   event   q_notempty;
   
   initial begin
      tag_a = new(1024);
      tag_b = new(1024);
   end

   always@(posedge a) begin
      if(enable) tag_a.put($time);
   end
   
   always@(posedge b) begin
      if(enable) tag_b.put($time);
   end
   
   

   initial forever begin
      wait(tag_a.num() > 0 && tag_b.num() > 0);
      
      while(tag_a.num() > 0 && tag_b.num() > 0)
        begin
           longint ta, tb, delta;
           
           tag_a.get(ta);
           tag_b.get(tb);

           delta = tb - ta;

           $display("Delay: %.3f ns",  real'(delta) / real'(1ns) );
        end
   end
endmodule // delay_meas

module period_meas(input enable, input a);

   mailbox tag_a, tag_b;

   event   q_notempty;
   
   initial begin
      tag_a = new(1024);
   end

   time prev_a = 0;
   
   
   always@(posedge a) begin
      if(prev_a > 0)begin
         if(enable) tag_a.put($time - prev_a);
      end
      if(!enable)
        prev_a=0;
      else
        prev_a=$time;
   end
   
   
   

   initial forever begin
      wait(tag_a.num() > 0);
      
      while(tag_a.num() > 0)
        begin
           time delta;
         
           tag_a.get(delta);
           
           $display("Period: %.3f ns",  real'(delta) / real'(1ns) );
        end
   end
endmodule // delay_meas



module main;

   reg rst_n = 0;
   reg clk_125m = 0, clk_20m = 0;

   always #4ns clk_125m <= ~clk_125m;
   always #25ns clk_20m <= ~clk_20m;
   
   initial begin
      repeat(20) @(posedge clk_125m);
      rst_n = 1;
   end

   IFineDelayFMC I_fmc0(), I_fmc1();
   
   IVME64X VME(rst_n);

   `DECLARE_VME_BUFFERS(VME.slave);

   svec_top #(
              .g_with_wr_phy(0),
              .g_simulation(1)
              ) DUT (
		 .clk_125m_pllref_p_i(clk_125m),
		 .clk_125m_pllref_n_i(~clk_125m),
		 .clk_125m_gtp_p_i(clk_125m),
		 .clk_125m_gtp_n_i(~clk_125m),
		 .clk_20m_vcxo_i(clk_20m),
                
		 .rst_n_i(rst_n),
                 
		 `WIRE_VME_PINS(8),
                 `WIRE_FINE_DELAY_PINS(0, I_fmc0),
                 `WIRE_FINE_DELAY_PINS(1, I_fmc1)
	         );

   wire trig0, trig1;
   wire [3:0] out0, out1;
   reg        pulse_enable = 0;
   
   random_pulse_gen
     #(
       .g_pulse_width  (50ns),
       .g_min_spacing  (1001ns),
       .g_max_spacing  (1001.1ns))
   U_Gen0
     (
      .enable_i(pulse_enable),
      .pulse_o(trig0)
      );
   
   fdelay_board U_Board0 
     (
      .trig_i(trig0),
      .out_o(out0),
      .fmc(I_fmc0.board)
      );

   reg out0_delayed=0;

   always@(out0[0]) out0_delayed <= #10ps out0[0];
    
  period_meas U_DMeas0 (pulse_enable, out0[0]);
  period_meas U_DMeas1 (pulse_enable, out0[1]);
  period_meas U_DMeas2 (pulse_enable, out0[2]);
  period_meas U_DMeas3 (pulse_enable, out0[3]);
   
   task automatic init_vme64x_core(ref CBusAccessor_VME64x acc);
      /* map func0 to 0x80000000, A32 */
      acc.write('h7ff63, 'h80, A32|CR_CSR|D08Byte3);
      acc.write('h7ff67, 0, CR_CSR|A32|D08Byte3);
      acc.write('h7ff6b, 0, CR_CSR|A32|D08Byte3);
      acc.write('h7ff6f, 36, CR_CSR|A32|D08Byte3);
      acc.write('h7ff33, 1, CR_CSR|A32|D08Byte3);
      acc.write('h7fffb, 'h10, CR_CSR|A32|D08Byte3); /* enable module (BIT_SET = 0x10) */

   endtask // init_vme64x_core
   
   initial begin
      CBusAccessor_VME64x acc = new(VME.master);
      CBusAccessor acc_casted = CBusAccessor'(acc);
      Timestamp dly, t_start;
      
      CSimDrv_FineDelay drv0;
      uint64_t d;
      
      #20us;
      

      init_vme64x_core(acc);
      acc_casted.set_default_xfer_size(A32|SINGLE|D32);

      
      
      drv0 = new(acc, 'h80010000);
      drv0.init();

      drv0.set_idelay_taps(30);
      
      t_start=new;    
      drv0.get_time(t_start);
      t_start.coarse += 20000;
      
      drv0.config_output(0, CSimDrv_FineDelay::PULSE_GEN, 1, t_start, 200000, 1001000, -1);
      drv0.config_output(1, CSimDrv_FineDelay::PULSE_GEN, 1, t_start, 200000, 1001100, -1);
      drv0.config_output(2, CSimDrv_FineDelay::PULSE_GEN, 1, t_start, 200000, 1001200, -1);
      drv0.config_output(3, CSimDrv_FineDelay::PULSE_GEN, 1, t_start, 200000, 1001300, -1);
      
      $display("Init done");

      
      pulse_enable = 1;

/* -----\/----- EXCLUDED -----\/-----
      forever begin
         drv0.rbuf_update();

         if(drv0.poll())
           begin
              Timestamp ts;
              ts = drv0.get();
             // $display("TS: %.3f", ts.flatten());
           end
         #1us;
      end
 -----/\----- EXCLUDED -----/\----- */
   end // initial begin
   

  
endmodule // main




