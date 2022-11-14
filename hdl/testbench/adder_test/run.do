# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

make

vsim -L XilinxCoreLib work.main -voptargs="+acc"
radix -hexadecimal
do wave.do

run 1us
wave zoomfull