`ifndef __TIMESTAMP_SVH
 `define __TIMESTAMP_SVH

`include "wb/simdrv_defs.svh"

class Timestamp;
   uint64_t utc;
   
   int coarse, frac, coarse_range, seq_id, source;
   
   function new(int _utc=0 ,int _coarse=0, int _frac=0,int _seq_id = 0, int _coarse_range = 125000000);
      utc           = _utc;
      coarse        = _coarse;
      frac          = _frac;
      coarse_range  = _coarse_range;
      seq_id        = _seq_id;
      source = 0;
   endfunction // new
   
   function real flatten();
      return real'(utc) * real'(coarse_range * 8) + real'(coarse) * 8.0 + (real'(frac)/4096.0 * 8.0);
   endfunction // flatten

   task from_ps(int x);
      unflatten(uint64_t'(x) * 4096 / 8000);
   endtask // from_ps
   
   
   task unflatten(int x);
      int t;
      t       =x;
      
      frac    = x % 4096;
      x       = x - frac;
      x       = x/4096;
      coarse  = x % coarse_range;
      x       = x - coarse;
      x       = x/coarse_range;
      utc     = x;
      $display("Unflat: %d %d %d %d", t, utc, coarse, frac);
      

   endtask // unflatten


   

   function Timestamp add(Timestamp b);
      Timestamp r = new;

      r.frac = frac+b.frac;
      r.coarse = coarse + b.coarse;
      r.utc = utc + b.utc;
      if(r.frac >= 4096)
        begin
           r.frac -= 4096;
           r.coarse++;
        end

      if(r.coarse >= coarse_range)
        begin
           r.utc ++;
           r.coarse -= coarse_range;
        end
      return r;
      
   endfunction

   
   
endclass      

`endif //  `ifndef __TIMESTAMP_SVH
