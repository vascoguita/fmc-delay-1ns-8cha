==========================
Information for Developers
==========================

This appendix contains some extra information on the internals of the driver
and how to access it bypassing the library. If you are not a *fine-delay*,
*fmc-bus* or *zio* developer, you can skip this chapter and just use
the library.

Source Code Conventions
=======================

This is a random list of conventions I use in this package

* All internal symbols in the driver begin with ``fd_``
  (excluding local variables like *i* and similar stuff). So you know
  if something is local or comes from the kernel.

* All library functions and public data begin with ``fdelay_``.

* The board passed as a library token (``struct fdelay_board``)
  is opaque, so the user doesn't access it.  Internally it is called
  ``userb`` because ``b`` is the real one being used. If you need
  to access library internals from a user file just define
  ``FDELAY_INTERNAL`` before including ``fdelay-lib.h``.

* The driver header is called ``fine-delay.h`` while the user one
  is ``fdelay-lib.h``. The latter includes the former, which user
  programs should not refer to.

* The *tools* directory hosts the suggested command-line tools
  to use the device for testing and quick access. They demonstrate use
  of the library functions using internally-consistent command line
  conventions. All command names begin with ``fmc-fdelay-``

* The *oldtools* directory includes tools that access *zio*
  directly; they are not built by default any more because they are now
  deprecated; we also removed documentation for them, for the same
  reason.  We keep them for our previous users, in case they still want
  to run previous scripts the saved in the past. The directory
  also includes tools that used to be built withing ``lib/`` and
  are deprecated as well. The old tools use
  the name patterns ``fd-raw-`` and ``fdelay-``

* The *lib* directory contains the userspace library, providing a
  simple C API to access the driver.

* The *tools* directory contains a number of tools built on top of that
  library that let you access all features of the *fine-delay* mezzanine.

Using the driver directly
=========================

The driver is designed as a *zio* driver that offers 1 input channel and
4 output channels. Since each output channel is independent (they do
not output at the same time) the device is modeled as 5 separate
*csets*.

The reader of this chapter is expected to be confident with basic *zio*
concepts, available in *zio* documentation (*zio* is an http://ohwr.org.
project).

The device
==========

The overall device includes a few device attributes and a few attributes
specific to the csets (some attributes for input and some attributes for
output).
The attributes allow to read and write the internal timing of the
card, as well as other internal parameters, documented below. Since *zio*
has no support for *ioctl*, all the attributes appear in *sysfs*.
For multi-valued attributes (like a time tag, which is more than 32
bits) the order of reading and writing is mandated by the driver
(e.g.: writing the seconds field of a time must be last, as it is the
action that fires hardware access for all current values).

The device appears in */dev* as a set of char devices:::

   spusa# ls -l /dev/zio/*
   crw------- 1 root root 249,   0 Apr 26 00:26 /dev/zio/fd-0200-0-0-ctrl
   crw------- 1 root root 249,   1 Apr 26 00:26 /dev/zio/fd-0200-0-0-data
   crw------- 1 root root 249,  32 Apr 26 00:26 /dev/zio/fd-0200-1-0-ctrl
   crw------- 1 root root 249,  33 Apr 26 00:26 /dev/zio/fd-0200-1-0-data
   crw------- 1 root root 249,  64 Apr 26 00:26 /dev/zio/fd-0200-2-0-ctrl
   crw------- 1 root root 249,  65 Apr 26 00:26 /dev/zio/fd-0200-2-0-data
   crw------- 1 root root 249,  96 Apr 26 00:26 /dev/zio/fd-0200-3-0-ctrl
   crw------- 1 root root 249,  97 Apr 26 00:26 /dev/zio/fd-0200-3-0-data
   crw------- 1 root root 249, 128 Apr 26 00:26 /dev/zio/fd-0200-4-0-ctrl
   crw------- 1 root root 249, 129 Apr 26 00:26 /dev/zio/fd-0200-4-0-data


The actual pathnames depend on the version of *udev*, and the support
library tries the three names that have been used over time
(the newest name is shown above; the oldest didn't have the two
*zio*).
Also, please note that a still-newer version of *udev* obeys device
permissions, so you'll have read-only and write-only device files.

