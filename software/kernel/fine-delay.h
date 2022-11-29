// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef __FINE_DELAY_H__
#define __FINE_DELAY_H__

enum fd_versions {
	FD_VER_TDC = 0,
};

enum fd_mem_resource {
	FD_MEM_BASE = 0,
};

enum fd_bus_resource {
	FD_BUS_FMC_SLOT = 0,
};

enum fd_irq_resource {
	FD_IRQ = 0,
};

#define FDELAY_VERSION_MAJ	2 /* version of the layout of registers */

/*
 * ZIO concatenates device, cset and channel extended attributes in the 32
 * values that are reported in the control block. So we are limited to
 * 32 values at most, and the offset of cset attributes depends on the
 * number of device attributes. For this reason, we reserve a few, in
 * order not to increase the version number too often (we need to increase
 * it when the layout of attributes changes in incompatible ways)
 */

/*
 * NOTE: all tuples of 4 register must be enumerated in the proper order:
 * utc-h, utc-l, coarse, frac  __IN_THIS_ORDER__ because I make arith on them
 */

/* Device-wide ZIO attributes */
enum fd_zattr_dev_idx {
	FD_ATTR_DEV_VERSION = 0,
	FD_ATTR_DEV_UTC_H,
	FD_ATTR_DEV_UTC_L,
	FD_ATTR_DEV_COARSE,
	FD_ATTR_DEV_COMMAND, /* see below for commands */
	FD_ATTR_DEV_TEMP,
	FD_ATTR_DEV_RESERVE_6,
	FD_ATTR_DEV_RESERVE_7,
	FD_ATTR_DEV__LAST,
};

enum fd_command {
	FD_CMD_HOST_TIME = 0,
	FD_CMD_WR_ENABLE,
	FD_CMD_WR_DISABLE,
	FD_CMD_WR_QUERY,
	FD_CMD_DUMP_MCP,
	FD_CMD_PURGE_FIFO = 5,
};


/* Input ZIO attributes (i.e. TDC attributes) */
enum fd_zattr_in_idx {
	/* PLEASE check "NOTE:" above if you edit this*/
	FD_ATTR_TDC_UTC_H = FD_ATTR_DEV__LAST,
	FD_ATTR_TDC_UTC_L,
	FD_ATTR_TDC_COARSE,
	FD_ATTR_TDC_FRAC,
	FD_ATTR_TDC_SEQ,
	FD_ATTR_TDC_CHAN,
	FD_ATTR_TDC_FLAGS, /* enable, termination, see below */
	FD_ATTR_TDC_OFFSET,
	FD_ATTR_TDC_USER_OFF,
	FD_ATTR_TDC__LAST,
};
/* Names have been chosen so that 0 is the default at load time */

/**
 * TDC flag to disable input pulse detection
 * When disabled time-stamping and delay are impossible
 */
#define FD_TDCF_DISABLE_INPUT	1

/**
 * TDC flag to disable input pulse time-stamping
 * When disabled time-stamping are impossible, but delay will work
 */
#define FD_TDCF_DISABLE_TSTAMP	2

/**
 * TDC flag to enable a 50Ohm termination
 */
#define FD_TDCF_TERM_50		4

/* Output ZIO attributes */
enum fd_zattr_out_idx {
	FD_ATTR_OUT_MODE = FD_ATTR_DEV__LAST,
	FD_ATTR_OUT_REP,
	/* PLEASE check "NOTE:" above if you edit this*/
	/* Start (or delay) is 4 registers */
	FD_ATTR_OUT_START_H,
	FD_ATTR_OUT_START_L,
	FD_ATTR_OUT_START_COARSE,
	FD_ATTR_OUT_START_FINE,
	/* End (start + width) is 4 registers */
	FD_ATTR_OUT_END_H,
	FD_ATTR_OUT_END_L,
	FD_ATTR_OUT_END_COARSE,
	FD_ATTR_OUT_END_FINE,
	/* Delta is 3 registers */
	FD_ATTR_OUT_DELTA_L,
	FD_ATTR_OUT_DELTA_COARSE,
	FD_ATTR_OUT_DELTA_FINE,
	/* The two offsets */
	FD_ATTR_OUT_DELAY_OFF,
	FD_ATTR_OUT_USER_OFF,
	FD_ATTR_OUT__LAST,
};
enum fd_output_mode {
	FD_OUT_MODE_DISABLED = 0,
	FD_OUT_MODE_DELAY,
	FD_OUT_MODE_PULSE,
};

