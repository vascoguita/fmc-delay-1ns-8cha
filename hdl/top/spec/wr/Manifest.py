files = ["spec_top.vhd", "spec_top.ucf", "spec_serial_dac.vhd", "spec_serial_dac_arb.vhd"]

fetchto = "../../../ip_cores"

modules = {
    "local" : ["../../../rtl", "../../../platform", "mini_bone" ],
    "git" : [ "git://ohwr.org/hdl-core-lib/wr-cores.git::wishbonized" ],
    "svn" : [ "http://svn.ohwr.org/gn4124-core/trunk/hdl/gn4124core/rtl" ]
    }
