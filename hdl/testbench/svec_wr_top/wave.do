onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/U_VME_Core/master_o
add wave -noupdate /main/DUT/U_VME_Core/master_i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {23693000000 fs} 0}
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
WaveRestoreZoom {49151514620 fs} {59369721340 fs}
