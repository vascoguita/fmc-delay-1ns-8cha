onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/vme_master_in
add wave -noupdate /main/DUT/vme_master_out
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/c_dl
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/c_al
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/c_sell
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/c_psizel
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/clk_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/reset_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/transfer_done_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_dat_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_dat_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_adr_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_cyc_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_err_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_lock_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_rty_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_sel_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_stb_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_ack_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_we_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_stall_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/sl_psize_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_dat_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_dat_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_adr_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_cyc_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_err_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_lock_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_rty_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_sel_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_stb_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_ack_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_we_o
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/m_stall_i
add wave -noupdate /main/DUT/U_VME_Core/U_Wrapped_VME/Uwb_dma/ack_latched
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {39417979 ps} 0}
configure wave -namecolwidth 177
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
WaveRestoreZoom {38951687 ps} {40055175 ps}
