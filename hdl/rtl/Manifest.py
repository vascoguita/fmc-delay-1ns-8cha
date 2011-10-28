files = ["fd_acam_timestamper.vhd",
         "fd_wbgen2_pkg.vhd",
         "fd_ring_buffer.vhd",
         "fd_ts_adder.vhd",
         "fd_ts_normalizer.vhd",
         "fd_reset_generator.vhd",
         "fd_csync_generator.vhd",
         "fd_timestamper_stat_unit.vhd",
         "fd_acam_timestamp_postprocessor.vhd",
         "fd_delay_channel_driver.vhd",
         "fd_delay_line_arbiter.vhd",
         "fd_rearm_generator.vhd",
         "fd_wishbone_slave.vhd",
         "fd_spi_master.vhd",
         "fd_spi_dac_arbiter.vhd",
         "fine_delay_pkg.vhd",
         "fine_delay_core.vhd"];

fetchto = "../ip_cores"

modules = {
    "git" :  [
        "git@ohwr.org:hdl-core-lib/wr-cores.git",
        "git@ohwr.org:hdl-core-lib/general-cores.git" ],
    "svn" : [ "http://svn.ohwr.org/gn4124-core/branches/hdlmake-compliant/rtl" ]
 };
