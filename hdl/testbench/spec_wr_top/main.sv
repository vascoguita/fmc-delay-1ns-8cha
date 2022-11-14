// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: CERN-OHL-W-2.0+

`timescale 1ns/1ps

`include "simdrv_defs.svh"   
`include "regs/fd_main_regs.vh"
`include "regs/simple_debug_recorder_regs.vh"

`include "gn4124_bfm.svh"

const uint64_t BASE_WRPC = 'h00c0000;
const uint64_t BASE_FINEDELAY = 'h0010000;

class IBusDevice;

   CBusAccessor m_acc;
   uint64_t m_base;

   function new ( CBusAccessor acc, uint64_t base );
      m_acc =acc;
      m_base = base;
   endfunction // new
   
   virtual task write32( uint32_t addr, uint32_t val );
     // $display("write32 addr %x val %x", m_base + addr, val);
      
      m_acc.write(m_base +addr, val);
//      #100ns;
      
   endtask // write
   
   virtual task read32( uint32_t addr, output uint32_t val );
      automatic uint64_t val64;
      
      m_acc.read(m_base + addr, val64);
     // $display("read32 addr %x val %x", m_base + addr, val64);
      val = val64;
//      #100ns;

   endtask // write
endclass // BusDevice

class FineDelayDev extends IBusDevice;
   function new(CBusAccessor bus, uint64_t base);
      super.new(bus, base);
   endfunction // new


/* -----\/----- EXCLUDED -----\/-----
`define FD_SCR_DATA_OFFSET 0
`define FD_SCR_DATA 32'h00ffffff
`define FD_SCR_SEL_DAC_OFFSET 24
`define FD_SCR_SEL_DAC 32'h01000000
`define FD_SCR_SEL_PLL_OFFSET 25
`define FD_SCR_SEL_PLL 32'h02000000
`define FD_SCR_SEL_GPIO_OFFSET 26
`define FD_SCR_SEL_GPIO 32'h04000000
`define FD_SCR_READY_OFFSET 27
`define FD_SCR_READY 32'h08000000
`define FD_SCR_CPOL_OFFSET 28
`define FD_SCR_CPOL 32'h10000000
`define FD_SCR_START_OFFSET 29
`define FD_SCR_START 32'h20000000
 -----/\----- EXCLUDED -----/\----- */

   const int FD_CS_PLL = 0;
   const int FD_CS_GPIO = 1;

   task set_idelay_taps( int taps );
      uint64_t tdcsr;

      $display("Set Idelay taps : %d\n", taps);
      
      write32(`ADDR_FD_IODELAY_ADJ, taps);
   endtask // set_idelay_taps
   
   task automatic fd_spi_xfer ( input int ss, int num_bits,
		    uint32_t in, output uint32_t out);
      uint32_t scr = 0, r;
      int i;

      $display("SPI Xfer ss %d in %x (SCR @ %x)", ss, in, `ADDR_FD_SCR );
      
      scr = (in << `FD_SCR_DATA_OFFSET) | `FD_SCR_CPOL;
      if(ss == FD_CS_PLL)
	scr |= `FD_SCR_SEL_PLL;
      else if(ss == FD_CS_GPIO)
	scr |= `FD_SCR_SEL_GPIO;

      write32(`ADDR_FD_SCR, scr);
      write32(`ADDR_FD_SCR, scr | `FD_SCR_START);

      forever begin
	 
	 read32( `ADDR_FD_SCR, scr );
	// $display("SCR %x", scr);

	 if( scr & `FD_SCR_READY )
	   begin
	      $display("READY");
	      
	      break;
	   end
	 
      end
      
      read32( `ADDR_FD_SCR, scr );
      out = r & `FD_SCR_DATA;

   endtask // r


   task automatic pll_writel( int val, int r );
      uint32_t dummy;      
      fd_spi_xfer( FD_CS_PLL, 24, (r << 8) | val, dummy );
   endtask // pll_writel

   task automatic pll_readl( int val, output int r );
      uint32_t rv;
      fd_spi_xfer( FD_CS_PLL, 24, (r << 8) | val | (1<<23), rv );
      r = rv;
   endtask // pll_writel

   
   task automatic unreset();
      uint32_t rval;
      write32(`ADDR_FD_RSTR, 'hdeadffff); /* Un-reset the card */

      read32('h4, rval);
      $display("FD.IDR = %x", rval);


      
   endtask // configure

   task automatic setup_irqs();
      write32(`ADDR_FD_EIC_IER, 'hffffffff);
   endtask // setup_irqs
   
	

endclass // FineDelayDev


module main;
   reg clk_125m_pllref = 0;
   reg clk_20m_vcxo = 0;
   reg clk_fd_ref = 0;
   reg tdc_start = 0;
   
   always #4ns clk_125m_pllref <= ~clk_125m_pllref;
   always #4ns clk_fd_ref <= ~clk_fd_ref;
   always #100ns tdc_start <= ~tdc_start;
   
   always #20ns clk_20m_vcxo <= ~clk_20m_vcxo;
   
   wire clk_sys;
   wire rst_sys_n;

   
   IGN4124PCIMaster i_gn4124 ();

   
   spec_fine_delay_top
     #(.g_simulation(1)
       )

     DUT (
          .clk_125m_pllref_p_i(clk_125m_pllref),
          .clk_125m_pllref_n_i(~clk_125m_pllref),

          .clk_125m_gtp_p_i(clk_125m_pllref),
          .clk_125m_gtp_n_i(~clk_125m_pllref),
          .clk_20m_vcxo_i(clk_20m_vcxo),

	  .button1_n_i(1'b1),
	  
          .fmc0_fd_clk_ref_p_i(clk_fd_ref),
          .fmc0_fd_clk_ref_n_i(~clk_fd_ref),

          .fmc0_fd_tdc_start_p_i(tdc_start),
          .fmc0_fd_tdc_start_n_i(~tdc_start),
	  
	  .fmc0_fd_pll_status_i(1'b1),

	  .gn_rst_n_i                (i_gn4124.rst_n),
      .gn_p2l_clk_n_i            (i_gn4124.p2l_clk_n),
      .gn_p2l_clk_p_i            (i_gn4124.p2l_clk_p),
      .gn_p2l_rdy_o              (i_gn4124.p2l_rdy),
      .gn_p2l_dframe_i           (i_gn4124.p2l_dframe),
      .gn_p2l_valid_i            (i_gn4124.p2l_valid),
      .gn_p2l_data_i             (i_gn4124.p2l_data),
      .gn_p_wr_req_i             (i_gn4124.p_wr_req),
      .gn_p_wr_rdy_o             (i_gn4124.p_wr_rdy),
      .gn_rx_error_o             (i_gn4124.rx_error),
      .gn_l2p_clk_n_o            (i_gn4124.l2p_clk_n),
      .gn_l2p_clk_p_o            (i_gn4124.l2p_clk_p),
      .gn_l2p_dframe_o           (i_gn4124.l2p_dframe),
      .gn_l2p_valid_o            (i_gn4124.l2p_valid),
      .gn_l2p_edb_o              (i_gn4124.l2p_edb),
      .gn_l2p_data_o             (i_gn4124.l2p_data),
      .gn_l2p_rdy_i              (i_gn4124.l2p_rdy),
      .gn_l_wr_rdy_i             (i_gn4124.l_wr_rdy),
      .gn_p_rd_d_rdy_i           (i_gn4124.p_rd_d_rdy),
      .gn_tx_error_i             (i_gn4124.tx_error),
      .gn_vc_rdy_i               (i_gn4124.vc_rdy),
      .gn_gpio_b                 ()
	  );

   assign clk_sys = DUT.clk_sys_62m5;
   assign rst_sys_n = DUT.rst_sys_62m5_n;

   
   initial begin
      uint64_t rval;
      int tmp;
      
      CBusAccessor acc ;
      FineDelayDev fd;
      
      acc = i_gn4124.get_accessor();

      fd = new(acc, BASE_FINEDELAY);
 
      while (!rst_sys_n)
	@(posedge clk_sys);
      

      repeat(100)
	@(posedge clk_sys);
      

//      $error("START");
      
      $display("Startup");

      fd.unreset();
      fd.setup_irqs();
      fd.set_idelay_taps(10);
      #10us;
      
      fd.set_idelay_taps(20);
      #10us;

      acc.read('h1000, rval );

      $display("R1000 = %x", rval );
      
      
      $stop;
      
   end
   
   
endmodule // main