In this drivers, *cset* 0 is for the input signal, and *csets* 1..4 are
for the output channels.

If more than one board is probed for, you'll have two or more similar
sets of devices, differing in the ``dev_id`` field, i.e. the
``0200`` that follows the device name ``zio-fd`` in the
stanza above. The *dev_id* field is built using the PCI bus
and the *devfn* octet; the example above refers to slot 0 of bus 2.

For remotely-controlled devices (e.g. Etherbone) the problem will need
to be solved differently.

Device (and channel) attributes can be accessed in the proper *sysfs*
directory. For a card in slot 0 of bus 2 (like shown above), the
directory is ``/sys/bus/zio/devices/fd-0200``:::

   spusa# ls -Ff /sys/bus/zio/devices/fd-0200/
   ./       cset0/  utc-h            fd-ch2@           temperature
   ../      cset1/  utc-l            fd-ch3@           version
   name     cset2/  resolution-bits  fd-ch4@           uevent
   command  cset3/  coarse           enable            fd-input@
   devname  cset4/  driver@          calibration_data
   devtype  power/  fd-ch1@          subsystem@

Device Attributes
-----------------

Device-wide attributes are the three time tags (*utc-h*, *utc-l*,
*coarse*), a read-only *version*, a read-only *temperature*
and a write-only *command*.
To read device time you should read *utc-h* first.  Reading *utc-h* will
atomically read all values from the card and store them in the software
driver: when reading *utc-l* and *coarse* you'll get such cached values.

Example:::

   spusa# cd /sys/bus/zio/devices/fd-0200/
   spusa# cat coarse coarse utc-h coarse
   75136756
   75136756
   0
   47088910


To set the time, you can write the three values leaving *utc-h*
last: writing *utc-h* atomically programs the hardware:::

   spusa# echo 10000 > coarse; echo 10000 > utc-l; echo 0 > utc-h
   spusa# cat utc-h utc-l
   0
   10003


The temperature value is scaled by four bits, so you need divide it by
16 to obtain the value in degrees. In this example:::

   spusa# cat temperature
   1129


Temperature is 70.5625 degrees.

If you write 0 to *command*, board time will be
synchronized to the current Linux clock within one microsecond
(reading Linux time and writing to the *fine-delay* registers is
done with interrupts disabled, so the actual synchronization precision
depends on the speed of your CPU and PCI bus):::

   spusa# cat utc-h utc-l; echo 0 > command; cat utc-h utc-l; date +%s
   0
   50005
   0
   1335948116
   1335948116


However, please note that the times will diverge over time. Also, if
you are using White-Rabbit mode, host time is irrelevant to the board.

I chose to offer a *command* channel, which is opaque to the user,
because there are several commands that you may need to send to the
device, and we need to limit the number of attributes. The command numbers
are enumerated in ``fine-delay.h`` and described here below.

List of Commands to the Device
------------------------------

The following commands are currently supported for the ``command``
write-only file in *sysfs*:

0 = FD_CMD_HOST_TIME
  Set board time equal to host time.

1 = FD_CMD_WR_ENABLE
  Enable White-Rabbit mode.

2 = FD_CMD_WR_DISABLE
  Disable White-Rabbit mode.

3 = FD_CMD_WR_QUERY
  Tell the user the status of White-Rabbit mode. This is a hack, as
  the return value is reported using error codes. Success means
  White-Rabbit is synchronized.  ``ENODEV`` means WR mode is not supported
  or inactive, ``EAGAIN```` means it is not synchronized yet.
  The error is returned to the *write* system call.

