#make

vsim -L XilinxCoreLib work.main -voptargs="+acc"
set StdArithNoWarnings 1
set NumericStdNoWarnings 1

radix -hexadecimal
do wave.do

run 100us
wave zoomfull