onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /main/DUT/u_acam_tsu/clk_ref_i
add wave -noupdate -format Logic /main/DUT/u_acam_tsu/tdc_start_i
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/start_gen_state
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/start_count
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/coarse_count
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/coarse_offset
add wave -noupdate -format Logic /main/acam_start_dis
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/start_ok_sreg
add wave -noupdate -format Logic /main/DUT/u_acam_tsu/start_ok
add wave -noupdate -format Logic /main/DUT/u_acam_tsu/acam_stop_dis_o
add wave -noupdate -format Logic /main/DUT/u_acam_tsu/acam_start_dis_o
add wave -noupdate -format Logic /main/ACAM/r_StartDisStart
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/acam_wdata
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/regs_b
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/post_frac_start_adj
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/raw_tag_frac
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/tag_raw_frac_o
add wave -noupdate -format Literal /main/DUT/u_acam_tsu/tag_frac_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {634263960 fs} 0}
configure wave -namecolwidth 413
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {20196598990 fs} {21042284270 fs}
