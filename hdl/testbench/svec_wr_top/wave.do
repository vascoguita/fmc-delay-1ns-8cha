onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/clk_ref_0_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/clk_ref_180_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/clk_sys_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/clk_dmtd_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rst_n_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dcm_reset_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dcm_locked_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/trig_a_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tdc_cal_pulse_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tdc_start_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dmtd_fb_in_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dmtd_fb_out_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dmtd_samp_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/led_trig_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/ext_rst_n_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/pll_status_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/acam_d_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/acam_d_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/acam_d_oen_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/acam_emptyf_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/acam_alutrigger_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/acam_wr_n_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/acam_rd_n_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/acam_start_dis_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/acam_stop_dis_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_dac_n_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_pll_n_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_gpio_n_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/spi_sclk_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/spi_mosi_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/spi_miso_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/delay_len_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/delay_val_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/delay_pulse_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tm_link_up_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tm_time_valid_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tm_cycles_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tm_utc_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tm_clk_aux_lock_en_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tm_clk_aux_locked_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tm_clk_dmtd_locked_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tm_dac_value_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tm_dac_wr_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/owr_en_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/owr_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/i2c_scl_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/i2c_scl_oen_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/i2c_scl_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/i2c_sda_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/i2c_sda_oen_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/i2c_sda_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/fmc_present_n_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/idelay_inc_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/idelay_cal_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/idelay_ce_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/idelay_rst_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/wb_adr_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/wb_dat_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/wb_dat_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/wb_sel_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/wb_cyc_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/wb_stb_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/wb_we_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/wb_ack_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/wb_stall_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/wb_irq_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tdc_seconds_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tdc_cycles_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tdc_frac_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tdc_valid_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/outx_seconds_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/outx_cycles_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/outx_frac_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/outx_valid_i
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dbg_o
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tag_frac
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tag_coarse
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tag_utc
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tag_dbg
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tag_valid
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_mux_ts
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_mux_valid
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_mux_valid_masked
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_in_ts
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_source
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_valid
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_mux_d
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_mux_q
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/master_csync_p1
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/master_csync_utc
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/master_csync_coarse
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rst_n_sys
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/rst_n_ref
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tsbcr_read_ack
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/fid_read_ack
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/irq_rbuf
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/irq_spll
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/irq_sync
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/channels
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/chx_delay_idle
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/cnx_out
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/cnx_in
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/slave_in
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/slave_out
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/regs_fromwb
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_csync
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_spi
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_tsu
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_rbuf
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_local
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_dmtd
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/owr_en_int
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/owr_int
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dbg_acam
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/gen_cal_pulse
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/cal_pulse_mask
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/cal_pulse_trigger
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tm_dac_val_int
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tcr_rd_ack
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tag_valid_masked
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dmtd_pattern
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/csync_pps
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/tdc_cal_pulse
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dmtr_in_rd_ack
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dmtr_out_rd_ack
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/pwm_count
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/pwm_out
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_dac_n
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_pll_n
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_gpio_n
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/spi_mosi
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dmtd_tag_stb
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dbg_tag_in
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/dbg_tag_out
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_ntaps
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_cnt
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_div
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_tick
add wave -noupdate -expand -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_cal_done
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {23947022 ps} 0}
configure wave -namecolwidth 486
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {23573029 ps} {24321015 ps}
