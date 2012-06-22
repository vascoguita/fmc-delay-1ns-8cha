`include "vme64x_bfm.svh"
`include "svec_vme_buffers.svh"

`include "regs/fd_main_regs.vh"
`include "regs/fd_channel_regs.vh"

module main;

   reg rst_n = 0;
   reg clk_125m = 0, clk_20m = 0;

   always #4ns clk_125m <= ~clk_125m;
   always #25ns clk_20m <= ~clk_20m;
   
   initial begin
      repeat(20) @(posedge clk_125m);
      rst_n = 1;
   end

   
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
                 .fd0_clk_ref_p_i(clk_125m),
                 .fd0_clk_ref_n_i(~clk_125m),
                 .fd1_clk_ref_p_i(clk_125m),
                 .fd1_clk_ref_n_i(~clk_125m),
		 .rst_n_i(rst_n),
                 
		 `WIRE_VME_PINS(8)
	         );
   
   initial begin
      uint64_t d, abuf[16], dbuf[16];
      
      int i, result;
      
      CBusAccessor_VME64x acc = new(VME.master);

      #20us;

      acc.read('h40004, d, A32|SINGLE|D32);
      $display("IDR0: %x\n", d);
      acc.write('h40000 + `ADDR_FD_RSTR, 'hdeadffff, A32|SINGLE|D32); /* Un-reset the card */
      #10us;
      
      acc.write('h40100, 'hdeadbeef, A32|SINGLE|D32);

      acc.read('h50004, d, A32|SINGLE|D32);
      $display("IDR1: %x\n", d);
      acc.write('h50000 + `ADDR_FD_RSTR, 'hdeadffff, A32|SINGLE|D32); /* Un-reset the card */
      #10us;
      
      acc.write('h50100, 'hdeadbeef, A32|SINGLE|D32);
      
      
      
      
      
   end

  
endmodule // main



