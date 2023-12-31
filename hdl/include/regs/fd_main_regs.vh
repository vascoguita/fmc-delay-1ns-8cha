// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: CERN-OHL-W-2.0+

`define ADDR_FD_RSTR                   8'h0
`define FD_RSTR_RST_FMC_OFFSET 0
`define FD_RSTR_RST_FMC 32'h00000001
`define FD_RSTR_RST_CORE_OFFSET 1
`define FD_RSTR_RST_CORE 32'h00000002
`define FD_RSTR_LOCK_OFFSET 16
`define FD_RSTR_LOCK 32'hffff0000
`define ADDR_FD_IDR                    8'h4
`define ADDR_FD_GCR                    8'h8
`define FD_GCR_BYPASS_OFFSET 0
`define FD_GCR_BYPASS 32'h00000001
`define FD_GCR_INPUT_EN_OFFSET 1
`define FD_GCR_INPUT_EN 32'h00000002
`define FD_GCR_DDR_LOCKED_OFFSET 2
`define FD_GCR_DDR_LOCKED 32'h00000004
`define FD_GCR_FMC_PRESENT_OFFSET 3
`define FD_GCR_FMC_PRESENT 32'h00000008
`define ADDR_FD_TCR                    8'hc
`define FD_TCR_DMTD_STAT_OFFSET 0
`define FD_TCR_DMTD_STAT 32'h00000001
`define FD_TCR_WR_ENABLE_OFFSET 1
`define FD_TCR_WR_ENABLE 32'h00000002
`define FD_TCR_WR_LOCKED_OFFSET 2
`define FD_TCR_WR_LOCKED 32'h00000004
`define FD_TCR_WR_PRESENT_OFFSET 3
`define FD_TCR_WR_PRESENT 32'h00000008
`define FD_TCR_WR_READY_OFFSET 4
`define FD_TCR_WR_READY 32'h00000010
`define FD_TCR_WR_LINK_OFFSET 5
`define FD_TCR_WR_LINK 32'h00000020
`define FD_TCR_CAP_TIME_OFFSET 6
`define FD_TCR_CAP_TIME 32'h00000040
`define FD_TCR_SET_TIME_OFFSET 7
`define FD_TCR_SET_TIME 32'h00000080
`define ADDR_FD_TM_SECH                8'h10
`define ADDR_FD_TM_SECL                8'h14
`define ADDR_FD_TM_CYCLES              8'h18
`define ADDR_FD_TDR                    8'h1c
`define ADDR_FD_TDCSR                  8'h20
`define FD_TDCSR_WRITE_OFFSET 0
`define FD_TDCSR_WRITE 32'h00000001
`define FD_TDCSR_READ_OFFSET 1
`define FD_TDCSR_READ 32'h00000002
`define FD_TDCSR_EMPTY_OFFSET 2
`define FD_TDCSR_EMPTY 32'h00000004
`define FD_TDCSR_STOP_EN_OFFSET 3
`define FD_TDCSR_STOP_EN 32'h00000008
`define FD_TDCSR_START_DIS_OFFSET 4
`define FD_TDCSR_START_DIS 32'h00000010
`define FD_TDCSR_START_EN_OFFSET 5
`define FD_TDCSR_START_EN 32'h00000020
`define FD_TDCSR_STOP_DIS_OFFSET 6
`define FD_TDCSR_STOP_DIS 32'h00000040
`define FD_TDCSR_ALUTRIG_OFFSET 7
`define FD_TDCSR_ALUTRIG 32'h00000080
`define FD_TDCSR_IDELAY_CE_OFFSET 8
`define FD_TDCSR_IDELAY_CE 32'h00000100
`define ADDR_FD_CALR                   8'h24
`define FD_CALR_CAL_PULSE_OFFSET 0
`define FD_CALR_CAL_PULSE 32'h00000001
`define FD_CALR_CAL_PPS_OFFSET 1
`define FD_CALR_CAL_PPS 32'h00000002
`define FD_CALR_CAL_DMTD_OFFSET 2
`define FD_CALR_CAL_DMTD 32'h00000004
`define FD_CALR_PSEL_OFFSET 3
`define FD_CALR_PSEL 32'h00000078
`define ADDR_FD_DMTR_IN                8'h28
`define FD_DMTR_IN_TAG_OFFSET 0
`define FD_DMTR_IN_TAG 32'h7fffffff
`define FD_DMTR_IN_RDY_OFFSET 31
`define FD_DMTR_IN_RDY 32'h80000000
`define ADDR_FD_DMTR_OUT               8'h2c
`define FD_DMTR_OUT_TAG_OFFSET 0
`define FD_DMTR_OUT_TAG 32'h7fffffff
`define FD_DMTR_OUT_RDY_OFFSET 31
`define FD_DMTR_OUT_RDY 32'h80000000
`define ADDR_FD_ADSFR                  8'h30
`define ADDR_FD_ATMCR                  8'h34
`define FD_ATMCR_C_THR_OFFSET 0
`define FD_ATMCR_C_THR 32'h000000ff
`define FD_ATMCR_F_THR_OFFSET 8
`define FD_ATMCR_F_THR 32'h7fffff00
`define ADDR_FD_ASOR                   8'h38
`define FD_ASOR_OFFSET_OFFSET 0
`define FD_ASOR_OFFSET 32'h007fffff
`define ADDR_FD_IECRAW                 8'h3c
`define ADDR_FD_IECTAG                 8'h40
`define ADDR_FD_IEPD                   8'h44
`define FD_IEPD_RST_STAT_OFFSET 0
`define FD_IEPD_RST_STAT 32'h00000001
`define FD_IEPD_PDELAY_OFFSET 1
`define FD_IEPD_PDELAY 32'h000001fe
`define ADDR_FD_SCR                    8'h48
`define FD_SCR_DATA_OFFSET 0
`define FD_SCR_DATA 32'h00ffffff
`define FD_SCR_SEL_DAC_OFFSET 24
`define FD_SCR_SEL_DAC 32'h01000000
`define FD_SCR_SEL_PLL_OFFSET 25
`define FD_SCR_SEL_PLL 32'h02000000
`define FD_SCR_SEL_GPIO_OFFSET 26
`define FD_SCR_SEL_GPIO 32'h04000000
`define FD_SCR_READY_OFFSET 27
`define FD_SCR_READY 32'h08000000
`define FD_SCR_CPOL_OFFSET 28
`define FD_SCR_CPOL 32'h10000000
`define FD_SCR_START_OFFSET 29
`define FD_SCR_START 32'h20000000
`define ADDR_FD_RCRR                   8'h4c
`define ADDR_FD_TSBCR                  8'h50
`define FD_TSBCR_CHAN_MASK_OFFSET 0
`define FD_TSBCR_CHAN_MASK 32'h0000001f
`define FD_TSBCR_ENABLE_OFFSET 5
`define FD_TSBCR_ENABLE 32'h00000020
`define FD_TSBCR_PURGE_OFFSET 6
`define FD_TSBCR_PURGE 32'h00000040
`define FD_TSBCR_RST_SEQ_OFFSET 7
`define FD_TSBCR_RST_SEQ 32'h00000080
`define FD_TSBCR_FULL_OFFSET 8
`define FD_TSBCR_FULL 32'h00000100
`define FD_TSBCR_EMPTY_OFFSET 9
`define FD_TSBCR_EMPTY 32'h00000200
`define FD_TSBCR_COUNT_OFFSET 10
`define FD_TSBCR_COUNT 32'h003ffc00
`define FD_TSBCR_RAW_OFFSET 22
`define FD_TSBCR_RAW 32'h00400000
`define ADDR_FD_TSBIR                  8'h54
`define FD_TSBIR_TIMEOUT_OFFSET 0
`define FD_TSBIR_TIMEOUT 32'h000003ff
`define FD_TSBIR_THRESHOLD_OFFSET 10
`define FD_TSBIR_THRESHOLD 32'h003ffc00
`define ADDR_FD_TSBR_SECH              8'h58
`define ADDR_FD_TSBR_SECL              8'h5c
`define ADDR_FD_TSBR_CYCLES            8'h60
`define ADDR_FD_TSBR_FID               8'h64
`define FD_TSBR_FID_CHANNEL_OFFSET 0
`define FD_TSBR_FID_CHANNEL 32'h0000000f
`define FD_TSBR_FID_FINE_OFFSET 4
`define FD_TSBR_FID_FINE 32'h0000fff0
`define FD_TSBR_FID_SEQID_OFFSET 16
`define FD_TSBR_FID_SEQID 32'hffff0000
`define ADDR_FD_I2CR                   8'h68
`define FD_I2CR_SCL_OUT_OFFSET 0
`define FD_I2CR_SCL_OUT 32'h00000001
`define FD_I2CR_SDA_OUT_OFFSET 1
`define FD_I2CR_SDA_OUT 32'h00000002
`define FD_I2CR_SCL_IN_OFFSET 2
`define FD_I2CR_SCL_IN 32'h00000004
`define FD_I2CR_SDA_IN_OFFSET 3
`define FD_I2CR_SDA_IN 32'h00000008
`define ADDR_FD_TDER1                  8'h6c
`define FD_TDER1_VCXO_FREQ_OFFSET 0
`define FD_TDER1_VCXO_FREQ 32'hffffffff
`define ADDR_FD_TDER2                  8'h70
`define FD_TDER2_PELT_DRIVE_OFFSET 0
`define FD_TDER2_PELT_DRIVE 32'hffffffff
`define ADDR_FD_TSBR_DEBUG             8'h74
`define ADDR_FD_TSBR_ADVANCE           8'h78
`define FD_TSBR_ADVANCE_ADV_OFFSET 0
`define FD_TSBR_ADVANCE_ADV 32'h00000001
`define ADDR_FD_FMC_SLOT_ID            8'h7c
`define FD_FMC_SLOT_ID_SLOT_ID_OFFSET 0
`define FD_FMC_SLOT_ID_SLOT_ID 32'h0000000f
`define ADDR_FD_IODELAY_ADJ            8'h80
`define FD_IODELAY_ADJ_N_TAPS_OFFSET 0
`define FD_IODELAY_ADJ_N_TAPS 32'h000000ff
`define ADDR_FD_EIC_IDR                8'ha0
`define FD_EIC_IDR_TS_BUF_NOTEMPTY_OFFSET 0
`define FD_EIC_IDR_TS_BUF_NOTEMPTY 32'h00000001
`define FD_EIC_IDR_DMTD_SPLL_OFFSET 1
`define FD_EIC_IDR_DMTD_SPLL 32'h00000002
`define FD_EIC_IDR_SYNC_STATUS_OFFSET 2
`define FD_EIC_IDR_SYNC_STATUS 32'h00000004
`define ADDR_FD_EIC_IER                8'ha4
`define FD_EIC_IER_TS_BUF_NOTEMPTY_OFFSET 0
`define FD_EIC_IER_TS_BUF_NOTEMPTY 32'h00000001
`define FD_EIC_IER_DMTD_SPLL_OFFSET 1
`define FD_EIC_IER_DMTD_SPLL 32'h00000002
`define FD_EIC_IER_SYNC_STATUS_OFFSET 2
`define FD_EIC_IER_SYNC_STATUS 32'h00000004
`define ADDR_FD_EIC_IMR                8'ha8
`define FD_EIC_IMR_TS_BUF_NOTEMPTY_OFFSET 0
`define FD_EIC_IMR_TS_BUF_NOTEMPTY 32'h00000001
`define FD_EIC_IMR_DMTD_SPLL_OFFSET 1
`define FD_EIC_IMR_DMTD_SPLL 32'h00000002
`define FD_EIC_IMR_SYNC_STATUS_OFFSET 2
`define FD_EIC_IMR_SYNC_STATUS 32'h00000004
`define ADDR_FD_EIC_ISR                8'hac
`define FD_EIC_ISR_TS_BUF_NOTEMPTY_OFFSET 0
`define FD_EIC_ISR_TS_BUF_NOTEMPTY 32'h00000001
`define FD_EIC_ISR_DMTD_SPLL_OFFSET 1
`define FD_EIC_ISR_DMTD_SPLL 32'h00000002
`define FD_EIC_ISR_SYNC_STATUS_OFFSET 2
`define FD_EIC_ISR_SYNC_STATUS 32'h00000004
