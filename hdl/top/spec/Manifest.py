files = ["spec_top.vhd", "spec_top.ucf"]

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
