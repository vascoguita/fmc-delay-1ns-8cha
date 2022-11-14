# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

files = ["spec_fine_delay_top.vhd", "spec_fine_delay_top.ucf"]

fetchto = "../../ip_cores"

modules = {
    "local" : [
	"../../rtl", 
	"../../platform",
	"../../ip_cores/general-cores",
	"../../ip_cores/wr-cores",
	"../../ip_cores/wr-cores/board/spec",
	"../../ip_cores/gn4124-core",
	"../../ip_cores/spec",
	"../../ip_cores/ddr3-sp6-core"
     ]
    }
