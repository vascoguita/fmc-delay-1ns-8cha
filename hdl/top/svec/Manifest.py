files = [ "synthesis_descriptor.vhd", "svec_top.vhd", "svec_top.ucf", "bicolor_led_ctrl.vhd", "bicolor_led_ctrl_pkg.vhd" ]

fetchto = "../../ip_cores"

modules = {
    "local" : ["../../rtl", "../../platform" ],
    "git" : [ "git://ohwr.org/hdl-core-lib/wr-cores.git",
    					"git://ohwr.org/hdl-core-lib/vme64x-core.git" ]
    }
