# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

files = ["svec_fine_delay_top.vhd"]

fetchto = "../../ip_cores"

modules = {
    "local" : [
	"../../rtl", 
	"../../platform",
	"../../ip_cores/general-cores",
	"../../ip_cores/wr-cores",
	"../../ip_cores/wr-cores/board/svec",
	"../../ip_cores/vme64x-core",
	"../../ip_cores/svec",
	"../../ip_cores/ddr3-sp6-core",
     ]
    }
