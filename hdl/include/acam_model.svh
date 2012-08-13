`timescale 1ps/1ps




// R-Mode only!
module acam_model
  (
   input PuResN,
   input Alutrigger,
   input RefClk,

   input WRN,
   input RDN,
   input CSN,
   input OEN,

   input [3:0] Adr,
   input DStart,
   input DStop1,
   input DStop2,

   input TStart,
   input[8:1] TStop,

   input StartDis,
   input[4:1] StopDis,

   output IrFlag,
   output ErrFlag,

   output reg EF1,
   output LF1,

   inout[27:0] D

   /* sim-only */

   );

   parameter real g_rmode_resolution  = 80.9553ps / 3.0;
   parameter int g_verbose 	      = 1;

   const real c_empty_flag_delay       = 75ns;


   wire start_masked;
   wire stop1_masked;

   wire r_MasterAluTrig;
   wire r_StartDisStart;
     
   reg[27:0] RB[0:14];
   reg[27:0] DQ = 0;

   reg EF1_int 	= 1'b1;
   reg start_disabled_int;

   int rmode_start_offset;
   
   mailbox q_start, q_stop1;
   mailbox q_hit;
   
   int t 		      = 0;

  
   assign rmode_start_offset  = RB[5][17:0];
   
   always #(g_rmode_resolution) t <= t + 1;

   assign r_MasterAluTrig  = RB[5][23];
   assign r_StartDisStart  = RB[5][22];
   

   task master_reset;
      int i;

      if(g_verbose) $display("Acam::MasterReset");
      
      
      q_start             = new(16384);
      q_stop1             = new(16384);
      q_hit               = new(16384);
      EF1                <= 1;
      start_disabled_int <= 0;

      for(i=0;i<15;i++)
        RB[i]             = 0;
      
      
   endtask // master_reset

   initial master_reset();
   
   
   always@(negedge PuResN) begin
      master_reset();
      end
   
   always@(posedge Alutrigger) begin
      if(r_MasterAluTrig)
	begin
	   int dummy;
	   
	   while(q_hit.num() > 0) q_hit.get(dummy);
	   
	   start_disabled_int <= 0;
//	   EF1		      <= 0;
	end
//	master_reset();
   end

   always@(negedge Alutrigger) begin
      if(r_MasterAluTrig)
	begin
//	   EF1		      <= 1;
	end
   end
   
//    
   

   always@(posedge DStart) 
     if(PuResN && !StartDis && !start_disabled_int) begin
//	if(g_verbose)$display("acam::start %d", t);
	q_start.put(t);
	start_disabled_int <= r_StartDisStart;
	
     end

   always@(posedge DStop1) 
     if(PuResN && !StopDis[1]) begin
	if(g_verbose)$display("acam::stop1 %d", t);
	q_stop1.put(t);
     end
   

   always@(negedge WRN) if (!CSN && RDN)
     begin
	RB[Adr] <= D;
		if(g_verbose)$display("acam::write reg %x val %x\n", Adr, D);
     end
   
   always@(negedge RDN) if (!CSN && WRN)
     begin
	if(g_verbose)$display("acam::read reg %x val %x\n", Adr, RB[Adr]);     
	if(Adr == 8) begin
	   int hit;
	   
	   q_hit.try_get(hit);
	   DQ 	    <= hit;
	   
	end else
	  DQ <= RB[Adr];
     end
   
   
   always@(negedge PuResN) begin
      int i;
      for (i=0;i<14;i++) RB[i] <= 0;
   end

   assign D  = (!CSN && !RDN)?DQ:28'bz;

   
   

   
   always@(posedge RefClk)
     begin
 
	int t_start, t_stop1, n_starts, tmp, hit;

        if(q_stop1.num() > 0)
          begin
	     q_stop1.get(t_stop1);

	     while(q_start.num() > 0) begin
	        q_start.peek(t_start);
	        
	        if(t_start < t_stop1)
	          begin
		     q_start.get(tmp);
	          end 
	        else 
	          break;
	     end
	     if(t_stop1 - t_start > 3780)
	       hit  =  (t_stop1 - t_start) - (128ns/g_rmode_resolution) + rmode_start_offset * 3;
	     else
	       hit  = t_stop1 - t_start + rmode_start_offset * 3;

	     if(g_verbose)$display("acam::hit1 %d t_stop1 %d t_start %d", hit, t_stop1, t_start);
	
	     if(q_hit.num() == 0) begin
	        #(c_empty_flag_delay);
	     end
	
	     q_hit.put(hit);
	  end // if (q_stop1.num() > 0)
     end // always@ (posedge RefClk)
   
   
   reg fifo_empty     =1;
   reg fifo_notempty  = 0;
   
   initial forever begin
      #1;
      
      if(q_hit.num() > 0)
	EF1 = #(12ns) 0;
      else
	EF1 = 1;
     
   end
   
   
   
   
   
endmodule // acam_model


