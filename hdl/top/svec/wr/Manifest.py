files = [ "svec_top.vhd", "svec_top.ucf", "xvme64x_core.vhd", "spec_serial_dac.vhd" ]

fetchto = "../../../ip_cores"

modules = {
    "local" : ["../../../rtl", "../../../platform", "../../../ip_cores/vme64x-core" ],
    "git" : [ "git://ohwr.org/hdl-core-lib/wr-cores.git::wishbonized" ]
 #   "svn" : [ "http://svn.ohwr.org/vme64x-core/trunk/hdl/vme64x-core/rtl" ]
    }
