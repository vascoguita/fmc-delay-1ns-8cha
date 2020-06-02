onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Top /main/DUT/rst_n_i
add wave -noupdate -group Top /main/DUT/clk_20m_vcxo_i
add wave -noupdate -group Top /main/DUT/clk_125m_pllref_p_i
add wave -noupdate -group Top /main/DUT/clk_125m_pllref_n_i
add wave -noupdate -group Top /main/DUT/clk_125m_gtp_n_i
add wave -noupdate -group Top /main/DUT/clk_125m_gtp_p_i
add wave -noupdate -group Top /main/DUT/vme_write_n_i
add wave -noupdate -group Top /main/DUT/vme_sysreset_n_i
add wave -noupdate -group Top /main/DUT/vme_retry_oe_o
add wave -noupdate -group Top /main/DUT/vme_retry_n_o
add wave -noupdate -group Top /main/DUT/vme_lword_n_b
add wave -noupdate -group Top /main/DUT/vme_iackout_n_o
add wave -noupdate -group Top /main/DUT/vme_iackin_n_i
add wave -noupdate -group Top /main/DUT/vme_iack_n_i
add wave -noupdate -group Top /main/DUT/vme_gap_i
add wave -noupdate -group Top /main/DUT/vme_dtack_oe_o
add wave -noupdate -group Top /main/DUT/vme_dtack_n_o
add wave -noupdate -group Top /main/DUT/vme_ds_n_i
add wave -noupdate -group Top /main/DUT/vme_data_oe_n_o
add wave -noupdate -group Top /main/DUT/vme_data_dir_o
add wave -noupdate -group Top /main/DUT/vme_berr_o
add wave -noupdate -group Top /main/DUT/vme_as_n_i
add wave -noupdate -group Top /main/DUT/vme_addr_oe_n_o
add wave -noupdate -group Top /main/DUT/vme_addr_dir_o
add wave -noupdate -group Top /main/DUT/vme_irq_o
add wave -noupdate -group Top /main/DUT/vme_ga_i
add wave -noupdate -group Top /main/DUT/vme_data_b
add wave -noupdate -group Top /main/DUT/vme_am_i
add wave -noupdate -group Top /main/DUT/vme_addr_b
add wave -noupdate -group Top /main/DUT/pll20dac_din_o
add wave -noupdate -group Top /main/DUT/pll20dac_sclk_o
add wave -noupdate -group Top /main/DUT/pll20dac_sync_n_o
add wave -noupdate -group Top /main/DUT/pll25dac_din_o
add wave -noupdate -group Top /main/DUT/pll25dac_sclk_o
add wave -noupdate -group Top /main/DUT/pll25dac_sync_n_o
add wave -noupdate -group Top /main/DUT/sfp_txp_o
add wave -noupdate -group Top /main/DUT/sfp_txn_o
add wave -noupdate -group Top /main/DUT/sfp_rxp_i
add wave -noupdate -group Top /main/DUT/sfp_rxn_i
add wave -noupdate -group Top /main/DUT/sfp_mod_def0_i
add wave -noupdate -group Top /main/DUT/sfp_mod_def1_b
add wave -noupdate -group Top /main/DUT/sfp_mod_def2_b
add wave -noupdate -group Top /main/DUT/sfp_rate_select_o
add wave -noupdate -group Top /main/DUT/sfp_tx_fault_i
add wave -noupdate -group Top /main/DUT/sfp_tx_disable_o
add wave -noupdate -group Top /main/DUT/sfp_los_i
add wave -noupdate -group Top /main/DUT/carrier_scl_b
add wave -noupdate -group Top /main/DUT/carrier_sda_b
add wave -noupdate -group Top /main/DUT/pcbrev_i
add wave -noupdate -group Top /main/DUT/onewire_b
add wave -noupdate -group Top /main/DUT/uart_rxd_i
add wave -noupdate -group Top /main/DUT/uart_txd_o
add wave -noupdate -group Top /main/DUT/spi_sclk_o
add wave -noupdate -group Top /main/DUT/spi_ncs_o
add wave -noupdate -group Top /main/DUT/spi_mosi_o
add wave -noupdate -group Top /main/DUT/spi_miso_i
add wave -noupdate -group Top /main/DUT/fp_led_line_oen_o
add wave -noupdate -group Top /main/DUT/fp_led_line_o
add wave -noupdate -group Top /main/DUT/fp_led_column_o
add wave -noupdate -group Top /main/DUT/fp_gpio1_b
add wave -noupdate -group Top /main/DUT/fp_gpio2_b
add wave -noupdate -group Top /main/DUT/fp_gpio3_b
add wave -noupdate -group Top /main/DUT/fp_gpio4_b
add wave -noupdate -group Top /main/DUT/fp_term_en_o
add wave -noupdate -group Top /main/DUT/fp_gpio1_a2b_o
add wave -noupdate -group Top /main/DUT/fp_gpio2_a2b_o
add wave -noupdate -group Top /main/DUT/fp_gpio34_a2b_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_start_p_i
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_start_n_i
add wave -noupdate -group Top /main/DUT/fmc0_fd_clk_ref_p_i
add wave -noupdate -group Top /main/DUT/fmc0_fd_clk_ref_n_i
add wave -noupdate -group Top /main/DUT/fmc0_fd_trig_a_i
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_cal_pulse_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_d_b
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_emptyf_i
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_alutrigger_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_wr_n_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_rd_n_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_oe_n_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_led_trig_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_start_dis_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_tdc_stop_dis_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_spi_cs_dac_n_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_spi_cs_pll_n_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_spi_cs_gpio_n_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_spi_sclk_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_spi_mosi_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_spi_miso_i
add wave -noupdate -group Top /main/DUT/fmc0_fd_delay_len_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_delay_val_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_delay_pulse_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_dmtd_clk_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_dmtd_fb_in_i
add wave -noupdate -group Top /main/DUT/fmc0_fd_dmtd_fb_out_i
add wave -noupdate -group Top /main/DUT/fmc0_fd_pll_status_i
add wave -noupdate -group Top /main/DUT/fmc0_fd_ext_rst_n_o
add wave -noupdate -group Top /main/DUT/fmc0_fd_onewire_b
add wave -noupdate -group Top /main/DUT/fmc0_prsnt_m2c_n_i
add wave -noupdate -group Top /main/DUT/fmc0_scl_b
add wave -noupdate -group Top /main/DUT/fmc0_sda_b
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_start_p_i
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_start_n_i
add wave -noupdate -group Top /main/DUT/fmc1_fd_clk_ref_p_i
add wave -noupdate -group Top /main/DUT/fmc1_fd_clk_ref_n_i
add wave -noupdate -group Top /main/DUT/fmc1_fd_trig_a_i
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_cal_pulse_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_d_b
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_emptyf_i
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_alutrigger_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_wr_n_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_rd_n_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_oe_n_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_led_trig_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_start_dis_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_tdc_stop_dis_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_spi_cs_dac_n_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_spi_cs_pll_n_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_spi_cs_gpio_n_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_spi_sclk_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_spi_mosi_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_spi_miso_i
add wave -noupdate -group Top /main/DUT/fmc1_fd_delay_len_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_delay_val_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_delay_pulse_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_dmtd_clk_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_dmtd_fb_in_i
add wave -noupdate -group Top /main/DUT/fmc1_fd_dmtd_fb_out_i
add wave -noupdate -group Top /main/DUT/fmc1_fd_pll_status_i
add wave -noupdate -group Top /main/DUT/fmc1_fd_ext_rst_n_o
add wave -noupdate -group Top /main/DUT/fmc1_fd_onewire_b
add wave -noupdate -group Top /main/DUT/fmc1_prsnt_m2c_n_i
add wave -noupdate -group Top /main/DUT/fmc1_scl_b
add wave -noupdate -group Top /main/DUT/fmc1_sda_b
add wave -noupdate -group Top /main/DUT/cnx_master_out
add wave -noupdate -group Top /main/DUT/cnx_master_in
add wave -noupdate -group Top /main/DUT/cnx_slave_out
add wave -noupdate -group Top /main/DUT/cnx_slave_in
add wave -noupdate -group Top /main/DUT/areset_n
add wave -noupdate -group Top /main/DUT/clk_dmtd_125m
add wave -noupdate -group Top /main/DUT/clk_sys_62m5
add wave -noupdate -group Top /main/DUT/rst_sys_62m5_n
add wave -noupdate -group Top /main/DUT/clk_ref_125m
add wave -noupdate -group Top /main/DUT/vme_access_led
add wave -noupdate -group Top /main/DUT/pps
add wave -noupdate -group Top /main/DUT/pps_led
add wave -noupdate -group Top /main/DUT/svec_led
add wave -noupdate -group Top /main/DUT/wr_led_link
add wave -noupdate -group Top /main/DUT/wr_led_act
add wave -noupdate -group Top /main/DUT/irq_vector
add wave -noupdate -group Top /main/DUT/tm_link_up
add wave -noupdate -group Top /main/DUT/tm_tai
add wave -noupdate -group Top /main/DUT/tm_cycles
add wave -noupdate -group Top /main/DUT/tm_time_valid
add wave -noupdate -group Top /main/DUT/tm_clk_aux_lock_en
add wave -noupdate -group Top /main/DUT/tm_clk_aux_locked
add wave -noupdate -group Top /main/DUT/tm_dac_value
add wave -noupdate -group Top /main/DUT/tm_dac_wr
add wave -noupdate -group Top /main/DUT/dcm0_clk_ref_0
add wave -noupdate -group Top /main/DUT/dcm0_clk_ref_180
add wave -noupdate -group Top /main/DUT/fd0_tdc_start
add wave -noupdate -group Top /main/DUT/fd0_tdc_start_predelay
add wave -noupdate -group Top /main/DUT/fd0_tdc_start_iodelay_inc
add wave -noupdate -group Top /main/DUT/fd0_tdc_start_iodelay_rst
add wave -noupdate -group Top /main/DUT/fd0_tdc_start_iodelay_cal
add wave -noupdate -group Top /main/DUT/fd0_tdc_start_iodelay_ce
add wave -noupdate -group Top /main/DUT/tdc0_data_out
add wave -noupdate -group Top /main/DUT/tdc0_data_in
add wave -noupdate -group Top /main/DUT/tdc0_data_oe
add wave -noupdate -group Top /main/DUT/dcm1_clk_ref_0
add wave -noupdate -group Top /main/DUT/dcm1_clk_ref_180
add wave -noupdate -group Top /main/DUT/fd1_tdc_start
add wave -noupdate -group Top /main/DUT/fd1_tdc_start_predelay
add wave -noupdate -group Top /main/DUT/fd1_tdc_start_iodelay_inc
add wave -noupdate -group Top /main/DUT/fd1_tdc_start_iodelay_rst
add wave -noupdate -group Top /main/DUT/fd1_tdc_start_iodelay_cal
add wave -noupdate -group Top /main/DUT/fd1_tdc_start_iodelay_ce
add wave -noupdate -group Top /main/DUT/tdc1_data_out
add wave -noupdate -group Top /main/DUT/tdc1_data_in
add wave -noupdate -group Top /main/DUT/tdc1_data_oe
add wave -noupdate -group Top /main/DUT/ddr0_pll_reset
add wave -noupdate -group Top /main/DUT/ddr0_pll_locked
add wave -noupdate -group Top /main/DUT/fd0_pll_status
add wave -noupdate -group Top /main/DUT/ddr1_pll_reset
add wave -noupdate -group Top /main/DUT/ddr1_pll_locked
add wave -noupdate -group Top /main/DUT/fd1_pll_status
add wave -noupdate -group Top /main/DUT/fd0_scl_out
add wave -noupdate -group Top /main/DUT/fd0_scl_in
add wave -noupdate -group Top /main/DUT/fd0_sda_out
add wave -noupdate -group Top /main/DUT/fd0_sda_in
add wave -noupdate -group Top /main/DUT/fd1_scl_out
add wave -noupdate -group Top /main/DUT/fd1_scl_in
add wave -noupdate -group Top /main/DUT/fd1_sda_out
add wave -noupdate -group Top /main/DUT/fd1_sda_in
add wave -noupdate -group Top /main/DUT/fd0_owr_en
add wave -noupdate -group Top /main/DUT/fd0_owr_in
add wave -noupdate -group Top /main/DUT/fd1_owr_en
add wave -noupdate -group Top /main/DUT/fd1_owr_in
add wave -noupdate -group Top /main/DUT/fd0_irq
add wave -noupdate -group Top /main/DUT/fd1_irq
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/clk_ref_0_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/clk_ref_180_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/clk_sys_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/clk_dmtd_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rst_n_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dcm_reset_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dcm_locked_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/trig_a_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tdc_cal_pulse_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tdc_start_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dmtd_fb_in_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dmtd_fb_out_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dmtd_samp_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/led_trig_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/ext_rst_n_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/pll_status_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/acam_d_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/acam_d_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/acam_d_oen_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/acam_emptyf_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/acam_alutrigger_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/acam_wr_n_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/acam_rd_n_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/acam_start_dis_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/acam_stop_dis_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_dac_n_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_pll_n_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_gpio_n_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/spi_sclk_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/spi_mosi_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/spi_miso_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/delay_len_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/delay_val_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/delay_pulse_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tm_link_up_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tm_time_valid_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tm_cycles_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tm_utc_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tm_clk_aux_lock_en_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tm_clk_aux_locked_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tm_clk_dmtd_locked_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tm_dac_value_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tm_dac_wr_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/owr_en_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/owr_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/i2c_scl_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/i2c_scl_oen_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/i2c_scl_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/i2c_sda_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/i2c_sda_oen_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/i2c_sda_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/fmc_present_n_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/idelay_inc_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/idelay_cal_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/idelay_ce_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/idelay_rst_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/idelay_busy_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/wb_adr_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/wb_dat_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/wb_dat_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/wb_sel_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/wb_cyc_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/wb_stb_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/wb_we_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/wb_ack_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/wb_stall_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/wb_irq_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tdc_seconds_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tdc_cycles_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tdc_frac_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tdc_valid_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/outx_seconds_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/outx_cycles_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/outx_frac_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/outx_valid_i
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dbg_o
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tag_frac
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tag_coarse
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tag_utc
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tag_dbg
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tag_valid
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_mux_ts
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_mux_valid
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_mux_valid_masked
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_in_ts
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_source
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_valid
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_mux_d
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rbuf_mux_q
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/master_csync_p1
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/master_csync_utc
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/master_csync_coarse
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rst_n_sys
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/rst_n_ref
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tsbcr_read_ack
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/fid_read_ack
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/irq_rbuf
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/irq_sync
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/channels
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/chx_delay_idle
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/cnx_out
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/cnx_in
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/slave_in
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/slave_out
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/regs_fromwb
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_csync
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_spi
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_tsu
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_rbuf
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_local
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb_dmtd
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/regs_towb
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/owr_en_int
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/owr_int
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dbg_acam
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/gen_cal_pulse
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/cal_pulse_mask
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/cal_pulse_trigger
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tm_dac_val_int
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tcr_rd_ack
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tag_valid_masked
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dmtd_pattern
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/csync_pps
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/tdc_cal_pulse
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dmtr_in_rd_ack
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dmtr_out_rd_ack
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/pwm_count
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/pwm_out
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_dac_n
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_pll_n
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/spi_cs_gpio_n
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/spi_mosi
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dmtd_tag_stb
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dbg_tag_in
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/dbg_tag_out
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_ntaps
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_cnt
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_div
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_tick
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_cal_done
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_cal_in_progress
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_n_taps_load_refclk_p
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_busy_synced
add wave -noupdate -group fd0 /main/DUT/U_FineDelay_Core0/iodelay_latch_reset
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/clk_ref_0_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/clk_ref_180_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/clk_sys_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/clk_dmtd_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rst_n_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dcm_reset_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dcm_locked_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/trig_a_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tdc_cal_pulse_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tdc_start_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dmtd_fb_in_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dmtd_fb_out_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dmtd_samp_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/led_trig_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/ext_rst_n_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/pll_status_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/acam_d_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/acam_d_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/acam_d_oen_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/acam_emptyf_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/acam_alutrigger_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/acam_wr_n_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/acam_rd_n_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/acam_start_dis_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/acam_stop_dis_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/spi_cs_dac_n_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/spi_cs_pll_n_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/spi_cs_gpio_n_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/spi_sclk_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/spi_mosi_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/spi_miso_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/delay_len_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/delay_val_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/delay_pulse_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tm_link_up_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tm_time_valid_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tm_cycles_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tm_utc_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tm_clk_aux_lock_en_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tm_clk_aux_locked_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tm_clk_dmtd_locked_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tm_dac_value_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tm_dac_wr_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/owr_en_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/owr_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/i2c_scl_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/i2c_scl_oen_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/i2c_scl_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/i2c_sda_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/i2c_sda_oen_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/i2c_sda_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/fmc_present_n_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/idelay_inc_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/idelay_cal_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/idelay_ce_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/idelay_rst_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/idelay_busy_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/wb_adr_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/wb_dat_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/wb_dat_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/wb_sel_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/wb_cyc_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/wb_stb_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/wb_we_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/wb_ack_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/wb_stall_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/wb_irq_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tdc_seconds_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tdc_cycles_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tdc_frac_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tdc_valid_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/outx_seconds_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/outx_cycles_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/outx_frac_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/outx_valid_i
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dbg_o
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tag_frac
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tag_coarse
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tag_utc
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tag_dbg
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tag_valid
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rbuf_mux_ts
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rbuf_mux_valid
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rbuf_mux_valid_masked
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rbuf_in_ts
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rbuf_source
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rbuf_valid
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rbuf_mux_d
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rbuf_mux_q
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/master_csync_p1
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/master_csync_utc
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/master_csync_coarse
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rst_n_sys
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/rst_n_ref
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tsbcr_read_ack
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/fid_read_ack
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/irq_rbuf
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/irq_sync
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/channels
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/chx_delay_idle
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/cnx_out
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/cnx_in
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/slave_in
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/slave_out
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/regs_fromwb
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/regs_towb_csync
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/regs_towb_spi
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/regs_towb_tsu
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/regs_towb_rbuf
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/regs_towb_local
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/regs_towb_dmtd
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/regs_towb
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/owr_en_int
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/owr_int
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dbg_acam
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/gen_cal_pulse
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/cal_pulse_mask
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/cal_pulse_trigger
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tm_dac_val_int
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tcr_rd_ack
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tag_valid_masked
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dmtd_pattern
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/csync_pps
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/tdc_cal_pulse
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dmtr_in_rd_ack
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dmtr_out_rd_ack
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/pwm_count
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/pwm_out
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/spi_cs_dac_n
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/spi_cs_pll_n
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/spi_cs_gpio_n
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/spi_mosi
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dmtd_tag_stb
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dbg_tag_in
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/dbg_tag_out
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/iodelay_ntaps
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/iodelay_cnt
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/iodelay_div
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/iodelay_tick
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/iodelay_cal_done
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/iodelay_cal_in_progress
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/iodelay_n_taps_load_refclk_p
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/iodelay_busy_synced
add wave -noupdate -group fd1 /main/DUT/U_FineDelay_Core1/iodelay_latch_reset
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/BUSY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DATAOUT
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DATAOUT2
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DOUT
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/TOUT
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/CAL
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/CE
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/CLK
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IDATAIN
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/INC
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IOCLK0
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IOCLK1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/ODATAIN
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/RST
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/T
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/COUNTER_WRAPAROUND_BINARY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DATA_RATE_BINARY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DELAY_SRC_BINARY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IDELAY2_VALUE_BINARY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IDELAY_MODE_BINARY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IDELAY_TYPE_BINARY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IDELAY_VALUE_BINARY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/ODELAY_VALUE_BINARY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/SERDES_MODE_BINARY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/SIM_TAPDELAY_VALUE_BINARY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/Tstep
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/COUNTER_WRAPAROUND_PAD
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DELAY_SRC_PAD
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IDELAY_MODE_PAD
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IDELAY_TYPE_PAD
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/SERDES_MODE_PAD
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/GSR_INDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/rst_sig
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/ce_sig
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/inc_sig
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/cal_sig
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_out_sig
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_out
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay2_out
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_out_dly
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/tout_out_int
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/busy_out_int
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/busy_out_pe_one_shot
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/busy_out_ne_one_shot
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/busy_out_dly
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/busy_out_pe_dly
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/busy_out_pe_dly1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/busy_out_ne_dly
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/busy_out_ne_dly1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/sdo_out_int
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/ioclk0_int
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/ioclk1_int
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/ioclk_int
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/first_edge
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/sat_at_max_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/rst_to_half_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/ignore_rst
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/force_rx_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/force_dly_dir_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/output_delay_off
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/input_delay_off
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/isslave
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/encasc
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/counter_wraparound_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/data_rate_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/serdes_mode_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/odelay_value_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_value_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/sim_tap_delay_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_type_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_mode_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay_src_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay2_value_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/attr_err_flag
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/cal_count
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/cal_delay
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/max_delay
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/half_max
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay_val_pe_1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay_val_ne_1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay_val_pe_clk
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay_val_ne_clk
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/first_time_pe
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/first_time_ne
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_val_pe_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_val_pe_m_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_val_pe_s_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_val_pe_m_reg1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_val_pe_s_reg1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_val_ne_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_val_ne_m_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_val_ne_s_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_val_ne_m_reg1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/idelay_val_ne_s_reg1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_reached
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_reached_1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_reached_2
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_working
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_working_1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_working_2
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_ignore
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay_val_pe_2
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay_val_ne_2
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/odelay_val_pe_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/odelay_val_ne_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay2_reached
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay2_reached_1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay2_reached_2
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay2_working
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay2_working_1
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay2_working_2
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay2_ignore
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay1_in
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/delay2_in
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/calibrate
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/calibrate_done
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/sync_to_data_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/pci_ce_reg
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/BUSY_OUT
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DATAOUT2_OUT
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DATAOUT_OUT
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DOUT_OUT
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/TOUT_OUT
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/BUSY_OUTDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DATAOUT2_OUTDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DATAOUT_OUTDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/DOUT_OUTDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/TOUT_OUTDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/CAL_ipd
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/CE_ipd
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/CLK_ipd
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IDATAIN_ipd
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/INC_ipd
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IOCLK0_ipd
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IOCLK1_ipd
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/ODATAIN_ipd
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/RST_ipd
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/T_ipd
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/CAL_INDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/CE_INDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/CLK_INDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IDATAIN_INDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/INC_INDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IOCLK0_INDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/IOCLK1_INDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/ODATAIN_INDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/RST_INDELAY
add wave -noupdate -expand -group Dly1 /main/DUT/cmp_fd_tdc_start_delay1/T_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/BUSY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT2
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DOUT
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/TOUT
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/CAL
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/CE
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/CLK
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IDATAIN
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/INC
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK0
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/ODATAIN
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/RST
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/T
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/COUNTER_WRAPAROUND_BINARY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DATA_RATE_BINARY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DELAY_SRC_BINARY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY2_VALUE_BINARY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY_MODE_BINARY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY_TYPE_BINARY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY_VALUE_BINARY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/ODELAY_VALUE_BINARY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/SERDES_MODE_BINARY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/SIM_TAPDELAY_VALUE_BINARY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/Tstep
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/COUNTER_WRAPAROUND_PAD
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DELAY_SRC_PAD
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY_MODE_PAD
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY_TYPE_PAD
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/SERDES_MODE_PAD
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/GSR_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/rst_sig
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/ce_sig
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/inc_sig
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/cal_sig
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_out_sig
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_out
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_out
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_out_dly
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/tout_out_int
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_int
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_pe_one_shot
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_ne_one_shot
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_dly
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_pe_dly
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_pe_dly1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_ne_dly
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_ne_dly1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/sdo_out_int
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/ioclk0_int
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/ioclk1_int
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/ioclk_int
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/first_edge
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/sat_at_max_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/rst_to_half_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/ignore_rst
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/force_rx_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/force_dly_dir_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/output_delay_off
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/input_delay_off
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/isslave
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/encasc
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/counter_wraparound_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/data_rate_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/serdes_mode_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/odelay_value_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_value_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/sim_tap_delay_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_type_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_mode_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay_src_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay2_value_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/attr_err_flag
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/cal_count
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/cal_delay
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/max_delay
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/half_max
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_pe_1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_ne_1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_pe_clk
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_ne_clk
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/first_time_pe
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/first_time_ne
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_pe_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_pe_m_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_pe_s_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_pe_m_reg1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_pe_s_reg1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_ne_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_ne_m_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_ne_s_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_ne_m_reg1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_ne_s_reg1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_reached
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_reached_1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_reached_2
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_working
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_working_1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_working_2
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_ignore
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_pe_2
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_ne_2
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/odelay_val_pe_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/odelay_val_ne_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_reached
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_reached_1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_reached_2
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_working
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_working_1
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_working_2
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_ignore
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_in
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_in
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/calibrate
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/calibrate_done
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/sync_to_data_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/pci_ce_reg
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/BUSY_OUT
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT2_OUT
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT_OUT
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DOUT_OUT
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/TOUT_OUT
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/BUSY_OUTDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT2_OUTDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT_OUTDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/DOUT_OUTDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/TOUT_OUTDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/CAL_ipd
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/CE_ipd
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/CLK_ipd
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IDATAIN_ipd
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/INC_ipd
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK0_ipd
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK1_ipd
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/ODATAIN_ipd
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/RST_ipd
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/T_ipd
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/CAL_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/CE_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/CLK_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IDATAIN_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/INC_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK0_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK1_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/ODATAIN_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/RST_INDELAY
add wave -noupdate -expand -group Dly0 /main/DUT/cmp_fd_tdc_start_delay0/T_INDELAY
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {101484936 ps} 0}
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
WaveRestoreZoom {0 ps} {382976 ns}
