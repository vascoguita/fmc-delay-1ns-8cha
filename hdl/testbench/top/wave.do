onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/U_Acam_TSU/csync_utc_i
add wave -noupdate /main/DUT/U_Acam_TSU/csync_p1_i
add wave -noupdate /main/DUT/U_Acam_TSU/dbg_utc
add wave -noupdate /main/DUT/U_Acam_TSU/dbg_coarse
add wave -noupdate /main/time_counter/wr_utc_o
add wave -noupdate /main/time_counter/wr_coarse_o
add wave -noupdate /main/time_counter/wr_time_valid_o
add wave -noupdate /main/IDEAL_TSU/csync_p1_i
add wave -noupdate /main/IDEAL_TSU/cntr_utc
add wave -noupdate /main/IDEAL_TSU/cntr_coarse
add wave -noupdate /main/IDEAL_TSU/cntr_frac
add wave -noupdate /main/IDEAL_TSU/enable_i
add wave -noupdate /main/DUT/tag_frac
add wave -noupdate /main/DUT/tag_coarse
add wave -noupdate /main/DUT/tag_utc
add wave -noupdate /main/DUT/tag_valid
add wave -noupdate /main/DUT/U_Acam_TSU/acam_stop_dis_o
add wave -noupdate /main/DUT/U_Acam_TSU/tag_enable
add wave -noupdate /main/DUT/U_Acam_TSU/trig_a_n_i
add wave -noupdate /main/DUT/U_Acam_TSU/raw_tag_valid
add wave -noupdate /main/DUT/U_Acam_TSU/raw_tag_coarse
add wave -noupdate /main/DUT/U_Acam_TSU/raw_tag_frac
add wave -noupdate /main/DUT/U_Acam_TSU/raw_tag_start_offset
add wave -noupdate /main/DUT/U_Acam_TSU/raw_tag_utc
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2588000010 fs} 0}
configure wave -namecolwidth 413
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
WaveRestoreZoom {3002500 ps} {4052500 ps}
