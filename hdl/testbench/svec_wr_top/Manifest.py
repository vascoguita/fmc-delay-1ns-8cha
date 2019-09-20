action = "simulation"
target = "xilinx"
fetchto = "../../ip_cores"
sim_tool="modelsim"
sim_top="main"

include_dirs = ["../../include/wb", "../../include/vme64x_bfm", "../../include" ];
syn_device="xc6slx150t"

files = [ "main.sv" ]

modules = { "local" :  [ "../../top/svec" ] }

