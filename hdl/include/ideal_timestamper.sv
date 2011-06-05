module ideal_timestamper
  (
   input clk_ref_i,
   input rst_n_i,
   input enable_i,

   input trig_a_i,
   
   output reg [22:0] tag_frac_o,
   output reg [27:0] tag_coarse_o,
   output reg [31:0] tag_utc_o,
   output tag_valid_p1_o,
   
   output [27:0] cntr_coarse_o,
   output [31:0] cntr_utc_o
   );

   parameter real g_frac_resolution  = 80.9553ps/3.0;
   
   reg [27:0] cntr_coarse;
   reg [31:0] cntr_utc;
   reg [22:0] cntr_frac;
   reg tag_valid_p1;

   
   typedef struct {
      reg [27:0] coarse;
      reg [31:0] utc;
      reg [22:0] frac;
   } timestamp_t;
   

   timestamp_t ts_queue[$]  = '{};

   
   always@(posedge clk_ref_i)
     if(!rst_n_i)
       begin
	  cntr_coarse 	   <= 0;
	  cntr_utc 	   <= 0;
	  cntr_frac 	   <= 0;
	  tag_valid_p1 	   <= 0;
	  ts_queue 	    = '{};
       end
   
   always@(posedge clk_ref_i)
     cntr_frac 		   <= 0;

   always@(posedge clk_ref_i)
     if(rst_n_i)
       begin
	  if(cntr_coarse == 125000000 - 1) begin
	     cntr_coarse 	   <= 0;
	     cntr_utc 	   <= cntr_utc + 1;	   
	  end else
	    cntr_coarse 	   <= cntr_coarse + 1;
       end

   initial forever begin
      #(g_frac_resolution) cntr_frac <= cntr_frac + 1;
   end
   
   always@(posedge trig_a_i) begin
      if(enable_i)
	begin
	   timestamp_t ts;

	   ts.frac 	 = cntr_frac;
	   ts.coarse  = cntr_coarse;
	   ts.utc 	 = cntr_utc;

	   ts_queue.push_back(ts);
	end
   end

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
   
endmodule // ideal_timestamper
