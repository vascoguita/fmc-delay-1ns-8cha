#ifndef __OPENCORES_SPI_H
#define __OPENCORES_SPI_H

#include <stdint.h>

#define OCSPI_REG_RX0 0
#define OCSPI_REG_RX1 4
#define OCSPI_REG_RX2 8
#define OCSPI_REG_RX3 12
#define OCSPI_REG_TX0 0
#define OCSPI_REG_TX1 4
#define OCSPI_REG_TX2 8
#define OCSPI_REG_TX3 12

#define OCSPI_REG_CTRL 16
#define OCSPI_REG_DIVIDER 20
#define OCSPI_REG_SS 24

#define OCSPI_CTRL_ASS (1<<13)
#define OCSPI_CTRL_IE (1<<12)
#define OCSPI_CTRL_LSB (1<<11)
#define OCSPI_CTRL_TXNEG (1<<10)
#define OCSPI_CTRL_RXNEG (1<<9)
#define OCSPI_CTRL_GO_BSY (1<<8)
#define OCSPI_CTRL_CHAR_LEN(x) ((x) & 0x7f)

#endif