/*
 * Cset attributes are concatenated to device attributes in the control
 * structure, but they start from 0 when allocate for the individual cset
 */
#define FD_CSET_INDEX(i) ((i) - FD_ATTR_DEV__LAST)

/*
 * Internal time: the first three fields should be converted to zio time.
 * This is exported to user space if raw_tdc is selected.
 */
struct fd_time {
	uint64_t utc;
	uint32_t coarse;
	uint32_t frac;
	uint32_t channel;
	uint32_t seq_id;
};


struct fd_calibration { /* All of these are big endian */
	uint32_t magic;			/* magic ID: 0xf19ede1a */
	uint32_t hash;			/* jhash of it all, with this zeroed */
	uint16_t size;
	uint16_t version;
	uint32_t date;			/* hex: 0x20130410 = Apr 4th 2013 */

	/* SY89295 delay/temperature polynomial coefficients */
	int64_t frr_poly[3];

	/* Output-to-internal-timebase offset in ps. Add to start/end output */
	int32_t zero_offset[4];

	/* TDC-to-internal-timebase offset in ps. Add to stamps and delays */
	int32_t tdc_zero_offset;

	/* Default DAC value for VCXO. Set during init and for local timing */
	uint32_t vcxo_default_tune;
};

#ifdef __KERNEL__ /* All the rest is only of kernel users */
#include <linux/spinlock.h>
#include <linux/timer.h>
#include <linux/platform_device.h>
#include <linux/version.h>
#include <linux/interrupt.h>
#include <linux/fmc.h>
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
#include <linux/math64.h>
#else
/* Hack to compile under 2.6.24: this comes from 2418f4f2 (Roman Zippel) */
static inline u64 div_u64_rem(u64 dividend, u32 divisor, u32 *remainder)
{
	*remainder = do_div(dividend, divisor);
	return dividend;
}
#endif

struct memory_ops {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5,8,0)
	u32 (*read)(void *addr);
#else
	u32 (*read)(const void *addr);
#endif
	void (*write)(u32 value, void *addr);
};


/* This is somehow generic, but I find no better place at this time */
#ifndef SET_HI32
#  if BITS_PER_LONG > 32
#    define SET_HI32(var, value)        ((var) |= (value) << 32)
#    define GET_HI32(var)               ((var) >> 32)
#  else
#    define SET_HI32(var, value)        ((var) |= 0)
#    define GET_HI32(var)               0
#  endif
#endif

/* Channels are called 1..4 in all docs. Internally it's 0..3 */
#define FD_CH_1		0
#define FD_CH_LAST	3
#define FD_CH_NUMBER	4
#define FD_CH_INT(i)	((i) - 1)
#define FD_CH_EXT(i)	((i) + 1)

#define FD_NUM_TAPS	1024	/* This is an hardware feature of SY89295U */
#define FD_CAL_STEPS	1024	/* This is a parameter: must be power of 2 */
#define FD_SW_FIFO_LEN	1024	/* Again, aa parameter: must be a power of 2 */

struct fd_ch {
	/* Offset between FRR measured at known T at startup and poly-fitted */
	uint32_t frr_offset;
	/* Fine range register for each ch, current value (after T comp.) */
	uint32_t frr_cur;
};

/* The software fifo is a circular buffer of fd_time structures */
struct fd_sw_fifo {
	unsigned long head, tail;
	struct fd_time *t;
};

/* This is the device we use all around */
struct fd_dev {
	spinlock_t lock;
	unsigned long flags;
	void *fd_regs_base;
	void *fd_owregs_base;		/* regs_base + 0x500 */
	struct memory_ops memops;
	struct platform_device *pdev;
	struct zio_device *zdev, *hwzdev;
	struct timer_list fifo_timer;
	struct timer_list temp_timer;
	struct tasklet_struct tlet;
	struct fd_calibration calib;	/* a copy of what we have in flash */
	struct fd_ch ch[FD_CH_NUMBER];
	struct fmc_slot *slot;
	uint32_t bin;
	int acam_addr;			/* cache of currently active addr */
	uint8_t ds18_id[8];
	unsigned long next_t;
	int temp;			/* temperature: scaled by 4 bits */
	int temp_ready;			/* temperature: measurement ready flag */
	int verbose;
	uint32_t tdc_attrs[FD_ATTR_TDC__LAST - FD_ATTR_DEV__LAST];
	uint16_t mcp_iodir, mcp_olat;
	struct fd_sw_fifo sw_fifo;

