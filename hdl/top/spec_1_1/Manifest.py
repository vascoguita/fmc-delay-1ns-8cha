files = [
"spec_top_finedelay.vhd",
"spec_top_finedelay.ucf",
"wb_gpio_port_notristates.vhd"
];

fetchto = "../../ip_cores"

modules = {"local" : "../../rtl",
					 "svn" : "http://svn.ohwr.org/gn4124-core/branches/hdlmake-compliant/rtl" }