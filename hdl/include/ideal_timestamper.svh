// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: CERN-OHL-W-2.0+

`include "timestamp.svh"

module ideal_timestamper
  (
   input clk_ref_i,
   input rst_n_i,
   input enable_i,

   input trig_a_i,

   input [31:0] csync_utc_i,
   input [27:0] csync_coarse_i,
   input csync_p1_i
   );

   parameter g_frac_range    = 4096;
   parameter g_coarse_range  = 125000000;

   const time c_frac_step   = 8ns / g_frac_range;
   
   reg [27:0] cntr_coarse;
   reg [31:0] cntr_utc;
   reg [12:0] cntr_frac;
   reg tag_valid_p1;
   
   Timestamp ts_queue[$];
   
   always@(posedge clk_ref_i)
     if(!rst_n_i)
       begin
	  cntr_coarse      <= 0;
	  cntr_utc         <= 0;
	  cntr_frac        <= 0;
	  tag_valid_p1     <= 0;
	  ts_queue          = '{};
       end
   
   always@(posedge clk_ref_i)
     cntr_frac             <= 0;

   always@(posedge clk_ref_i)
     if(!rst_n_i) begin
        cntr_coarse        <= 0;
        cntr_utc           <= 0;
     end else begin
        if(csync_p1_i)
          begin
             cntr_coarse <= csync_coarse_i+1;
             cntr_utc    <= csync_utc_i;
          end else if(cntr_coarse == g_coarse_range) begin
	     cntr_coarse <= 1;
	     cntr_utc    <= cntr_utc + 1;	   
          end else if(cntr_coarse == g_coarse_range - 1) begin
	     cntr_coarse <= 0;
	     cntr_utc    <= cntr_utc + 1;	   
	  end else
	    cntr_coarse  <= cntr_coarse + 1;
       end

  initial forever #(c_frac_step) cntr_frac <= cntr_frac + 1;
   
   always@(posedge trig_a_i) begin
      
      if(enable_i)
	begin
           Timestamp ts;
           ts         = new (cntr_utc, cntr_coarse, cntr_frac);
	   ts_queue.push_back(ts);
	end
   end

   function int poll();
      return (ts_queue.size() > 0);
   endfunction // poll

   function Timestamp get();
      return ts_queue.pop_front();
   endfunction // get
     

/* -----\/----- EXCLUDED -----\/-----
   always@(posedge clk_ref_i)
     if(tag_valid_p1)
       tag_valid_p1 <= 0;
     else if(ts_queue.size() > 0)
       begin
	  timestamp_t ts;
	  ts 		  = ts_queue.pop_front();
	  tag_frac_o 	 <= ts.frac;
	  tag_utc_o 	 <= ts.utc;
	  tag_coarse_o 	 <= ts.coarse;
	  tag_valid_p1 	 <= 1'b1;
       end
       

   assign tag_valid_p1_o = tag_valid_p1;
   assign cntr_coarse_o   = cntr_coarse;
   assign cntr_utc_o 	  = cntr_utc;
 -----/\----- EXCLUDED -----/\----- */
   
endmodule // ideal_timestamper
