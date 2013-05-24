files = [ "synthesis_descriptor.vhd", "svec_top.vhd", "svec_top.ucf", "xvme64x_core.vhd" ]

fetchto = "../../../ip_cores"

modules = {
    "local" : ["../../../rtl", "../../../platform" ],
    "git" : [ "git://ohwr.org/hdl-core-lib/wr-cores.git" ],
#    					"git://ohwr.org/hdl-core-lib/etherbone-core.git" ],
    "svn" : [ "http://svn.ohwr.org/vme64x-core/trunk/hdl/vme64x-core/rtl" ]
    }
