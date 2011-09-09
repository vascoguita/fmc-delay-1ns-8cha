
module jittery_delay
  (
   input in_i,
   output reg out_o
   );

   parameter g_delay   = 10ns;
   parameter g_jitter  = 10ps;

   int seed 	       = 1;
   
   always@(in_i)
     begin
	real delta;

	seed   = $urandom(seed);
	delta  = $dist_normal(seed, g_delay, g_jitter);

	out_o <= #(delta) in_i;
     end
   
endmodule // jittery_delay