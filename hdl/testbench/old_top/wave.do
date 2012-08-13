onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/g_with_internal_timebase
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/g_clk_sys_freq
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/g_counter_bits
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/clk_sys_i
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/clk_in_i
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/rst_n_i
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/pps_p1_i
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/freq_o
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/freq_valid_o
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/gate_pulse
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/gate_pulse_synced
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/cntr_gate
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/cntr_meas
add wave -noupdate /main/DUT/U_VCXO_Freq_Meter/freq_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {8145325200 fs} 0}
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
WaveRestoreZoom {0 fs} {26250 ns}
