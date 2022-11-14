#!/bin/bash

# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

wbgen2 -V fd_main_wishbone_slave.vhd -H record -p fd_main_wbgen2_pkg.vhd -K ../include/regs/fd_main_regs.vh -s defines -C fd_main_regs.h -f texinfo -D ../../doc/design-notes/fd_main_regs.in fd_main_wishbone_slave.wb 
wbgen2 -V fd_channel_wishbone_slave.vhd -H record -p fd_channel_wbgen2_pkg.vhd -K ../include/regs/fd_channel_regs.vh -s defines -C fd_channel_regs.h -f texinfo -D ../../doc/design-notes/fd_channel_regs.in fd_channel_wishbone_slave.wb 