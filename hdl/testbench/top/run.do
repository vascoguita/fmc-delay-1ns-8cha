make

vsim -L XilinxCoreLib work.main -voptargs="+acc"
radix -hexadecimal
do wave.do

run 1us
wave zoomfull