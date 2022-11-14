// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: CERN-OHL-W-2.0+

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
   
   int cur_dly;
   
   reg o_reg    = 0;

   bit dly[0:2000];
   int ptr = 0;

   always #(c_time_per_tap)
     begin
        dly[ptr++] = i;
        if(ptr == 1024)
          ptr = 0;
     end
   
   
   assign o     = dly[ptr - 1 - cur_dly < 0 ? ptr -1 -cur_dly + 1024: ptr-1-cur_dly];
   

   always@(posedge len)
     begin
        cur_dly <= delay;
     end
   
   


endmodule // mc100ep195
