ctrls = ["bank3_32b_32b"]
action = "simulation"
target = "xilinx"
vcom_opt="-mixedsvvh l"
fetchto = "../../ip_cores"
include_dirs = ["../../include/vme64x_bfm",
                "../../include",
                "../../ip_cores/general-cores/modules/wishbone/wb_spi/",
                "../../ip_cores/general-cores/sim/",
                "../../ip_cores/general-cores/modules/wishbone/wb_lm32/src/"]
syn_device = "xc6slx45t"
sim_tool = "modelsim"
sim_top = "main"
top_module = "main"
files = ["main.sv","buildinfo_pkg.vhd"]

modules = {"local":  ["../../top/svec" ]}

#try:
exec(open(fetchto + "/general-cores/tools/gen_buildinfo.py").read())
#except:
#  pass
