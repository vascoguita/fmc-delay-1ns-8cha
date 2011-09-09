module random_pulse_gen
  (
   input enable_i,
   output reg pulse_o
   );


   parameter real g_pulse_width  = 30ns;
   parameter real g_min_spacing  = 300ns;
   parameter real g_max_spacing  = 600ns;

   int seed 			 = 1;
   

   initial forever
     if(enable_i)
       begin
	  real delta;
	  seed 	   = $urandom(seed);
	  delta    = $dist_uniform(seed, g_min_spacing - g_pulse_width, g_max_spacing - g_pulse_width);
	  pulse_o  = 1;
	  #(g_pulse_width);
	  pulse_o  = 0;
	  #(delta);
	  
       end else begin
	  pulse_o <= 1'b0;
	  #1;
       end
   
endmodule // random_pulse_gen