	/* The following fields used to live in fd_calib */
	int32_t tdc_user_offset;
	int32_t ch_user_offset[4];
	int32_t tdc_flags;

	struct dentry *dbg_dir;
	struct dentry *dbg_reg_spi_pll;
};

/* We act on flags using atomic ops, so flag is the number, not the mask */
enum fd_flags {
	FD_FLAG_INITED = 0,
	FD_FLAG_DO_INPUT,
	FD_FLAG_INPUT_READY,
	FD_FLAG_WR_MODE,
};

/* Split a pico value into coarse and frac */
static inline void fd_split_pico(uint64_t pico,
				 uint32_t *coarse, uint32_t *frac)
{
	/* This works for less than 1s delays */
	BUG_ON(pico > 1000ULL * NSEC_PER_SEC);
	*coarse = div_u64_rem(pico, 8000, frac);
	*frac = (*frac << 12) / 8000;
}

static inline u32 fd_ioread(struct fd_dev *fd, void *addr)
{
	return fd->memops.read(addr);
}

static inline void fd_iowrite(struct fd_dev *fd,
			      u32 value, void *addr)
{
	fd->memops.write(value, addr);
}

static inline uint32_t fd_readl(struct fd_dev *fd, unsigned long reg)
{
	return fd_ioread(fd, (char *)fd->fd_regs_base + reg);
}
static inline void fd_writel(struct fd_dev *fd, uint32_t v, unsigned long reg)
{
	fd_iowrite(fd, v, (char *)fd->fd_regs_base + reg);
}

static inline void __check_chan(int x)
{
	BUG_ON(x < 0 || x > 3);
}


static inline uint32_t fd_ch_readl(struct fd_dev *fd, int ch,
				   unsigned long reg)
{
	__check_chan(ch);
	return fd_readl(fd, 0x100 + ch * 0x100 + reg);
}

static inline void fd_ch_writel(struct fd_dev *fd, int ch,
				uint32_t v, unsigned long reg)
{
	__check_chan(ch);
	fd_writel(fd, v, 0x100 + ch * 0x100 + reg);
}

#define FD_MAGIC_FPGA	0xf19ede1a	/* FD_REG_IDR content */

/* Values for the configuration of the acam PLL. Can be changed */
#define ACAM_DESIRED_BIN	80.9553
#define ACAM_CLOCK_FREQ_KHZ	31250

/* ACAM TDC operation modes */
enum fd_acam_modes {
	ACAM_RMODE,
	ACAM_IMODE,
	ACAM_GMODE
};

/*
 * You can change the following value to have a pll with smaller divisor,
 * at the cost of potentially less precision in the desired bin value.
 */
#define ACAM_MAX_REFDIV		7

#define ACAM_MASK		((1<<29) - 1) /* 28 bits */

/* SPI Bus chip selects */
#define FD_CS_DAC	0	/* DAC for VCXO */
#define FD_CS_PLL	1	/* AD9516 PLL */
#define FD_CS_GPIO	2	/* MCP23S17 GPIO */

/* MCP23S17 register addresses (only ones which are used by the lib) */
#define FD_MCP_IODIR	0x00
#define FD_MCP_IPOL	0x01
#define FD_MCP_IOCON	0x0a
#define FD_MCP_GPIO	0x12
#define FD_MCP_OLAT	0x14

/*
 * MCP23S17 GPIO direction and meaning
 * NOTE: outputs are called 1..4 to match hw schematics
 */
#define FD_GPIO_IN	0
#define FD_GPIO_OUT	1

static inline void __check_output(int x)
{
	BUG_ON(x < 1 || x > 4);
}

#define FD_GPIO_TERM_EN		0x0001		/* Input terminator enable */
#define FD_GPIO_OUTPUT_EN(x)	\
	({__check_output(x); 1 << (6-(x));})	/* Output driver enable */
