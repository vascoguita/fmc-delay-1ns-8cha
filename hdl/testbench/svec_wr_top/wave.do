onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group VME /main/rst_n
add wave -noupdate -group VME /main/clk_125m
add wave -noupdate -group VME /main/clk_20m
add wave -noupdate -group VME /main/VME_AS_n
add wave -noupdate -group VME /main/VME_RST_n
add wave -noupdate -group VME /main/VME_WRITE_n
add wave -noupdate -group VME /main/VME_AM
add wave -noupdate -group VME /main/VME_DS_n
add wave -noupdate -group VME /main/VME_BERR
add wave -noupdate -group VME /main/VME_DTACK_n
add wave -noupdate -group VME /main/VME_RETRY_n
add wave -noupdate -group VME /main/VME_RETRY_OE
add wave -noupdate -group VME /main/VME_LWORD_n
add wave -noupdate -group VME /main/VME_ADDR
add wave -noupdate -group VME /main/VME_DATA
add wave -noupdate -group VME /main/VME_BBSY_n
add wave -noupdate -group VME /main/VME_IRQ_n
add wave -noupdate -group VME /main/VME_IACKIN_n
add wave -noupdate -group VME /main/VME_IACK_n
add wave -noupdate -group VME /main/VME_IACKOUT_n
add wave -noupdate -group VME /main/VME_DTACK_OE
add wave -noupdate -group VME /main/VME_DATA_DIR
add wave -noupdate -group VME /main/VME_DATA_OE_N
add wave -noupdate -group VME /main/VME_ADDR_DIR
add wave -noupdate -group VME /main/VME_ADDR_OE_N
add wave -noupdate -group VME /main/trig0
add wave -noupdate -group VME /main/trig1
add wave -noupdate -group VME /main/out0
add wave -noupdate -group VME /main/out1
add wave -noupdate -group VME /main/pulse_enable
add wave -noupdate -group VME /main/out0_delayed
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/BUSY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT2
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DOUT
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/TOUT
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/CAL
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/CE
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/CLK
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IDATAIN
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/INC
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK0
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/ODATAIN
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/RST
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/T
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/COUNTER_WRAPAROUND_BINARY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DATA_RATE_BINARY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DELAY_SRC_BINARY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY2_VALUE_BINARY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY_MODE_BINARY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY_TYPE_BINARY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY_VALUE_BINARY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/ODELAY_VALUE_BINARY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/SERDES_MODE_BINARY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/SIM_TAPDELAY_VALUE_BINARY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/Tstep
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/COUNTER_WRAPAROUND_PAD
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DELAY_SRC_PAD
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY_MODE_PAD
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IDELAY_TYPE_PAD
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/SERDES_MODE_PAD
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/GSR_INDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/rst_sig
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/ce_sig
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/inc_sig
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/cal_sig
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_out_sig
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_out
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_out
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_out_dly
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/tout_out_int
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_int
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_pe_one_shot
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_ne_one_shot
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_dly
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_pe_dly
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_pe_dly1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_ne_dly
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/busy_out_ne_dly1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/sdo_out_int
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/ioclk0_int
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/ioclk1_int
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/ioclk_int
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/first_edge
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/sat_at_max_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/rst_to_half_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/ignore_rst
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/force_rx_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/force_dly_dir_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/output_delay_off
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/input_delay_off
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/isslave
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/encasc
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/counter_wraparound_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/data_rate_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/serdes_mode_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/odelay_value_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_value_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/sim_tap_delay_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_type_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_mode_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay_src_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay2_value_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/attr_err_flag
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/cal_count
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/cal_delay
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/max_delay
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/half_max
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_pe_1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_ne_1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_pe_clk
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_ne_clk
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/first_time_pe
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/first_time_ne
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_pe_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_pe_m_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_pe_s_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_pe_m_reg1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_pe_s_reg1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_ne_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_ne_m_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_ne_s_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_ne_m_reg1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/idelay_val_ne_s_reg1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_reached
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_reached_1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_reached_2
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_working
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_working_1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_working_2
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_ignore
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_pe_2
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay_val_ne_2
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/odelay_val_pe_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/odelay_val_ne_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_reached
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_reached_1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_reached_2
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_working
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_working_1
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_working_2
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_ignore
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay1_in
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/delay2_in
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/calibrate
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/calibrate_done
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/sync_to_data_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/pci_ce_reg
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/BUSY_OUT
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT2_OUT
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT_OUT
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DOUT_OUT
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/TOUT_OUT
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/BUSY_OUTDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT2_OUTDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DATAOUT_OUTDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/DOUT_OUTDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/TOUT_OUTDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/CAL_ipd
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/CE_ipd
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/CLK_ipd
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IDATAIN_ipd
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/INC_ipd
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK0_ipd
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK1_ipd
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/ODATAIN_ipd
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/RST_ipd
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/T_ipd
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/CAL_INDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/CE_INDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/CLK_INDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IDATAIN_INDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/INC_INDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK0_INDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/IOCLK1_INDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/ODATAIN_INDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/RST_INDELAY
add wave -noupdate -expand -group Delay0 /main/DUT/cmp_fd_tdc_start_delay0/T_INDELAY
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {9101898590 fs} 0}
configure wave -namecolwidth 183
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
WaveRestoreZoom {0 fs} {226247193600 fs}
