`ifndef __TIMESTAMP_SVH
 `define __TIMESTAMP_SVH

class Timestamp;

   int utc, coarse, frac, coarse_range, seq_id;
   
   function new(int _utc=0 ,int _coarse=0, int _frac=0,int _seq_id = 0, int _coarse_range = 256);
      utc           = _utc;
      coarse        = _coarse;
      frac          = _frac;
      coarse_range  = _coarse_range;
      seq_id        = _seq_id;
      
   endfunction // new
   
   function real flatten();
      return real'(utc) * real'(coarse_range * 8) + real'(coarse) * 8.0 + (real'(frac)/4096.0 * 8.0);
   endfunction // flatten

   task unflatten(int x);
      int t;
      t       =x;
      
      frac    = x % 4096;
      x       = x - frac;
      x       = x/4096;
      coarse  = x % 256;
      x       = x - coarse;
      x       = x/256;
      utc     = x;
      $display("Unflat: %d %d %d %d", t, utc, coarse, frac);
      

   endtask // unflatten
   

   function Timestamp sub(Timestamp b);

   endfunction

endclass      

`endif //  `ifndef __TIMESTAMP_SVH
