============
Introduction
============

This is the user manual for the *fmc-delay-1ns-4cha* board developed on
http://ohwr.org.  Please note that the ohwr hardware project is
misnamed as *fmc-delay-1ns-8cha*; even if the board has 4
channels; the references to *8ch* below are thus correct, even if
the may seem wrong.

Repositories and Releases
=========================

The code and documentation is distributed in the following places:

http://www.ohwr.org/projects/fine-delay-sw/documents
  This place hosts the pdf documentation for some official
  release, but we prefer to use the *files* tab, below.

http://www.ohwr.org/projects/fine-delay-sw/files
  Here we place the *.tar.gz* file for every release,
  including the *git* tree and compiled documentation (for
  those who lack TeX), as well as manuals.

git://ohwr.org/fmc-projects/fmc-delay-1ns-8cha/fine-delay-sw.git
  Read-only repositories for the software and documentation.

git@@ohwr.org:fmc-projects/fmc-delay-1ns-8cha/fine-delay-sw.git
  Read-write repositories, for those authorized.

.. note::
   If you got this from the repository (as opposed to a named
   *tar.gz* or *pdf* file) it may happen that you are looking at a later
   commit than the release this manual claims to document.
   It is a fact of life that developers forget
   to re-read and fix documentation while updating the code. In that case,
   please run ``git describe HEAD`` to ensure where you are.

Hardware Description
====================

The *FMC Delay 1ns-4cha* is an FPGA Mezzanine Card (FMC - VITA 57 standard),
whose main purpose is to produce pulses delayed by a user-programmed value with
respect to the input trigger pulse. The card can also work as a Time to
Digital converter (TDC) or as a programmable pulse generator triggering at a
given TAI time.

For the sake of clarity of this document, the card's  name will be further
abbreviated as *fine-delay*.

Requirements and Supported Platforms
====================================

*fine-delay* can work with any VITA 57-compliant FMC carrier, provided that
the carrier's FPGA has enough logic resources. The current software/gateware
release officially supports the following carrier and mezzanine combinations:

* CERN's SPEC (Simple PCI-Express Carrier) with one *fine-delay* mezzanine.
* CERN's SVEC (Simple VME64x Carrier) with one or two *fine-delay* mezzanines.

Note that if only one *fine-delay* is in use, the other slot should be left
empty.

Aside from the FMC and its carrier, the following hardware/software components
are required:

* For the PCI version: a standard PC with at least one free 4x (or wider)
  PCI-Express slot.
* For the VME version: a VME64x crate with a MEN A20 CPU.
* 50-ohm cables with 1-pin LEMO 00 plugs for connecting the I/O signals.
* Any Linux (kernel 2.6 or 3.0+) distribution. Backports are provided down to
  kernel ``2.6.24``.

Modes of Operation
==================

*fine-delay* can work in one or more of the following modes:

* **Pulse Delay**: produces one or more pulse(s) on selected outputs
  a given time after an input trigger pulse (fig. 1a).
* **Pulse Generator**: produces one or more pulse(s) on selected outputs
  starting at an absolute time value programmed by the user (fig. 1b).
  In this mode, time base is usually provided by the White Rabbit network.
* **Time to Digital Converter**: tags all trigger pulses and delivers the
  timestamps to the user's application.

.. image:: drawings/func.eps
	   :alt: *fine-delay* operating modes.

Modes (pulse delay/generator) can be selected independently for each output.
For example, one can configure the output 1 to delay trigger pulses
by 1 us, and the output 2 to produce a pulse at the beginning of each second.
The TDC mode can be enabled for the input at any time and
does not interfere with the operation of the channels being time tagged.

Mechanical/Environmental
========================

.. image:: drawings/front_panels.eps
	   :alt: *fine-delay* front panel connector layout.

**Mechanical and environmental specs:**

* Format: FMC (VITA 57), with rear zone for conduction cooling.
* Operating temperature range: 0 - 90 degC.
* Carrier connection: 160-pin Low Pin Count FMC connector.

Electrical
==========

**Inputs/Outputs:**

* 1 trigger input (LEMO 00).
* 4 pulse outputs (LEMO 00).
* 2 LEDs (termination status and trigger indicator).
* Carrier communication via 160-pin Low Pin Count FMC connector.

**Trigger input:**

* TTL/LVTTL levels, DC-coupled. Reception of a trigger pulse is indicated by
  blinking the "TRIG" LED in the front panel.
* 2 kOhm or 50 Ohm input impedance (programmable via software).
  50 Ohm termination is indicated by the "TERM" LED in the front panel.
