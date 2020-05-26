======
Driver
======

Driver Features
===============

This driver is based on `zio`_ and it uses `fmc`_.  It supports initial
setup of the board, setting and reading time, run-time continuous
calibration, input timestamping, output pulse generation and readback of
output settings from the hardware.  It supports user-defined offsets,
so our users can tell the driver about channel-specific delays (for
example, to account for wiring) and ignore the issue in application code.

For each feature offered the driver (and documentation) the driver
tries to offer the following items; sometimes however one of them is missing
for a specific driver functionality, if we don't consider it important enough.


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

The module also supports some more parameters that are
calibration-specific. They are described in the :ref:`Calibration<dev_cal>`
section.

.. _zio: https://www.ohwr.org/project/zio
.. _fmc: https://www.ohwr.org/project/fmc-sw
