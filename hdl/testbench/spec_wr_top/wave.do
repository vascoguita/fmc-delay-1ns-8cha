onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_125m_pllref_p_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_125m_pllref_n_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_20m_vcxo_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_125m_gtp_n_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_125m_gtp_p_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_aux_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_rst_n_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_p2l_clk_n_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_p2l_clk_p_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_p2l_rdy_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_p2l_dframe_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_p2l_valid_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_p2l_data_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_p_wr_req_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_p_wr_rdy_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_rx_error_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_l2p_clk_n_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_l2p_clk_p_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_l2p_dframe_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_l2p_valid_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_l2p_edb_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_l2p_data_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_l2p_rdy_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_l_wr_rdy_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_p_rd_d_rdy_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_tx_error_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_vc_rdy_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_gpio_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/fmc0_scl_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/fmc0_sda_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/fmc0_prsnt_m2c_n_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/onewire_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/spi_sclk_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/spi_ncs_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/spi_mosi_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/spi_miso_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/pcbrev_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/led_act_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/led_link_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/button1_n_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/uart_rxd_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/uart_txd_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/plldac_sclk_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/plldac_din_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/pll25dac_cs_n_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/pll20dac_cs_n_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_txp_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_txn_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_rxp_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_rxn_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_mod_def0_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_mod_def1_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_mod_def2_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_rate_select_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_tx_fault_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_tx_disable_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_los_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_a_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_ba_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_cas_n_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_ck_n_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_ck_p_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_cke_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dq_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_ldm_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_ldqs_n_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_ldqs_p_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_odt_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_ras_n_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_reset_n_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_rzq_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_udm_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_udqs_n_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_udqs_p_b
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_we_n_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_clk_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_rst_n_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_wb_cyc_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_wb_stb_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_wb_adr_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_wb_sel_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_wb_we_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_wb_dat_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_wb_ack_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_wb_stall_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_dma_wb_dat_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_wr_fifo_empty_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_dmtd_125m_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_62m5_sys_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/rst_62m5_sys_n_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_125m_ref_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/rst_125m_ref_n_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/irq_user_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrf_src_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrf_src_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrf_snk_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrf_snk_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_tx_data_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_tx_valid_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_tx_dreq_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_tx_last_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_tx_flush_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_tx_cfg_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_rx_first_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_rx_last_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_rx_data_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_rx_valid_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_rx_dreq_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrs_rx_cfg_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wb_eth_master_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wb_eth_master_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/tm_link_up_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/tm_time_valid_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/tm_tai_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/tm_cycles_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/tm_dac_value_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/tm_dac_wr_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/tm_clk_aux_lock_en_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/tm_clk_aux_locked_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/pps_p_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/pps_led_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/link_ok_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/app_wb_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/app_wb_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sim_wb_i
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sim_wb_o
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_62m5_sys
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_pll_aux
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/rst_pll_aux_n
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_333m_ddr
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/rst_333m_ddr_n
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_rst
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_status
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/ddr_calib_done
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_wb_ddr_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_wb_ddr_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_wb_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gn_wb_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/carrier_wb_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/carrier_wb_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/gennum_status
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/metadata_addr
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/metadata_data
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/buildinfo_addr
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/buildinfo_data
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/therm_id_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/therm_id_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/fmc_i2c_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/fmc_i2c_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/dma_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/dma_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/flash_spi_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/flash_spi_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/vic_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/vic_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrc_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrc_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrc_out_sh
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/csr_rst_gbl
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/csr_rst_app
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/rst_csr_app_n
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/rst_csr_app_sync_n
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/rst_gbl_n
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/fmc0_scl_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/fmc0_sda_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/fmc0_scl_oen
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/fmc0_sda_oen
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/fmc_presence
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/irq_master
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/irqs
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/rst_62m5_sys_n
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/rst_125m_ref_n
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_125m_ref
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/clk_10m_ext
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/eeprom_sda_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/eeprom_sda_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/eeprom_scl_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/eeprom_scl_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_sda_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_sda_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_scl_in
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/sfp_scl_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrc_abscal_txts_out
add wave -noupdate -group SpecBase /main/DUT/inst_spec_base/wrc_abscal_rxts_out
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/rst_n_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/clk_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_cyc_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_stb_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_adr_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_sel_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_we_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_dat_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_ack_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_err_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_rty_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_stall_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_dat_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/metadata_addr_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/metadata_data_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/metadata_data_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/metadata_wr_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/csr_app_offset_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/csr_resets_global_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/csr_resets_appl_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/csr_fmc_presence_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/csr_gn4124_status_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/csr_ddr_status_calib_done_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/csr_pcb_rev_rev_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/therm_id_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/therm_id_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/fmc_i2c_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/fmc_i2c_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/flash_spi_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/flash_spi_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/dma_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/dma_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/vic_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/vic_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/buildinfo_addr_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/buildinfo_data_i
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/buildinfo_data_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/buildinfo_wr_o
add wave -noupdate -group Devs -expand /main/DUT/inst_spec_base/inst_devs/wrc_regs_i
add wave -noupdate -group Devs -expand /main/DUT/inst_spec_base/inst_devs/wrc_regs_o
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/rd_int
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wr_int
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/rd_ack_int
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wr_ack_int
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_en
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/ack_int
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_rip
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wb_wip
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/metadata_rack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/metadata_re
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/csr_resets_global_reg
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/csr_resets_appl_reg
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/therm_id_re
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/therm_id_wt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/therm_id_rt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/therm_id_tr
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/therm_id_wack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/therm_id_rack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/fmc_i2c_re
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/fmc_i2c_wt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/fmc_i2c_rt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/fmc_i2c_tr
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/fmc_i2c_wack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/fmc_i2c_rack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/flash_spi_re
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/flash_spi_wt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/flash_spi_rt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/flash_spi_tr
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/flash_spi_wack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/flash_spi_rack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/dma_re
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/dma_wt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/dma_rt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/dma_tr
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/dma_wack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/dma_rack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/vic_re
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/vic_wt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/vic_rt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/vic_tr
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/vic_wack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/vic_rack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/buildinfo_rack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/buildinfo_re
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wrc_regs_re
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wrc_regs_wt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wrc_regs_rt
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wrc_regs_tr
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wrc_regs_wack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/wrc_regs_rack
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/reg_rdat_int
add wave -noupdate -group Devs /main/DUT/inst_spec_base/inst_devs/rd_ack1_int
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_sys_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_dmtd_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_ref_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_aux_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_ext_mul_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_ext_mul_locked_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_ext_stopped_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_ext_rst_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_ext_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/pps_ext_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/rst_n_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/dac_hpll_load_p1_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/dac_hpll_data_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/dac_dpll_load_p1_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/dac_dpll_data_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_ref_clk_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_tx_data_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_tx_k_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_tx_disparity_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_tx_enc_err_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_rx_data_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_rx_rbclk_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_rx_k_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_rx_enc_err_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_rx_bitslide_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_rst_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_rdy_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_loopen_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_loopen_vec_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_tx_prbs_sel_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_sfp_tx_fault_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_sfp_los_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_sfp_tx_disable_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_rx_rbclk_sampled_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_lpc_stat_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_lpc_ctrl_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy8_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy8_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy16_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy16_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/led_act_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/led_link_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/scl_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/scl_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/sda_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/sda_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/sfp_scl_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/sfp_scl_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/sfp_sda_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/sfp_sda_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/sfp_det_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/btn1_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/btn2_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/spi_sclk_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/spi_ncs_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/spi_mosi_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/spi_miso_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/uart_rxd_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/uart_txd_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/owr_pwren_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/owr_en_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/owr_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_adr_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_dat_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_dat_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_sel_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_we_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_cyc_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_stb_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_ack_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_err_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_rty_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/wb_stall_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_adr_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_dat_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_dat_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_sel_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_we_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_cyc_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_stb_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_ack_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_stall_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_snk_adr_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_snk_dat_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_snk_sel_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_snk_cyc_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_snk_we_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_snk_stb_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_snk_ack_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_snk_err_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_snk_stall_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_src_adr_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_src_dat_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_src_sel_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_src_cyc_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_src_stb_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_src_we_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_src_ack_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_src_err_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_src_stall_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/txtsu_port_id_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/txtsu_frame_id_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/txtsu_ts_value_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/txtsu_ts_incorrect_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/txtsu_stb_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/txtsu_ack_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/abscal_txts_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/abscal_rxts_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/fc_tx_pause_req_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/fc_tx_pause_delay_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/fc_tx_pause_ready_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/tm_link_up_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/tm_dac_value_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/tm_dac_wr_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/tm_clk_aux_lock_en_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/tm_clk_aux_locked_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/tm_time_valid_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/tm_tai_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/tm_cycles_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/pps_csync_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/pps_valid_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/pps_p_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/pps_led_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/rst_aux_n_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/link_ok_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_diag_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/aux_diag_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/rst_wrc_n
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/rst_net_n
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/rst_net_resync_ref_n
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/rst_net_resync_ext_n
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/rst_net_resync_dmtd_n
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/rst_net_resync_rxclk_n
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/rst_net_resync_txclk_n
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/s_pps_csync
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/pps_valid
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ppsg_link_ok
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ppsg_wb_in
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ppsg_wb_out
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_rx_clk
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_tx_clk
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/spll_wb_in
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/spll_wb_out
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_txtsu_port_id
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_txtsu_frame_id
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_txtsu_ts_value
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_txtsu_ts_incorrect
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_txtsu_stb
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_txtsu_ack
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_led_link
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/phy_rst
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/mnic_mem_data_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/mnic_mem_addr_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/mnic_mem_wr_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/mnic_txtsu_ack
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/mnic_txtsu_stb
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/dpram_wbb_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/periph_slave_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/periph_slave_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/sysc_in_regs
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/sysc_out_regs
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/secbar_master_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/secbar_master_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/cbar_slave_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/cbar_slave_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/cbar_master_i
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/cbar_master_o
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_wb_in
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ext_wb_out
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/hpll_auxout
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/dmpll_auxout
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_ref_slv
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_rx_slv
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/s_dummy_addr
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/softpll_irq
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/lm32_irq_slv
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_wb_in
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_wb_out
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/minic_wb_in
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/minic_wb_out
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_src_out
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_src_in
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_snk_out
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/ep_snk_in
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/mux_src_out
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/mux_src_in
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/mux_snk_out
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/mux_snk_in
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/mux_class
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/spll_out_locked
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/dac_dpll_data
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/dac_dpll_sel
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/dac_dpll_load_p1
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/clk_fb
add wave -noupdate /main/DUT/inst_spec_base/gen_wr/cmp_xwrc_board_spec/cmp_board_common/cmp_xwr_core/WRPC/out_enable
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {25805352090 fs} 0}
configure wave -namecolwidth 339
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
WaveRestoreZoom {24701267760 fs} {27643595600 fs}
