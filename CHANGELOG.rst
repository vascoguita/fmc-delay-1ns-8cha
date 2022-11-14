.. SPDX-License-Identifier: CC-BY-SA-4.0+
..
.. SPDX-FileCopyrightText: 2019 CERN

=========
Changelog
=========

3.0.8 - 2021-03-17
==================

Changed
-------
- hdl: svec-base updated to 2.0, for the FD there are no incompatible changes
- sw,hdl: compact memory map [we know, do not ask]

3.0.7 - 2021-02-24
==================

Added
-----
- sw: show the input status from the fmc-fdelay-status tool
- sw: use the fmc-fdelay-input tool to change the input status

Fixed
-----
- sw: make clear in the tools' help message that the device ID is an
  hexadecimal number

3.0.6 - 2021-01-20
==================
Fixed
-----
- sw: open_by_lun() conversion from LUN to ID

3.0.5 - 2020-12-14
==================
Fixed
-----
- sw: open_by_lun() path to /dev/ device changed

3.0.4 - 2020-12-11
==================
Changed
-------
- hdl: include fixes from SPEC and SVEC

Added
-----
- sw: add symlink to FMC slot in sysfs

Fixed
-----
- sw: IPMI header
- tst: timeout computation was wrong in some cases and very very long

3.0.3 - 2020-10-07
==================

Changed
-------
- drv: ZIO device parent is, correctly, the Fine-Delay platform
  device. Before it did not have any parent so this change should not
  break anything.

3.0.2 - 2020-09-25
==================

Added
-----
- bld: cppcheck target for software

Fixed
-----
- sw: SVEC, load device driver instance only if the mezzanine is present.

3.0.1 - 2020-06-04
==================

Changed
-------
- sw: version reporting in sysfs include the full output from 'git describe'

3.0.0 - 2020-06-02
==================

Added
-----
- First release of Convention-based Fine Delay HW/GW/SW.
- Added programmable delay line on the TDC start FPGA input to compensate for different delays on
  TDC start signal from different production batches of the boards.