4 = FD_CMD_DUMP_MCP
  Force dumping to log messages (using a plain *printk* the
  GPIO registers in the MCP23S17 device (fixme: is it really needed).

5 = FD_CMD_PURGE_FIFO
  Empty the input fifo and reset the sequence number.

The Input cset
==============

The input cset returns blocks with no data and timestamp information in the
control structure (the meta-information associated to data).  Before
January 2014 the driver was suboptimal, but now those limitations are
gone and the driver uses the ``self-timed`` *zio* abstraction, which
allows it to push blocks to the buffer even if no process is yet reading.

Collecting event in empty blocks, with full meta-data description, brings
some overhead in the data flow, mainly for the marshalling of meta-data.
If you need to stamp pulse rates higher than 10kHz we advise you to
rely on the *raw_tdc* support, which on an average computer can
timestamp up to 100-150 kHz without data loss. This is described
in :ref:`Raw TDC<dev_raw_tdc>`.  The internals of the input data flow are
described in :ref:`The Input Data Flow<dev_data_flow>`, that may help fine-tune
driver parameters to match your timestamping needs.

For normal *zio* blocks, with meta-data and no data, the hardware
timestamp and other information is returned as *channel
attributes*, which you can look at using *zio-dump* (part of the *zio*
package) or
*tools/fd-raw-input* which is part of this package.

Input Device Attributes
-----------------------

The attributes are all 32-bit unsigned values, and their meaning
is defined in *fine-delay.h* for libraries/applications to use them:::

   enum fd_zattr_in_idx {
           FD_ATTR_TDC_UTC_H,
           FD_ATTR_TDC_UTC_L,
           FD_ATTR_TDC_COARSE,
           FD_ATTR_TDC_FRAC,
           FD_ATTR_TDC_SEQ,
           FD_ATTR_TDC_CHAN,
           FD_ATTR_TDC_FLAGS,
           FD_ATTR_TDC_OFFSET,
           FD_ATTR_TDC_USER_OFF,

   };

   #define FD_TDCF_DISABLE_INPUT	1
   #define FD_TDCF_DISABLE_TSTAMP	2
   #define FD_TDCF_TERM_50		4

The attributes are also visible in */sys*, in the directory
describing the cset:

::
   spusa# ls -Ff /sys/bus/zio/devices/zio-fd-0200/fd-input/
   ./    devname  utc-l            offset
   ../   devtype  current_trigger  uevent
   seq   chan0/   user-offset      current_buffer
   chan  flags    coarse           direction
   frac  power/   enable
   name  utc-h    trigger/

The timestamp-related values in this file reflect the last stamp that
has been enqueued to user space (this may be the next event to be
read by the actual reading process).

The *offset* attribute is the stamping offset, in picoseconds, for the
TDC channel.  The hardware timestamper's time-base is shifted
backwards, so the driver adds this offset to the raw timestamps it
collects. Users should not change this value, that depends on how
hardware and HDL is designed.

The *user-offset* attribute, which defaults to 0 every time the
driver is loaded, is a signed value that users can write to represent a
number of picoseconds to be added (or subtracted, if negative)
to the hardware-reported stamps. This is used to account for delays
induced by cabling (range: -2ms to 2ms).

The *flags* attribute can be used to change three configuration
bits, defined by the respective macros. Please note that the default
at module load time is zero: some of the flags bits are inverted
over the hardware counterpart, but the ``DISABLE`` in flag names
is there to avoid potential errors.

Reading with zio-dump
---------------------

This is an example read sequence using *zio-dump*: data must be ignored
and only the first few extended attributes are meaningful. This can
be used to see low-level details, but please note
that the programs in ``tools/`` and ``lib/`` in this package are
in general a better choice to timestamp input pulses.::

   spusa# zio-dump /dev/zio/fd-0200-0-0-*
   Ctrl: version 0.5, trigger user, dev fd, cset 0, chan 0
   Ctrl: seq 1, n 16, size 4, bits 32, flags 01000001 (little-endian)
   Ctrl: stamp 1335737285.312696982 (0)
   Device attributes:
       [...]
       Extended: 0x0000003f
       0x0 0x30 0x640f20d 0x60a 0x0 0x0 0x0 0x0
       [...]
       Extended: 0x0000003f
       0x0 0x40 0x454b747 0x1d3 0x1 0x0 0x0 0x0
       [...]
       Extended: 0x0000003f
       0x0 0x47 0xf04c57 0x772 0x2 0x0 0x0 0x0


Reading with fd-raw-input
-------------------------

The *tools/fd-raw-input* program, part of this package, is a low-level
program to read input events. It reads
the control devices associated to *fine-delay* cards, ignoring the
data devices which are known to not return useful information.
The program can receive
file names on the command line, but reads all fine-delay devices by
default -- it looks for filenames in */dev* using *glob* patterns (also
called ``wildcards``).

This is an example run:

::
   spusa# ./tools/fd-raw-input
   /dev/zio/zio-fd-0200-0-0-ctrl: 00000000 0000001a 00b9be2b 00000bf2 00000000
   /dev/zio/zio-fd-0200-0-0-ctrl: 00000000 0000001b 00e7f5c2 0000097d 00000001
   /dev/zio/zio-fd-0200-0-0-ctrl: 00000000 0000001b 02c88901 00000035 00000002
   /dev/zio/zio-fd-0200-0-0-ctrl: 00000000 0000001b 03e23c26 000006ce 00000003


The program offers a ``float`` mode, that reports floating point
time differences between two samples (this doesn't use the *frac* delay
value, though, but only the integer second and the coarse 8ns timer).

This is an example while listening to a software-generated 1kHz signal:

::
   spusa# ./tools/fd-raw-input -f
   /dev/zio/fd-0200-0-0-ctrl:    1825.903957552 (delta   0.001007848)
   /dev/zio/fd-0200-0-0-ctrl:    1825.904971384 (delta   0.001013832)
   /dev/zio/fd-0200-0-0-ctrl:    1825.905968648 (delta   0.000997264)
   /dev/zio/fd-0200-0-0-ctrl:    1825.906980376 (delta   0.001011728)
   /dev/zio/fd-0200-0-0-ctrl:    1825.907997128 (delta   0.001016752)


The tool reports lost events using the sequence number (attribute number 4).
This is an example using a software-generated burst with a 10us period:::

   /dev/zio/fd-0200-0-0-ctrl:    1958.385815880 (delta   0.000010024)
   /dev/zio/fd-0200-0-0-ctrl:    1958.385825832 (delta   0.000009952)
   /dev/zio/fd-0200-0-0-ctrl:    1958.385835720 (delta   0.000009888)
   /dev/zio/fd-0200-0-0-ctrl: LOST 2770 events
   /dev/zio/fd-0200-0-0-ctrl:    1958.412775304 (delta   0.026939584)
   /dev/zio/fd-0200-0-0-ctrl:    1958.412784808 (delta   0.000009504)
   /dev/zio/fd-0200-0-0-ctrl:    1958.412794808 (delta   0.000010000)
   /dev/zio/fd-0200-0-0-ctrl:    1958.412804184 (delta   0.000009376)


The ``pico`` mode of the program (command line argument ``-p``) is
used to get input timestamps with picosecond precision. In this mode
the program doesn't report the ``second`` part of the stamp. This is
an example run of the program, fed by 1kHz generated from the board
itself:::

   spusa.root# ./tools/fd-raw-input -p | head -5
   /dev/zio/fd-0800-0-0-ctrl: 642705121635
   /dev/zio/fd-0800-0-0-ctrl: 643705121647 - delta 001000000012
   /dev/zio/fd-0800-0-0-ctrl: 644705121656 - delta 001000000009
   /dev/zio/fd-0800-0-0-ctrl: 645705121647 - delta 000999999991
   /dev/zio/fd-0800-0-0-ctrl: 646705121664 - delta 001000000017


If is possible, for diagnostics purposes, to run several modes
at the same time: while ``-f`` and ``-p`` disable raw/hex mode,
the equivalent options ``-r`` and ``-h`` reinstantiate it.
If the input event is reported in more than one format, the filename
is only printed once, and later lines begin with a single blank space
(you may see more blanks because they are part of normal output,
for alignment purposes).

If you are using the tool in a script, and you want to capture all the
samples in a burst and then terminate, you can specify a timeout, in
microseconds, using ``-t``.  The timeout is only applied after the
first pulse is received.

Finally, the program uses two environment variables, if set to any value:
``FD_SHOW_TIME`` make the tool report the time difference between
sequential reads, which is mainly useful to debug the driver workings;
``FD_EXPECTED_RATE`` makes the tool report the difference from the
expected data rate, relative to the first sample collected:::

   spusa.root# FD_EXPECTED_RATE=1000000000 ./tools/fd-raw-input -p | head -5
   /dev/zio/fd-0800-0-0-ctrl: 139705121668
   /dev/zio/fd-0800-0-0-ctrl: 140705121699 - delta 001000000031 - error  31
   /dev/zio/fd-0800-0-0-ctrl: 141705121661 - delta 000999999962 - error  -7
   /dev/zio/fd-0800-0-0-ctrl: 142705121671 - delta 001000000010 - error   3
   /dev/zio/fd-0800-0-0-ctrl: 143705121689 - delta 001000000018 - error  21


Please note that the expected rate is a 32-bit integer, so it is limited
to 4ms; moreover it is only used in ``picosecond`` mode.

Using fd-raw-perf
-----------------

The program *tools/fd-raw-perf* gives trivial performance figures for
a train of input pulses. It samples all input events and reports some
statistics when a burst completes (i.e., no pulse is received for at
least 300ms):::

   spusa#  ./tools/fd-raw-perf
   59729 pulses (0 lost)
      hw: 1000000000ps (1.000000kHz) -- min 999999926 max 1000000089 delta 163
      sw: 983us (1.017294kHz) -- min 7 max 18992 delta 18985


The program uses the environment variable ``PERF_STEP``, if set, to
report information every that many seconds, even if the burst is still
running:::

   spusa.root# PERF_STEP=5 ./tools/fd-raw-perf

   4999 pulses (0 lost)
      hw: 1000000000ps (1.000000kHz) -- min 999999933 max 1000000067 delta 134
      sw: 1000us (1.000000kHz) -- min 8 max 10001 delta 9993

   4999 pulses (0 lost)
      hw: 1000000000ps (1.000000kHz) -- min 999999926 max 1000000081 delta 155
      sw: 1000us (1.000000kHz) -- min 7 max 18995 delta 18988

Configuring the Input Channel
-----------------------------

There is no support in ``tools/`` to change channel configuration
(but see :ref:`Input Configuration<lib_input>` for the official API).
The user is expected to write values in the *flags* file directly.
For example, to enable the termination resistors, write 4 to the
*flags* file in *sysfs*.

Pulsing from the Parallel Port
------------------------------

For my initial tests, some of which are shown above, I generated bursts
of pulses with a software
program (later I used the board itself, for a much better precision).
To do so, I connected a pin of a parallel port plugged on the PCI bus to
the input channel of the *fine-delay* card.

The program *tools/parport-burst*, part of this package, generates a
burst according to three command line parameters: the I/O port of
the data byte of the parallel port, the repeat count and the duration
of each period. This example makes 1000 pulses of 100 usec each,
using the physical address of my parallel port (if yours is part
of the motherboard, the address is ``378``):::

   ./parport-burst d080 1000 100

.. _dev_raw_tdc:

Raw TDC
-------

If your rate of input pulses is above a dozen kHz, the overheader of
setting up a full *zio* block with proper control information may cause
some data loss; the actual threshold depends on the speed of your
computer and the amount of other activities that are going on.

By loading the module with the parameter ``raw_tdc=1``, you force
the input channel to carry timestamps in the data area; only the first
timestamp is properly converted to meta-data for the control
structure.  This allow timestamping without data loss trains of pulses
of up to 150kHz; again, the actual limit depends on the performance of
your host computer and concurrent load.

Timestamps are returned as 24-byte-long data samples, i.e.
``struct fd_time``, as defined in the header file:::

   struct fd_time {
           uint64_t utc;
           uint32_t coarse;
           uint32_t frac;
           uint32_t channel;
           uint32_t seq_id;
   };


For a simple pulse logging, the following shell command will work:::

   insmod kernel/fmc-fine-delay.ko raw_tdc=1 fifo_len=16384
   cat /dev/zio/fd-0200-0-0-data > logfile


Anders Walling provided tools for use with ``raw_tdc=1``. I'll try to
merge them with this package; meanwhile please find them in
https://github.com/aewallin/fine-delay-sw

.. _dev_data_flow:

The Input Data Flow
-------------------

This section described the input data flow, after a summary about
the basic *zio* concept, because most readers are not expected to be
confident with it.

Fdelay-sw implements a *zio* device. *zio* is a framework to
transport I/O data, its own atomic unit is a "block",
i.e. meta-information (*control*, or ``ctrl``) and actual samples
(*data*).  Each block is like a network frame, in a way: header and
payload.  The header/ctrl is 512 bytes and includes a very sharp
timestamp plus both standardized and device-specific "attribute"
values.

TDC/DTC devices are best represented as an empty block: the header
carries the timestamp and the attributes, and no data is associated
with the event.  This however has an overhead: each timestamp is 512
bytes big, and is delivered as a separate object.  With
``fd-raw-input`` I can collect 30-40kHz square waves, but not more
than that.  This means my computer takes 25-30 microseconds per
sample, including the user-space overhead.  This time is mainly taken
by the data conversion and attribute setting to provide high-level
information; the overhead of a *zio* block is less than one
microsecond, as documented elsewhere.

By using the new module parameter ``raw_tdc=1`` the data flow is
slightly modified and timestamps are delivered to user space in a much
lower-level format.  The sample-size of the input channel is now 24
bytes (``struct fd_time``, defined in the header) and each block can
transport several samples in its data area.  Thus, if configured for N
samples per block, *zio* allocates payload areas of ``24*N`` bytes;
when the input interrupt is served, the driver fills as many samples
as it can, up to N, it then stores the block to the *zio* buffer.
Thus, each block in the buffer will host 1 or more "raw" timestamps,
up to the configured value N.  This lowers the computational load and
allows capturing fast bursts of many thousands pulses.

The data path is then split in the following steps

* In the gateware, timestamps are placed in a ring buffer (FIFO) that
  is currently 1024-samples long (set by ``c_RING_BUFFER_SIZE_LOG2`` in
  ``fine_delay_pkg.vhd``).

* The irq handler pulls the hardware fifo and places samples into a
  software ring buffer (fifo).  The software fifo is an array of "struct
  fd_time".  Its size is configured by the insmod parameter
  ``fifo_len=`` (default is 1024 as I write this). The handler finally
  sends acknowledgement to the hardware and awakes the software
  interrupt.

* The software interrupt handler pulls the software fifo and fills the
  already-allocated *zio* block, finally storing it to the buffer.
  Both the block size and the number of blocks in the buffer are
  configurable at run time.  When *zio* allocates the next block, the
  driver pulls the software fifo too, so any sample received in the
  store-allocate interval is recovered in the new block.  When using
  ``raw_tdc=1``, the *zio* control represents the first timestamp (so
  consistency of the meta-information is preserved), and all stamps
  including the first are included in the data area after a simple
  normalization step.  So the samples are not *very* raw, some
  calculation is still performed, but much less than setting all
  the *zio* attributes.

Thus, the critical points are the following ones:

* Hardware can timestamp up to its maximum speed (I tested 1MHz with no
  issues) as long as the burst fits in the hw fifo.

* The irq handler moves the samples to the software fifo, while
  splitting bit fields. Several samples are handled by each interrupt.
  I think I can pull up to 300-500 kilosamples per second. But I didn't
  prepare a specific test.  This works with no loss as long as the
  software fifo is not overflown. Clearly the sw fifo can be increased
  at will: making it 64-ksample or more is not a problem, but the size
  is constrained to be a power of two.

* Moving the samples from the software fifo to the *zio* buffer is
  another step, which requires a little more data conversion
  (normalization and addition of the user-defined constant offset).
  There is a per-sample overhead and a (bigger) per-block overhead.
  This step detects if an overflow of the software fifo happened. IF so,
  it discards half of the fifo size to recover some margin.

The number of samples per *zio* block is configured by the "post-samples"
attribute (or pre-samples, which is usually left as 0 because stamps
are taken after the trigger event):::

  echo 1000 > /sys/bus/zio/devices/fd-0200/fd-input/trigger/post-samples

A bigger size for the block means more wasted memory if pulses are
slow (the block is used almost-empty); a smaller size means more
overhead and thus a smaller maximum bursts frequency.

The buffer length (number of blocks), can be increased at will:::

  echo 1000 > /sys/bus/zio/devices/fd-0200/fd-input/chan0/buffer/max-buffer-len

There is nothing against using a very long list of blocks in the
buffer, if user-space is slow in pulling data: blocks are only
allocated when needed.  Federico recently added an attribute to
monitor buffer usage: ``allocated-buffer-len`` (which is always at
least 1, because one block is always ready to be filled by the next
interrupt).

Data can be read by user-space simply by reading::

  /dev/zio/fd-0200-0-0-data

The file is a continuous stream of samples. Meta-information is
delivered to another device name: by reading data alone, the
application ignores the control structures that are properly released.

Each sample includes a 16-bit sequence number, so the final consumer
can detect overflows.  This doesn't apply if the software fifo is 128k
samples, because samples are dropped half-a-fifosize each time --
maybe I can change this).  If the *zio* buffer is overflown,
*zio* must discard one or more blocks.  This is reported in the
*alarms* field of the control, also readable as ``alarms`` in sysfs. The
sysfs attribute is write-1-to-clear and there's  no other way to
clear alarms.

