#!/bin/bash

~/wbgen2/wishbone-gen/wbgen2 -V fine_delay_wb.vhd -H record -p fd_registers_pkg.vhd -K ../sim/fine_delay_regs.v -s defines -C fd_core.h -D 1.html fine_delay_wb.wb 