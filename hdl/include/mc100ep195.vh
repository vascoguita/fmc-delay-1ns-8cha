`timescale 1ps/1ps

module mc100ep195
  (
   input len,
   input i,
   input [9:0] delay,
   output o
   );


   const int c_min_delay     = 2ns;
   const int c_time_per_tap  = 10ps;
   
   reg [9:0] cur_dly = 0;
   reg o_reg    = 0;

   assign o     = o_reg;
   

   always@(posedge len)
     begin
        cur_dly <= delay;
     end
   
   

   always@(i)
     o_reg         <= #(c_min_delay +  cur_dly * c_time_per_tap) i;

endmodule // mc100ep195
