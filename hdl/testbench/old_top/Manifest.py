# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

target = "xilinx"
action = "simulation"

vlog_opt="+incdir+../../include +incdir+../../include/wb"

files = "main.sv"
modules = {"local": [ "../../" ] }
