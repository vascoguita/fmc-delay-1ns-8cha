..
  SPDX-License-Identifier: CC-0.0
  SPDX-FileCopyrightText: 2019 CERN

=========
Changelog
=========

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