#define FD_GPIO_OUTPUT_MASK	0x003c		/* Output driver enable */
#define FD_GPIO_TRIG_INTERNAL	0x0040		/* TDC trig (1=in, 1=fpga) */
#define FD_GPIO_CAL_DISABLE	0x0080		/* 0 enables calibration */

/* Functions exported by spi.c */
extern int fd_spi_xfer(struct fd_dev *fd, int ss, int num_bits,
		       uint32_t in, uint32_t *out);
extern int fd_spi_init(struct fd_dev *fd);
extern void fd_spi_exit(struct fd_dev *fd);

/* Functions exported by pll.c */
extern int fd_pll_init(struct fd_dev *fd);
extern void fd_pll_exit(struct fd_dev *fd);

/* Functions exported by onewire.c */
extern int fd_onewire_init(struct fd_dev *fd);
extern void fd_onewire_exit(struct fd_dev *fd);
extern int fd_read_temp(struct fd_dev *fd, int verbose);

/* Functions exported by acam.c */
extern int fd_acam_init(struct fd_dev *fd);
extern void fd_acam_exit(struct fd_dev *fd);
extern uint32_t acam_readl(struct fd_dev *fd, int reg);
extern void acam_writel(struct fd_dev *fd, int val, int reg);

/* Functions exported by calibrate.c, called within acam.c */
extern int fd_calibrate_outputs(struct fd_dev *fd);

#if LINUX_VERSION_CODE < KERNEL_VERSION(4,14,0)
extern void fd_update_calibration(unsigned long arg);
#else
extern void fd_update_calibration(struct timer_list *arg);
#endif

extern int fd_calib_period_s;

/* Functions exported by gpio.c */
extern int fd_gpio_init(struct fd_dev *fd);
extern void fd_gpio_exit(struct fd_dev *fd);
extern void fd_gpio_dir(struct fd_dev *fd, int pin, int dir);
extern void fd_gpio_val(struct fd_dev *fd, int pin, int val);
extern void fd_gpio_set_clr(struct fd_dev *fd, int pin, int set);
extern int fd_dump_mcp(struct fd_dev *fd);
#define fd_gpio_set(fd, pin) fd_gpio_set_clr((fd), (pin), 1)
#define fd_gpio_clr(fd, pin) fd_gpio_set_clr((fd), (pin), 0)

/* Functions exported by time.c */
extern int fd_time_init(struct fd_dev *fd);
extern void fd_time_exit(struct fd_dev *fd);
#if LINUX_VERSION_CODE < KERNEL_VERSION(5,6,0)
extern int fd_time_set(struct fd_dev *fd, struct fd_time *t,
		       struct timespec *ts);
extern int fd_time_get(struct fd_dev *fd, struct fd_time *t,
		       struct timespec *ts);
#else
extern int fd_time_set(struct fd_dev *fd, struct fd_time *t,
		       struct timespec64 *ts);
extern int fd_time_get(struct fd_dev *fd, struct fd_time *t,
		       struct timespec64 *ts);
#endif

/* Functions exported by fd-zio.c */
extern int fd_zio_register(void);
extern void fd_zio_unregister(void);
extern int fd_zio_init(struct fd_dev *fd);
extern void fd_zio_exit(struct fd_dev *fd);
extern void fd_apply_offset(uint32_t *a, int32_t off_pico);

/* Functions exported by fd-irq.c */
struct zio_channel;
extern int fd_read_sw_fifo(struct fd_dev *fd, struct zio_channel *chan);
extern int fd_irq_init(struct fd_dev *fd);
extern void fd_irq_exit(struct fd_dev *fd);

/* Functions exported by fd-spec.c */
extern int fd_spec_init(void);
extern void fd_spec_exit(void);

/* Function exported by calibration.c */
extern int fd_calib_init(struct fd_dev *fd);
extern void fd_calib_exit(struct fd_dev *fd);
extern struct bin_attribute dev_attr_calibration;

extern int fd_debug_init(struct fd_dev *fd);
extern void fd_debug_exit(struct fd_dev *fd);
#endif /* __KERNEL__ */
#endif /* __FINE_DELAY_H__ */
