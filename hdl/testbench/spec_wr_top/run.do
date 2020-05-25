#vlog -sv main.sv +incdir+"." +incdir+gn4124_bfm +incdir+../../include/wb +incdir+../../include
#make -f Makefile
vsim -L unisim -L secureip work.main -voptargs="+acc" -t 10fs -novopt 
 set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave.do
radix -hexadecimal
run 200us
wave zoomfull
radix -hexadecimal
