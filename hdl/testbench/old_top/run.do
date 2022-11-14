# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

#make

vsim -L XilinxCoreLib work.main -voptargs="+acc"
set StdArithNoWarnings 1
set NumericStdNoWarnings 1

radix -hexadecimal
do wave.do

run 100us
wave zoomfull