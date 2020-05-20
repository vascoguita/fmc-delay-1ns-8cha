======================
Using the Provided API
======================

This chapter describes the higher level interface to the board,
designed for user applications to use.  The code lives in the *lib}
subdirectory of this package. The directory uses a plain Makefile (not
a Kbuild one) so it can be copied elsewhere and compiled stand-alone.
Only, it needs a copy of ``fine-delay.h`` (which it currently pulls
from the parent directory) and the *zio* headers, retrieved using the
``ZIO`` environment variable).

.. _lib_init:

Initialization and Cleanup
==========================

Before using this library it must be initilized by calling
:c:func:`fdelay_init`. When you are not going to use the library anymore
call :c:func:`fdelay_exit` to release all allocated resources.

.. doxygenfunction:: fdelay_init

.. doxygenfunction:: fdelay_exit

In order to be able to handle a *fine-delay* device you must open it
with one of the following functions :c:func:`fdelay_open` or
:c:func:`fdelay_open_by_lun`. All these functions return a device token
which is required by most *fine-delay* functions. When you do not want to
use anymore the device, you should close it with :c:func:`fdelay_close`.

.. doxygenfunction:: fdelay_open

.. doxygenfunction:: fdelay_open_by_lun

.. doxygenfunction:: fdelay_close

Example code: all tools in ``tools/`` subdirectory.

.. _lib_time:

Time Management
===============

These are the primitives the library offers for time management, including
support for White Rabbit network synchronization.

.. doxygenfunction:: fdelay_set_time

.. doxygenfunction:: fdelay_get_time

.. doxygenfunction:: fdelay_set_host_time

.. doxygenfunction:: fdelay_wr_mode

.. doxygenfunction:: fdelay_check_wr_mode

Example code: ``fmc-fdelay-board-time`` tool.

.. _lib_input:

Input Configuration
===================

To configure the input channel for a board, the library offers the
following function and macros:

.. doxygenfunction:: fdelay_set_config_tdc

.. doxygenfunction:: fdelay_get_config_tdc

.. doxygendefine:: FD_TDCF_DISABLE_INPUT

.. doxygendefine:: FD_TDCF_DISABLE_TSTAMP

.. doxygendefine:: FD_TDCF_TERM_50

Example code: ``fmc-fdelay-term`` tool.

Reading Input Timestamps
========================

The library offers the following functions that deal with the input stamps:

.. doxygenfunction:: fdelay_read

.. doxygenfunction:: fdelay_fread

.. doxygenfunction:: fdelay_fileno_tdc

.. _lib_output:

Output Configuration
====================

The library offers the following functions for output configuration:

.. doxygenfunction:: fdelay_config_pulse

.. doxygenfunction:: fdelay_config_pulse_ps

.. doxygenfunction:: fdelay_get_config_pulse

.. doxygenfunction:: fdelay_get_config_pulse_ps

.. doxygenfunction:: fdelay_has_triggered

The configuration functions receive a time configuration. The
starting time is passed as ``struct fdelay_time``, while the
pulse end and loop period are passed using either the same structure
or a scalar number of picoseconds. These are the relevant structures:

.. doxygenstruct:: fdelay_time
   :members:

.. doxygenstruct:: fdelay_pulse
   :members:

.. doxygenstruct:: fdelay_pulse_ps
   :members:

Example code: ``fmc-fdelay-pulse`` tool.

Miscellanous functions
======================

.. doxygenfunction:: fdelay_pico_to_time

.. doxygenfunction:: fdelay_time_to_pico

.. doxygenfunction:: fdelay_read_temperature
