`timescale 1ns/1ps

`include "simdrv_defs.svh"   
`include "regs/fd_main_regs.vh"
`include "regs/simple_debug_recorder_regs.vh"
`include "vhd_wishbone_master.svh"

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

/* -----\/----- EXCLUDED -----\/-----
`define ADDR_SDER_CSR                  4'h0
`define SDER_CSR_START_OFFSET 0
`define SDER_CSR_START 32'h00000001
`define SDER_CSR_STOP_OFFSET 1
`define SDER_CSR_STOP 32'h00000002
`define SDER_CSR_FORCE_OFFSET 2
`define SDER_CSR_FORCE 32'h00000004
`define SDER_CSR_TRIG_SEL_OFFSET 3
`define SDER_CSR_TRIG_SEL 32'h000000f8
`define SDER_CSR_TRIG_EDGE_OFFSET 8
`define SDER_CSR_TRIG_EDGE 32'h00000100
`define SDER_CSR_TRIGGERED_OFFSET 9
`define SDER_CSR_TRIGGERED 32'h00000200
`define SDER_CSR_TRIG_PRE_SAMPLES_OFFSET 10
`define SDER_CSR_TRIG_PRE_SAMPLES 32'h03fffc00
`define ADDR_SDER_MEM_ADDR             4'h4
`define SDER_MEM_ADDR_ADDR_OFFSET 0
`define SDER_MEM_ADDR_ADDR 32'h0000ffff
`define ADDR_SDER_TRIG_POS             4'h8
`define SDER_TRIG_POS_POS_OFFSET 0
`define SDER_TRIG_POS_POS 32'h0000ffff
`define ADDR_SDER_MEM_DATA             4'hc
`define SDER_MEM_DATA_DATA_OFFSET 0
`define SDER_MEM_DATA_DATA 32'hffffffff
 -----/\----- EXCLUDED -----/\----- */

class DebugRecorderDev extends IBusDevice;
  function new(CBusAccessor bus, uint64_t base);
      super.new(bus, base);
   endfunction // new

   task automatic configure(int trig_in, int trig_edge, int pre_samples);
      uint32_t csr;

      csr = (trig_in << `SDER_CSR_TRIG_SEL_OFFSET);
      if(trig_edge)
	csr|=`SDER_CSR_TRIG_EDGE;
      csr |= (pre_samples << `SDER_CSR_TRIG_PRE_SAMPLES_OFFSET);

      write32(`ADDR_SDER_CSR, csr);
   endtask // configure

   task automatic run();
      uint32_t csr;
      read32(`ADDR_SDER_CSR, csr);
      csr |= `SDER_CSR_START;
      write32(`ADDR_SDER_CSR, csr);
   endtask // run

   task automatic readout();
      uint32_t csr, pos, mdata, mtag;
      int i;

      $error("RDS");
      
      forever begin
	 read32(`ADDR_SDER_CSR, csr);
	 $display("trig CSR %x", csr);
	 
	 if( csr & `SDER_CSR_TRIGGERED)
	   break;

	 #5us;
	 
      end
      
      csr |= `SDER_CSR_STOP;
      write32(`ADDR_SDER_CSR, csr);

      $display("Readout!");

      read32(`ADDR_SDER_TRIG_POS, pos);
      $display("Trig pos: %x", pos);

      for(i=0;i<10;i++)
	begin
	   write32(`ADDR_SDER_MEM_ADDR, 2*i);
	   read32(`ADDR_SDER_MEM_DATA, mdata);
	   write32(`ADDR_SDER_MEM_ADDR, 2*i+1);
	   read32(`ADDR_SDER_MEM_DATA, mtag);
	   $display("pos %d %x %x", i, mdata, mtag);
	   
	end
      

      
      
   endtask // readout
   
	
	

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

   wire t_wishbone_master_out sim_wb_in;
   wire t_wishbone_master_in sim_wb_out;
   

   
   
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

	  .sim_wb_i(sim_wb_in),
	  .sim_wb_o(sim_wb_out)

	  
	     
        //  `GENNUM_WIRE_SPEC_PINS_V2(I_Gennum)
	  );


   
   IVHDWishboneMaster Host
     (
      .clk_i   (DUT.clk_sys_62m5),
      .rst_n_i (DUT.rst_sys_62m5_n));
   

   assign sim_wb_in = Host.out;
   assign Host.in = sim_wb_out;
   
   assign clk_sys = DUT.clk_sys_62m5;
   assign rst_sys_n = DUT.rst_sys_62m5_n;

   
   initial begin
      uint64_t rval;
      int tmp;
      
      CBusAccessor acc ;
      FineDelayDev fd;
      DebugRecorderDev rec;
      
      acc = Host.get_accessor();

      fd = new(acc, BASE_FINEDELAY);
      rec = new(acc, BASE_FINEDELAY + 'h180 * 4);

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

      $stop;
      
      
//      rec.configure(4, 0, 100);
//      rec.run();

//      fd.pll_readl('h1f, tmp);
//      $error("done");
      
//      rec.readout();
      
     
      

      
   end
   
   
endmodule // main



