# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/chx_delay_pulse0
add wave -noupdate /main/DUT/chx_delay_pulse1
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {64524193550 fs} 0}
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
WaveRestoreZoom {0 fs} {840 us}
