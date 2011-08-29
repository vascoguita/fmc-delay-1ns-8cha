//#`include "simdrv_defs.svh"

`timescale 1ns/1ps

typedef longint unsigned uint64_t;

typedef struct {
   bit[27:0] coarse;
   bit[31:0] utc;
   bit[11:0] frac;
} timestamp_t;


class Timestamp;

   const int coarse_range  = 125;
   const int frac_range    = 4096;
   
   rand int coarse;
   rand int utc;
   rand int frac;

   function new(timestamp_t ts);
      coarse  = ts.coarse;
      utc     = ts.utc;
      frac    = ts.frac;
   endfunction // new
   
   
   function timestamp_t get();
      timestamp_t ts;
      ts.coarse  = coarse;
      ts.frac    = frac;
      ts.utc     = utc;
      return ts;
   endfunction // get
   
     

   function automatic bit is_normalized();
      if(frac < 0|| frac >=frac_range)
        return 0;
      if(coarse < 0|| coarse >= coarse_range)
        return 0;
      return 1;
   endfunction // is_normalized

   constraint c_frac 
     {
      frac >= 0;
      frac < frac_range;
      };

   constraint c_utc {
      utc >= 0;
      utc < 100000000;
   };

   function automatic uint64_t flatten();
      return frac + coarse * frac_range + utc * frac_range * coarse_range;
   endfunction // flatten

endclass // Timestamp

// a is always normalized
class ATimestamp extends Timestamp;
   function new();
      timestamp_t ts;
      super.new(ts);
   endfunction // new

   constraint c_coarse 
     {
      coarse >= 0;
      coarse < coarse_range;
   };
endclass // ATimestamp

// a is always normalized
class BTimestamp extends Timestamp;
   function new();
        timestamp_t ts;
      super.new(ts);
   endfunction // new

   constraint c_coarse 
     {
      coarse > -coarse_range;
      coarse < coarse_range + 10;
   };
endclass // BTimestamp


     

module main;

   reg clk_sys  = 0;
   reg rst_n    = 0;

   always #4ns clk_sys <= ~clk_sys;

   initial begin
      repeat(3)@(posedge clk_sys);
      rst_n     <= 1;
   end

   reg valid_in  = 0;
   timestamp_t ta,tb,tq;
   
   fd_ts_adder
     #(
       .g_frac_bits    (12),
       .g_coarse_bits  (28),
       .g_utc_bits     (32),
       .g_coarse_range (125)
       ) DUT (
              .clk_i  (clk_sys),
              .rst_n_i (rst_n),
              .valid_i (valid_in),

              .a_utc_i    (ta.utc),
              .a_coarse_i (ta.coarse),
              .a_frac_i   (ta.frac),

              .b_utc_i    (tb.utc),
              .b_coarse_i (tb.coarse),
              .b_frac_i   (tb.frac),

              .valid_o   (valid_out),
              .q_utc_o    (tq.utc),
              .q_coarse_o (tq.coarse),
              .q_frac_o   (tq.frac)
              );

   const int num_tries  = 10000000;

   uint64_t expected[$];

   always@(posedge clk_sys)
     begin
       if(valid_out)
         begin
            Timestamp tmp;
            uint64_t sum;

            sum  = expected.pop_front();
            tmp  = new(tq);

            
            if(tmp.flatten() != sum)
              begin
                 $display("Failed: %d vs %d ", sum, tmp.flatten());
                 $stop;
              end
            
         end
     end
   
   
   initial begin
      int i;
      ATimestamp a;
      BTimestamp b;

      a  = new;
      b  = new;
      
      wait(rst_n != 0);
      @(posedge clk_sys);

      for(i=0;i<num_tries;i++)
        begin
           a.randomize();
           b.randomize();

           ta       <= a.get();
           tb       <= b.get();

           expected.push_back(a.flatten() + b.flatten());
           
           valid_in <= 1;
   
           @(posedge clk_sys);
        end
      valid_in <= 0;
      @(posedge clk_sys);
      
   end

endmodule // main
