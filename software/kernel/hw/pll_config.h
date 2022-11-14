// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef __PLL_CONFIG_H__
#define __PLL_CONFIG_H__

struct ad9516_reg {
	int reg;
	int val;
};

extern const struct ad9516_reg __9516_regs[];
extern const unsigned int __9516_regs_n;

#endif
