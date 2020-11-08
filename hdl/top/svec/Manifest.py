files = ["svec_fine_delay_top.vhd", "svec_fine_delay_top.ucf"]

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
