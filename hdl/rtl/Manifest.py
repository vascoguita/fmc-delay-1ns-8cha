files = ["fd_acam_timestamper.vhd",
         "fd_ring_buffer.vhd",
         "fd_ts_adder.vhd",
         "fd_reset_generator.vhd",
         "fd_csync_generator.vhd",
         "fd_timestamper_stat_unit.vhd",
         "fd_acam_timestamp_postprocessor.vhd",
         "fd_delay_channel_driver.vhd",
         "fd_delay_line_arbiter.vhd",
         "fd_spi_master.vhd",
         "fd_spi_dac_arbiter.vhd",
         "fine_delay_pkg.vhd",
         "fine_delay_core.vhd",
         "fd_channel_wishbone_slave.vhd",
         "fd_main_wishbone_slave.vhd",
         "fd_channel_wbgen2_pkg.vhd",
         "fd_main_wbgen2_pkg.vhd",
         "fd_dmtd_insertion_calibrator.vhd",
         "fd_dmtd_with_deglitcher.vhd"
    ];

fetchto = "../ip_cores"

modules = { "git" : [ "git@ohwr.org:hdl-core-lib/general-cores.git::master"] }

