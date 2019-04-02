target = "xilinx"
action = "synthesis"

fetchto = "../../ip_cores"

syn_device = "xc6slx150t"
syn_grade = "-3"
syn_package = "fgg900"
syn_top = "svec_top"
syn_project = "svec_fine_delay.xise"
syn_tool="ise"

#files = [ "wrc-release.ram" ]
modules = { "local" : [ "../../top/svec", "../../platform" ] }