In order to see how *zio* blocks flow, you can::

   ./zio/tools/zio-dump /dev/zio/fd-0200-0-0-*

or just *grep* the number of samples in each block, without even
reading the payload:::

  ./zio/tools/zio-dump /dev/zio/fd-0200-0-0-* | grep ", n "

You'll get something like this:::

   Ctrl: seq 2257, n 26, size 24, bits 32, flags 01000001 (little-endian)
   Ctrl: seq 2258, n 436, size 24, bits 32, flags 01000001 (little-endian)
   Ctrl: seq 2259, n 2684, size 24, bits 32, flags 01000001 (little-endian)
   Ctrl: seq 2260, n 4000, size 24, bits 32, flags 01000001 (little-endian)
   [...]
   Ctrl: seq 2268, n 4000, size 24, bits 32, flags 01000001 (little-endian)
   Ctrl: seq 2269, n 854, size 24, bits 32, flags 01000001 (little-endian)

The log above is 40000 samples streamed at 200kHz into 4000-big
*zio* blocks.  In the log above, ``n`` is the number of samples in
each block, ``seq`` is the *zio* sequence number for the block. The
number of bits (32) is wrong, I apologize.

The Output cset
===============

The output channels need some configuration to be provided. This
is done using attributes. Attributes can either be written in
*sysfs* or can be passed in the control block that accompanies data.