* Power-up input impedance: 2 kOhm.
* Protected against short circuit, overcurrent (> 200 mA) and overvoltage
  (up to +28 V).
* Maximum input pulse edge rise time: 20 ns.

**Outputs:**

* TTL-compatible levels DC-coupled: Voh = 3 V, Vol = 200 mV (50 Ohm load),
  Voh = 6 V, Vol = 400 mV (high impedance).
* Output impedance: 50 Ohm (source-terminated).
* Rise/fall time: 2.5 ns (10%% - 90%%, 50 Ohm load).
* Power-up state: LOW (2 kOhm pulldown), guaranteed glitch-free.
* Protected against continuous short circuit, overcurrent and overvoltage
  (up to +28 V).

**Power supply:**

* Used power supplies: P12V0, P3V3, P3V3_AUX, VADJ (voltage monitor only).
* Typical current consumption: 200 mA (P12V0) + 1.5 A (P3V3).
* Power dissipation: 7 W. Forced cooling is required.

Timing
======

.. image:: drawings/io_timing.eps
	   :alt: *fine-delay* timing parameter definitions.

**Time base:**

* On-board oscillator accuracy: +/- 2.5 ppm (i.e. max. 2.5 ns error for a
  delay of 1 ms).
* When using White Rabbit as the timing reference: depending on the
  characteristics of the grandmaster clock and the carrier used. On SPEC
  v 4.0 FMC carrier, the accuracy is better than 1 ns.

**Input timing:**

* Minimum pulse width: :math:`t_{IW}` = 50 ns. Pulses below 24 ns are rejected.
* Minimum gap between the last delayed output pulse and subsequent trigger
  pulse: :math:`T_{LT}` = 50 ns.
* Input TDC performance: 400 ps pp accuracy, 27 ps resolution,
  70 ps trigger-to-trigger rms jitter (measured at 500 kHz pulse rate).

**Output timing:**

* Resolution: 10 ps.
* Accuracy (pulse generator mode): 300 ps.
* Train generation: trains of 1-65536 pulses or continuous square wave up
  to 10 MHz.
* Output-to-output jitter (outputs programmed to the same delay): 10 ps rms.
* Output-to-output jitter (outputs programmed to to different delays, worst
  case): 30 ps rms.
* Output pulse spacing (:math:`T_{SP}`) : 100 ns - 16 s. Adjustable in 10 ps
  steps when both :math:`T_{PW}`, :math:`T_{GAP}` > 200 ns. Outside that range,
  :math:`T_{SP}` resolution is limited to 4 ns.
* Output pulse start (:math:`t_{START}`) resolution: 10 ps for the rising edge
  of the pulse, 10 ps for subsequent pulses if the condition above is met,
  otherwise 4 ns.

**Delay mode specific parameters:**

* Delay accuracy: < 1 ns.
* Trigger-to-output jitter: 80 ps rms.
* Trigger-to-output delay: minimum :math:`T_{DLY}` = 600 ns,
  maximum :math:`T_{DLY}` = 120 s.
* Maximum trigger pulse rate: :math:`T_{DLY} + N*(T_{SP} + T_{GAP}) +` 100 ns,
  where N = number of output pulses.
* Trigger pulses are ignored until the output with the biggest delay has
  finished generation of the pulse(s).


Principles of Operation
=======================

.. note::
   if you are an electronics engineer, you can skip this section, as
   you will most likely find it rather boring.

.. image:: drawings/analog_digital_delays.eps
   :alt: Principle of operation of analog and digital delay generators.

Contrary to typical analog delay cards, which work by comparing an analog ramp
triggered by the input pulse with a voltage proportional to the desired delay,
*fine-delay* is a digital delay generator, which relies on time tag arithmetic.
The principle of operation of both generators is illustrated in figure 3.

When a trigger pulse comes to the input, *fine-delay* first produces its'
precise time tag using a Time-to-Digital converter (TDC). Afterwards,
the time tag is summed together with the delay preset and the result is
passed to a digital pulse generator.
In its simplest form, it consists of a free running counter and a comparator.
When the counter reaches the value provided on the input, a pulse is produced
on the output.
Note that in order for the system to work correctly, both the TDC and
the Pulse Generator must use exactly the same time base (not shown on
the drawings).

Digital architecture brings several advantages compared to analog
predecessors: Timestamps generated by the TDC can be also passed to
the host system, and the Pulse Generators can be programmed with arbitrary
pulse start times instead of :math:`t_{TRIG} + T_{DLY}`. Therefore,
*fine-delay* can be used simultaneously as a TDC, pulse generator or
a pulse delay.
