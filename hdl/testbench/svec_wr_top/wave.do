onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/cnx_master_out
add wave -noupdate /main/DUT/cnx_master_in
add wave -noupdate /main/DUT/cnx_slave_out
add wave -noupdate /main/DUT/cnx_slave_in
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {53004000000 fs} 0}
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
