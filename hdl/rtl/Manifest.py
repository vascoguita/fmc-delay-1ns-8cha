files = ["fd_acam_timestamper.vhd",
	       "fd_cal_pulse_gen.vhd",
				 "fd_delay_line_driver.vhd",
         "fd_wbgen2_pkg.vhd",
         "fine_delay_core.vhd",
         "fine_delay_pkg.vhd",
         "fine_delay_wb.vhd"]

fetchto = "../ip_cores"

modules = {

					 "git" :  [
										"git@ohwr.org:hdl-core-lib/wr-cores.git",
										"git@ohwr.org:hdl-core-lib/general-cores.git" ],
   				 "svn" : [ "http://svn.ohwr.org/gn4124-core/branches/hdlmake-compliant/rtl" ]

					}

