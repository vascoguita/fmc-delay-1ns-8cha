======
Driver
======

Driver Features
===============

This driver is based on *zio* and *fmc-bus*.  It supports initial
setup of the board, setting and reading time, run-time continuous
calibration, input timestamping, output pulse generation and readback of
output settings from the hardware.  It supports user-defined offsets,
so our users can tell the driver about channel-specific delays (for
example, to account for wiring) and ignore the issue in application code.

For each feature offered the driver (and documentation) the driver
tries to offer
the following items; sometimes however one of them is missing for a specific
driver functionality, if we don't consider it important enough.


* A description of how the features works at low level;

* A low-level user-space program to test the actual mechanism;

* A C-language API to access the feature with data structures;

* An example program based on that API.

.. _drv_param:

Module Parameters
=================
The driver accepts a few load-time parameters for configuration. You
can pass them to *insmod* amd *modprobe* directly, or write them
in ``/etc/modules.conf`` or the proper file in ``/etc/modutils/``.

The following parameters are used:

verbose=
    The parameter defaults to 0. If set, it enables more diagnostic
    messages during probe (you may find it is not used, but it is
    left in to be useful during further development, and avoid
    compile-time changes like use of ``DEBUG``).

timer_ms=
    The period of the internal timer, if not zero.
    The timer is used to poll for input events instead of enabling
    the interrupt.  The default interval is 0, which means to
    use interrupt support. You may want to use the timer while
    porting to a different carrier, before sorting out IRQ issues.

calib_s=
    The period, in seconds, of temperature measurement to re-calibrate
    the output delays. Defaults to 30. If set to zero, the
    re-calibration timer is not activated.


The module also uses the two parameters provided by the *fmc*
framework:

busid=
    A list of bus identifiers the driver will accept to driver.
    Other identifiers will lead to a failure in the *probe*
    function. The meaning of the identifiers is carrier-specific;
    the SPEC uses the bus number and *devfn*, where the latter
    is most likely zero.

gateware=
    A list of gateware file names. The names passed are made to
    match the *busid* parameters, in the same order. This
    means that you can't make the driver load a different gateware
    file without passing the respective *busid*. Actually, to
    change the gateware for all boards, you may just replace
    the file in ``/lib/firmware``. (Maybe I'll add an
    option to change the name at load time for all boards).

For example, this host has two SPEC cards:::

   spusa.root# lspci | grep CERN
   02:00.0 Non-VGA unclassified device: CERN/ECP/EDU Device 018d (rev 03)
   04:00.0 Non-VGA unclassified device: CERN/ECP/EDU Device 018d (rev 03)


One of the cards hosts a *fine-delay* mezzanine and the other does
not. FMC identifiers are not yet used by this driver at this point in time.
(They will be there in  the next release: code is there but not finalized).
So, here you can use ``busid=`` to choose which SPEC must use *fine-delay*,
leaving the other one alone:::

    spusa.root# insmod fmc-fine-delay.ko busid=0x0200
    [ 4603.994936] spec 0000:02:00.0: Driver has no ID: matches all
    [ 4604.000624] spec 0000:02:00.0: reprogramming with fmc/fine-delay.bin
    [ 4604.206515] spec 0000:02:00.0: FPGA programming successful
    [ 4604.212442] spec 0000:02:00.0: Gateware successfully loaded
    [ 4604.218037] spec 0000:02:00.0: fd_regs_base is 80000
    [ 4604.223023] spec 0000:02:00.0: fmc_fine_delay: initializing
    [ 4604.228624] spec 0000:02:00.0: calibration: version 3, date 20130427
    [ 4605.691404] fd_read_temp: Scratchpad: 9f:04:4b:46:7f:ff:01:10:89
    [ 4605.697615] fd_read_temp: Temperature 0x49f (12 bits: 73.937)
    [ 4606.645545] fd_calibrate_outputs: ch1: 8ns @@859 (f 827, off 32, t 71.00)
    [ 4606.815228] fd_calibrate_outputs: ch2: 8ns @@867 (f 827, off 40, t 71.00)
    [ 4607.001027] fd_calibrate_outputs: ch3: 8ns @@854 (f 827, off 27, t 71.00)
    [ 4607.187007] fd_calibrate_outputs: ch4: 8ns @@859 (f 827, off 32, t 71.00)
    [ 4607.356103] fmc_fine_delay: Found i2c device at 0x50
    [ 4607.364039] spec 0000:02:00.0: Using interrupts for input
    [ 4607.369549] spec 0000:04:00.0: Driver has no ID: matches all
    [ 4607.375243] spec 0000:04:00.0: not using "fmc_fine_delay" according to modparam

If you use ``show_sdb=1``, you'll get the following dump of the
internal SDB structure to ``printk``. The *Self Describing Bus* data
structure is described in the documentation of the
*fpga-config-space* project, under http://ohwr.org.::

    SDB: 00000651:e6a542c9 WB4-Crossbar-GSI   
    SDB: 0000ce42:f19ede1a Fine-Delay-Core     (00010000-000107ff)
    SDB: 0000ce42:f19ede1a Fine-Delay-Core     (00020000-000207ff)
    SDB: 0000ce42:00000013 WB-VIC-Int.Control  (00030000-000300ff)
    SDB: 00000651:eef0b198 WB4-Bridge-GSI      (bridge: 00040000)
    SDB:    00000651:e6a542c9 WB4-Crossbar-GSI   
    SDB:    0000ce42:66cfeb52 WB4-BlockRAM        (00040000-00055fff)
    SDB:    00000651:eef0b198 WB4-Bridge-GSI      (bridge: 00060000)
    SDB:       00000651:e6a542c9 WB4-Crossbar-GSI   
    SDB:       0000ce42:ab28633a WR-Mini-NIC         (00060000-000600ff)
    SDB:       0000ce42:650c2d4f WR-Endpoint         (00060100-000601ff)
    SDB:       0000ce42:65158dc0 WR-Soft-PLL         (00060200-000602ff)
    SDB:       0000ce42:de0d8ced WR-PPS-Generator    (00060300-000603ff)
    SDB:       0000ce42:ff07fc47 WR-Periph-Syscon    (00060400-000604ff)
    SDB:       0000ce42:e2d13d04 WR-Periph-UART      (00060500-000605ff)
    SDB:       0000ce42:779c5443 WR-Periph-1Wire     (00060600-000606ff)
    SDB:       0000ce42:779c5445 WR-Periph-AuxWB     (00060700-000607ff)
    SDB: Bitstream 'svec-fine-delay' synthesized 20140317 by twlostow \
                  (ISE version 133), commit e95b10c776f5f7603f49fcf1330e0c07
    SDB: Synthesis repository: git://ohwr.org/fmc-projects/fmc-delay-1ns-8cha.git

The module also supports some more parameters that are
calibration-specific. They are described in the :ref:`Calibration<dev_cal>`
section.
