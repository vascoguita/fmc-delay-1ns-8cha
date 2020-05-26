==================
Command Line Tools
==================

This chapter describes the command line tools that come with the
driver and reside in the ``tools/`` subdirectory. They are provided
as diagnostic utilities and to demonstrate how to use the library.

General Command Line Conventions
================================

Most tools accept the following command-line options, in a
consistent way:

``-d <devid>``
	Used to select one board among several. See the description
        of *fdelay_open* in :ref:`Initialization and Cleanup<lib_init>`.

fmc-fdelay-list
===============

The command takes no arguments. It reports the list of available
boards in the current system:::

   spusa# ./tools/fmc-fdelay-list
     Fine-Delay Device ID 0005
     Fine-Delay Device ID 0004


fmc-fdelay-term
===============

The command can be used to activate or deactivate the 50 ohm
termination resistor.

In addition to the ``-d`` argument the command receives one optional
argument, either ``1`` or ``on`` (activate termination)
or ``0`` or ``off`` (deactivate termination).

::
   spusa# ./tools/fmc-fdelay-term -d 0x5 on
   ./tools/fmc-fdelay-term: termination is on


If no optional argument is passed the termination status is reported back but
not changed.


fmc-fdelay-board-time
=====================

The command is used to act on the time notion of the *fine-delay* card.

In addition to the ``-d`` argument the command receives one mandatory
argument, that is either a command or a floating point number.
The number is the time, in seconds, to be set in the card only if running
with the local oscillator; the command is one of the following ones:

get
	Read board time and print to *stdout*.

host
	Set board time from host time

wr
	Lock the boards to White Rabbit time. It may block if no White
	Rabbit is there. No timeout is currently available.

local
	Detach the board from White Rabbit, and run local time instead.

Examples:::

   spusa# ./tools/fmc-fdelay-board-time -d 0x5 25.5
   spusa# ./tools/fmc-fdelay-board-time -d 0x5 get
   25.504007360
   spusa# ./tools/fmc-fdelay-board-time -d 0x5 get
   34.111048968
   spusa# ./tools/fmc-fdelay-board-time -d 0x5 host
   spusa# ./tools/fmc-fdelay-board-time -d 0x5 get
   1335974946.493415600


fmc-fdelay-input
================

The tool reports input pulses to stdout.  It receives the
usual ``-d`` argument to select one board.

It receives the following options:

``-c <count>``
    Number of pulses to print. Default (0) means run forever.

``-n``
    Nonblocking mode: just print what is pending in the buffer.

``-f``
    Floating point: print as a floatingpoint seconds.pico value.
    The default is a human-readable string, where the decimal part
    is split.

``-r``
    Raw output: print the three hardware timestamps, in decimal.

This an example output, reading a pps signal through a 16ns cable:

::
   spusa.root# ./tools/fmc-fdelay-input -d 0x5 -c 3
   seq 10921:     time      11984:000,000,015,328 ps
   seq 10922:     time      11985:000,000,015,410 ps
   seq 10923:     time      11986:000,000,015,248 ps
   spusa.root# ./tools/fmc-fdelay-input -d 0x5 -c 3 -r
   seq 10924:      raw   utc      11987,  coarse         1,  frac      3773
   seq 10925:      raw   utc      11988,  coarse         1,  frac      3814
   seq 10926:      raw   utc      11989,  coarse         1,  frac      3794
   spusa.root# ./tools/fmc-fdelay-input -d 0x5 -c 3 -f
   seq 10927:     time      11990.000000015328
   seq 10928:     time      11991.000000015410
   seq 10929:     time      11992.000000015410


In a future release we'll support reading concurrently from several
boards.


fmc-fdelay-pulse
================

The program can be used to program one of the output channels to
output a sequence of pulses.  It can parse the following command-line
options:

``-o <output>``
      Output channels are numbered 1 to 4, as written on the device panel.
      Each command invocation can set only one output channel; the
      last ``-o`` specified takes precedence.

``-c <count>``
	Output repeat count: 0 is the default and means forever
``-m <mode>``
	Output mode. Can be ``pulse``, ``delay`` or ``disable``.

``-r <reltime>``
      Output pulse at a relative time in the future. The time is
      a fraction of a second, specified as for ``-T`` and ``-w``,
      described below.  For delay mode the time is used as
      a delay value from input events; for pulse mode the time
      represents a fraction of the next absolute second.

``-D <date>``
      Output pulse at a specified date. The argument is parsed
      as ``<seconds>:<nanoseconds>``.


``-T <period>``, ``-w <width>``
      Period and width of the output signal. A trailing ``m``,
      ``u``, ``n``, ``p`` means milli, micro, nano, pico, resp.
      The parser supports additions and subtractions, e.g.
      ``50m-20n``.
      The period defaults to 100ms and the width defaults to 8us

``-t``
      Wait for the trigger to happen before returning. The boards reports
      a trigger event when the requested pulse sequence is initiated,
      either because the absolute time arrived or because an input
      pulse was detected and the requested delay elapsed.

``-p``, ``-1``
	Pulse-per-seconds and 10MHz. These are shorthands setting many
        parameters.

``-v``
	Verbose: report action to stdout before telling the driver.

This is, for example, how verbose operation reports the request for a single
pulse 300ns wide, 2 microseconds into the next second.:::

  spusa.root# ./tools/fmc-fdelay-board-time -d 0x5 get; \
              ./tools/fmc-fdelay-pulse -d 0x5 -o 1 -m pulse -r 2u -w 300n -c 1 -t
  WR Status: disabled.
  Time: 13728.801090400
  Channel 1: pulse generator mode
    start at:       13729:000,002,000,000 ps
    pulse width:        0:000,000,300,000 ps
    period:             0:100,000,000,000 ps


fmc-fdelay-status
=================

The program reports the current output status of the four channels,
both in human-readable and raw format.  The receives no arguments
besides the usual ``-d``.::

  spusa.root# ./tools/fmc-fdelay-status -d 0x5
  Channel 1: pulse generator mode (triggered)
    start at:       13729:000,002,000,000 ps
    pulse width:        0:000,000,300,000 ps
    period:             0:100,000,000,000 ps
  Channel 2: disabled
  Channel 3: disabled
  Channel 4: disabled

Please note that the tool reads back hardware values, which are already
fixed for calibration delays. A difference in value may depends on the
``delay-offset`` value for the channel, according to calibration.
