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

The library offers the following structures and functions:

``struct fdelay_board``

	This is the ``opaque`` token that is being used by library clients.
        If you want to see the internals define ``FDELAY_INTERNAL``
        and look at *fdelay_list.c*.

``int fdelay_init(void)``, `` void fdelay_exit(void)``

	The former function allocates its internal data and returns
	the number of boards currently found on the system. The latter
        releases any allocated data. If *init* fails, it returns -1 with
        a proper ``errno`` value. If no boards are there it returns 0.
        You should not load or unload drivers between *init* and *exit*.

``struct fdelay_board *fdelay_open(int index, int dev_id)``, ``int fdelay_close(struct fdelay_board *)``

	The former function opens a board and returns a token that can
        be used in subsequent calls. The latter function undoes it.
        You can refer to a board either by index or by
        ``dev_id``. Either argument (but not both) may be -1. If both
        are different from -1 the index and dev_id must match. If a mismatch
        is found, the function return NULL with ``EINVAL``; if either index or
        ``dev_id`` are not found, the function returns NULL with ``ENODEV``.

``struct fdelay_board *fdelay_open_by_lun(int lun)``

	The function opens a pointer to a board, similarly to *fdelay_open*,
        but it uses the Logical Unit Number as argument instead. The LUN
        is used internally be CERN libraries, and the function is needed
        for compatibility with the installed tool-set.  The function uses
        a symbolic link in *dev*, created by the local installation procedure.


Example code: all tools in ``tools/`` subdirectory.

.. _lib_time:

Time Management
===============

These are the primitives the library offers for time management, including
support for White Rabbit network synchronization.

``struct fdelay_time``

	The structure has the same fields as the one in the initial
        user-space library. All but *utc* are unsigned 32-bit values
        whereas they were different types in the first library.

``int fdelay_set_time(struct fdelay_board *b, struct fdelay_time *t)``, ``int fdelay_get_time(struct fdelay_board *b, struct fdelay_time *t)``

	The functions are used to set board time from a user-provided
        time, and to retrieve the current board time to user space.
        The functions return 0 on success. They only use the fields
        *utc* and *coarse* of ``struct fdelay_time``.

``int fdelay_set_host_time(struct fdelay_board *b)``

	The function sets board time equal to host time. The precision
        should be in the order of 1 microsecond, but will drift over time. This function is only provided to 
        coarsely correlate the board time with the system time. Relying on system time 
        for synchronizing multiple *fine-delays* is strongly discouraged.

``int fdelay_wr_mode(struct fdelay_board *b, int on)``

	The function enables/disables White Rabbit mode.
        It may fail with ``ENOTSUPP`` if there's no White Rabbit support in the
        gateware.

``int fdelay_check_wr_mode(struct fdelay_board *b)``

	The function returns 0 if the WR slave is synchronized, ``EAGAIN``
        if it is enabled by not yet synchronized, ``ENODEV``
        if WR-mode is currently disabled and ``ENOLINK`` if the WR link is down (e.g. unconnected cable).

Example code: ``fmc-fdelay-board-time`` tool.

.. _lib_input:

Input Configuration
===================

To configure the input channel for a board, the library offers the
following function and macros:

``int fdelay_set_config_tdc(struct fdelay_board *b, int flags)``, ``int fdelay_get_config_tdc(struct fdelay_board *b)``

	The function configures a few options in the input channel.
	The *flags* argument is a bit-mask of the following three
        values (note that 0 is the default at initialization time).
        The function returns -1 with ``EINVAL`` if the *flags*
        argument includes undefined bits.

``FD_TDCF_DISABLE_INPUT``, ``FD_TDCF_DISABLE_TSTAMP``, ``FD_TDCF_TERM_50``

	The first bit disables the input channel, the second disables
        acquisition of timestamps, and the last enables the 50-ohm
        termination on the input channel.

Example code: ``fmc-fdelay-term`` tool.