This driver defines the sample size as 4 bytes and the trigger should
be configured for a 1-sample block (the library does it at open
time). We should aim at a zero-size data block, but this would require
a patch to *zio*, and I'd better not change version during development.

The output is configured and activated by writing a control block
with proper attributes set. Then a write to the data channel will
push the block to hardware, for it to be activated.

The driver defines the following attributes:::

   /* Output ZIO attributes */
   enum fd_zattr_out_idx {
           FD_ATTR_OUT_MODE = FD_ATTR_DEV__LAST,
           FD_ATTR_OUT_REP,
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

To disable the output, you must assign 0 to the mode attribute and
other attributes are ignored.  To configure pulse or delay, all
attributes must be set to valid values.

.. note::
  writing the output configuration (mode, rep, start, end,
  delta) to *sysfs* is not working with this version of *zio*. And I've
  been too lazy to add code to do that.  While recent developments in *zio*
  introduced more complete consistency between the various places where
  attributes live, with this version you can only write these attributes to
  the control block.

The *delay-offset* attribute represents an offset that is subtracted
from the user-requested delay (*start* fields) when generating output
pulses. It represents internal card delays.  The value can be modified
from *sysfs*.

The *user-offset* attribute, which defaults to 0 at module load time, is a
signed value that users can write to represent a number of picoseconds
to be added (or subtracted) to every user command (for both delay
and pulse generation). This is used to account for delays induced by
cabling (range: -2ms to 2ms).  The value can be modified
from *sysfs*.

This is the unsorted content of the *sysfs* directory for each
of the output csets:::

   spusa# ls -fF /sys/bus/zio/devices/fd-0200/fd-ch1
   ./               mode          end-l         user-offset
   ../              rep           end-coarse    power/
   uevent           start-h       end-fine      trigger/
   name             start-l       delta-l       chan0/
   enable           start-coarse  delta-coarse
   current_trigger  start-fine    delta-fine
   current_buffer   end-h         delay-offset


As said, only *delay-offset* and *user-offset* are designed to be
read and written by the user. Additionally, *mode* can be read to
know whether the channel output or delay event  has triggered.
As of this version, the other attributes are not
readable nor writable in *sysfs* --  they are meant to be used
in the control block written to */dev*.

Using fd-raw-output
-------------------

The simplest way to generate output is using the tools in ``lib/``.
You are therefore urged to skip this section and read
:ref:`Output Configuration<lib_output>` instead.

For the bravest people, the low
level way to generate output is using *fd-raw-output*, part
of the *tools* directory of this package.  The tool writes a control
block to the *zio* control file, setting the block size to 1 32-bit
sample; it then writes 4 bytes to the data file to force output of the
attributes.

The tool acts on channel 1 (the first) by default, but uses the
environment variable ``CHAN`` if set.  All arguments on the command
line are passed directly in the attributes.  Thus, it is quite a
low-level tool.

To help the user, any number that begins with ``+`` is added to the
current time (in seconds). It is thus recommended to set the card to follow
system time.

The following example sets card time to 0 and programs 10 pulses at
the beginning of the next second.  The pulses are 8usec long and
repeat after 16usec.  The next example runs 1s of 1kHz square wave.
For readability, numbers are grouped as *(mode, count)*, *(start --
utc-h, utc-l, coarse, frac)*, *(stop -- utc-h, utc-l, coarse, frac)*,
*(delta - utc-l, coarse, frac)*.::

   spusa# ./tools/fd-raw-settime 0 0; \
          ./tools/fd-raw-output 2 10   0 1 0 0   0 1 1000 0   0 2000 0

   spusa# ./tools/fd-raw-settime 0 0; \
          ./tools/fd-raw-output 2 500   0 1 0 0   0 1 62500 0   0 125000 0

The following example sets board time to host time and programs a single
40us pulse at the beginning of the next second (note use of ``+``)::

   spusa# echo 0 > /sys/bus/zio/devices/fd-*/command; \
          ./tools/fd-raw-output 2 0   0 +1 0 0   0 +1 5000 0

The following example programs a pps pulse (1ms long) on channel 1
and a 1MHz square wave on channel 2, assuming board time is already
synchronized with host time:::

   spusa# CHAN=1 ./tools/fd-raw-output 2 -1   0 +1 0 0   0 +1 125000 0  1 0 0; \
          CHAN=2 ./tools/fd-raw-output 2 -1   0 +1 0 0   0 +1 64 0   0 125 0

.. _dev_cal:

Calibration
===========

Calibration data for a fine-delay card is stored in the I2C FMC EEPROM
device, using the SDB filesystem. Previous versions used a constant
offset of 6kB, but the calibration format was different, so no
compatibility is retained. The driver will refuse to work with cards that have
incompatible EEPROMs, these must be re-calibrated.

The driver automatically loads calibration data from the flash at
initialization time, but only uses it if its hash is valid. The
calibration data is in ``struct fd_calib`` and the on-eeprom structure
is ``fd_calib_on_eeprom``; both are on show in ``fine-delay.h``.

If the hash of the data structure found on EEPROM is not valid, the
driver will use the compile-time default values.  You can act on
this configuration using a number of module parameters; please note
that changing calibration data is only expected to happen at production
time.

calibration_check
    This integer parameter, if not zero, makes the driver dump the binary
    structure of calibration data during initialization.
    It is mainly a debug tool.

calibration_default
    This option should only be used by developers. If not zero, it tells
    the driver to ignore
    calibration data found on the EEPROM, thus enacting a build-time
    default (which is most likely wrong for any board).

calibration_load
    This parameter is a file name, and it should only be used by developers.
    The name is used to ask the *firmware loader*
    to retrieve a file from ``/lib/firmware``.
    The data, once read, is used only
    if the size is correct. The hash is regenerated by the driver. Please
    remember that all values in the calibration structure are stored as
    big-endian.

calibration_save
    This option should only be used by developers, and is not supported
    in this release. If you are a developer and need to change the calibration,
    please check the current master branch on the repository, or a later
    release.
    The integer parameter is used to request saving calibration data to EEPROM,
    whatever values are active after the other parameters have been used.
    You can thus save the compiled-in default, the content of the firmware
    file just loaded, or the value you just read from EEPROM -- not useful,
    but not denied either.

This package currently offers no tool to generate the binary file for
the calibration.
