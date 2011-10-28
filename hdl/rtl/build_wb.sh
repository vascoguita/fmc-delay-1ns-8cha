#!/bin/bash

~/wbgen2/wishbone-gen/wbgen2 -V fd_wishbone_slave.vhd -H record -p fd_wbgen2_pkg.vhd -K ../include/fine_delay_regs.v -s defines -C fd_core.h -D 1.html fd_wishbone_slave.wb 