Reading Input Timestamps
========================

The library offers the following functions that deal with the input stamps:

``int fdelay_fread(struct fdelay_board *b, struct fdelay_time *t, int n)``

	The function behaves like *fread*: it tries to read all samples,
        even if it implies sleeping several times.  Use it only if you are
        aware that all the expected pulses will reach you.

``int fdelay_read(struct fdelay_board *b, struct fdelay_time *t, int n, int flags)``

	The function behaves like *read*: it will wait at most once
        and return the number of samples that it received.  The *flags*
        argument is used to pass 0 or ``O_NONBLOCK``. If a non-blocking
        read is performed, the function may return -1 with ``EAGAIN``
        if nothing is pending in the hardware FIFO.

``int fdelay_fileno_tdc(struct fdelay_board *b)``

	This returns the file descriptor associated to the TDC device,
        so you can *select* or *poll* before calling *fdelay_read*.
        If access fails (e.g., for permission problems), the functions
        returns -1 with ``errno`` properly set.

.. _lib_output:

Output Configuration
====================

The library offers the following functions for output configuration:

``int fdelay_config_pulse(board, channel, pulse_cfg)``, ``int fdelay_config_pulse_ps(board, channel, pulse_ps_cfg)``

	The two functions configure the channel
        for pulse or delay mode. The channel numbers are 0..3 (that is, the number of the output on the 
        front panel minus 1, you may use ``FDELAY_OUTPUT`` macro to convert). The former function receives
        ``struct fdelay_pulse`` (with split utc/coarse/frac times)
        while the latter receives ``struct fdelay_pulse_ps``, with
        picosecond-based time values. The functions return 0 on success, -1
        and an error code in ``errno`` in case of failure.

``int fdelay_get_config_pulse(board, channel, pulse_cfg)``, ``int fdelay_get_config_pulse_ps(board, channel, pulse_ps_cfg)``

       The two functions return the configuration of the channel
       (numbered 0..3) read from the hardware. They may be used to check
       the correctness of outputs' programming. The former function returns
       ``struct fdelay_pulse`` (with split utc/coarse/frac times)
       while the latter returns ``struct fdelay_pulse_ps``, with
       picosecond-based time values.

``int fdelay_has_triggered(struct fdelay_board *b, int channel)``

	The function returns 1 of the output channel (numbered 0..3) has
        triggered since the last configuration request, 0 otherwise.

The configuration functions receive a time configuration. The
starting time is passed as ``struct fdelay_time``, while the
pulse end and loop period are passed using either the same structure
or a scalar number of picoseconds. These are the relevant structures:::

   struct fdelay_time {
           uint64_t utc;
           uint32_t coarse;    uint32_t frac;
           uint32_t seq_id;    uint32_t channel;
   };

   struct fdelay_pulse {
           int mode;           int rep;    /* -1 == infinite */
           struct fdelay_time start, end, loop;
   };

   struct fdelay_pulse_ps {
           int mode;          int rep;
           struct fdelay_time start;
           uint64_t length, period;
   };

The ``rep`` field represents the repetition count, to output a
train of pulses. The mode field is one of ``FD_OUT_MODE_DISABLED``,
``FD_OUT_MODE_DELAY``, ``FD_OUT_MODE_PULSE``.

Example code: ``fmc-fdelay-pulse`` tool.

Miscellanous functions
======================

``void fdelay_pico_to_time(uint64_t *pico, struct fdelay_time *time)``

     Splits a time value expressed in picoseconds to *fine-delay*'s internal
     time format (utc/coarse/frac).

``void fdelay_time_to_pico(struct fdelay_time *time, uint64_t *pico)``

     Converts from *fine-delay*'s internal time format (utc/coarse/frac)
     to plain picoseconds.

``float fdelay_read_temperature(struct fdelay_board *b)``

    Returns the temperature of the given board, in degrees Celsius.
