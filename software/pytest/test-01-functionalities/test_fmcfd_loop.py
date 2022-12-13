"""
SPDX-License-Identifier: LGPL-2.1-or-later
SPDX-FileCopyrightText: 2020 CERN
"""

import pytest
import select
import time
import os
from PyFmcFineDelay import FmcFineDelay, FmcFineDelayTime
import random


@pytest.fixture(scope="function")
def fmcfd():
    fd = FmcFineDelay(pytest.fd_id)
    for ch in fd.chan:
        ch.disable()
    yield fd
    for ch in fd.chan:
        ch.disable()


@pytest.fixture(scope="function", params=pytest.channels)
def fmcfd_chan(request, fmcfd):
    yield fmcfd.chan[request.param]
    fmcfd.chan[request.param].disable()


MIN_COUNT = 1
MAX_COUNT = 0xFFFF


@pytest.fixture(scope="function")
def fmcfd_tdc(request, fmcfd):
    fmcfd.tdc.enable_input = False
    fmcfd.tdc.enable_tstamp = False
    fmcfd.tdc.termination = False
    fmcfd.tdc.flush()

    fmcfd.tdc.enable_tstamp = True
    fmcfd.tdc.enable_input = True
    yield fmcfd.tdc
    fmcfd.tdc.enable_input = False
    fmcfd.tdc.enable_tstamp = False


def timeout_compute(start, period_ps, count):
    proportional = ((count * period_ps) / 1000000000000.0)
    return time.time() + proportional + start + 5


class TestFmcfdLoop(object):
    """
    The test needs a lemo cable (1ns) that connects all outputs
    to the input channel

    input
      chan   o------.
    output           |
      chan 1 o-------+
      chan 2 o-------+
      chan 3 o-------+
      chan 4 o-------`
    """

    def test_output_flush(self, fmcfd, fmcfd_chan, fmcfd_tdc):
        period_ps = 400000
        fmcfd_chan.pulse_generate(fmcfd.time + FmcFineDelayTime(2, 0, 0),
                                  int(period_ps / 2), period_ps,  1)
        assert len(fmcfd_tdc.poll(4000)) > 0
        fmcfd_tdc.flush()
        assert len(fmcfd_tdc.poll(4000)) == 0


    @pytest.mark.parametrize("count", [1, MAX_COUNT] +
                                      [random.randrange(MIN_COUNT + 1,
                                                        int(MAX_COUNT / 10)) for x in range(8)])
    def test_output_counter(self, fmcfd, fmcfd_chan, fmcfd_tdc, count):
        """
        In pulse mode, the Fine-Delay generates the exact number of
        required pulses and we are able to read them all from the input
        channel.
        """
        ts = []
        period_ps = 4500000000
        start_s = 2
        start = fmcfd.time + FmcFineDelayTime(start_s, 0, 0)
        fmcfd_chan.pulse_generate(start, int(period_ps / 2), period_ps, count)
        timeout = timeout_compute(start_s, period_ps, count)
        while len(ts) < count and time.time() < timeout:
            if len(fmcfd_tdc.poll()) == 0:
                continue
            try:
                t = fmcfd_tdc.read(100, os.O_NONBLOCK)
            except BlockingIOError:
                t = fmcfd_tdc.read(100, os.O_NONBLOCK)

            assert len(t) > 0
            ts = ts + t
        assert len(ts) == count
        assert len(fmcfd_tdc.poll(int(period_ps / 1000000000.0))) == 0
        del ts

    @pytest.mark.parametrize("count", [random.randrange(1000, 10000)])
    def test_input_sequence_number(self,fmcfd_chan, fmcfd_tdc, count):
        """
        The input channel has time-stamps with increasing sequence number
        with step 1.
        """
        period_ps = 4500000000
        pending = count
        ts = []
        start_s = 2
        start = FmcFineDelayTime(start_s, 0, 0)
        fmcfd_chan.pulse_generate(fmcfd_chan.dev.time + start,
                                  int(period_ps / 2), period_ps, count)

        timeout = timeout_compute(start_s, period_ps, count)
        while pending > 0 and time.time() < timeout:
            if len(fmcfd_tdc.poll()) == 0:
                continue
            try:
                t = fmcfd_tdc.read(100, os.O_NONBLOCK)
            except BlockingIOError:
                t = fmcfd_tdc.read(100, os.O_NONBLOCK)
            assert len(t) > 0
            ts.extend(t)
            pending -= len(t)
        assert pending == 0

        prev_ts = None
        for i in range(len(ts)):
            if prev_ts is not None:
                assert ts[i].seq_id == (prev_ts.seq_id + 1) & 0xFFFF,\
                  "i:{:d}, cur: {:s}, prev: {:s}".format(i, str(ts[i]),
                                                         str(prev_ts))

    @pytest.mark.parametrize("start_rel", [FmcFineDelayTime(random.randrange(0, 60),
                                                            random.randrange(0, 125000000),
                                                            0) for i in range(10)])
    @pytest.mark.parametrize("wr", [False, True])
    def test_output_input_start(self, fmcfd_chan, fmcfd_tdc, wr, start_rel):
        """
        The output channel generates a pulse at a given time and the input
        channel timestamps it. The two times must be almost the same excluding
        the propagation time (cable length).
        """
        period_ps = 1000000
        count = 1

        fmcfd_chan.dev.whiterabbit_mode = wr
        ts = []

        start = fmcfd_chan.dev.time + start_rel
        fmcfd_chan.pulse_generate(start, int(period_ps / 2), period_ps, count)
        assert len(fmcfd_tdc.poll(int(float(start_rel) * 1000) + 2000)) > 0
        ts = fmcfd_tdc.read(count, os.O_NONBLOCK)
        assert len(ts) == count
        assert start.seconds == ts[0].seconds
        assert ts[0].coarse - start.coarse <= 3 # there is < 3ns cable


    @pytest.mark.parametrize("period_ps", [random.randrange(400000, 1000000000000)])
    @pytest.mark.parametrize("count", [10])
    def test_output_period(self, fmcfd_chan, fmcfd_tdc, period_ps, count):
        """
        The test produces pulses on the given channels and catch them using
        the on board TDC. The period between two timestamps must be as close
        as possible (ideally equal) to the period used to generate them.
        """
        ts = []

        start = fmcfd_chan.dev.time + FmcFineDelayTime(2, 0, 0, 0, 0)
        fmcfd_chan.pulse_generate(start, int(period_ps / 2), period_ps, count)
        time.sleep(2 + (count * period_ps) / 1000000000000.0)
        assert len(fmcfd_tdc.poll(10000)) > 0
        ts = fmcfd_tdc.read(count, os.O_NONBLOCK)
        assert len(ts) == count

        prev_ts = None
        for i in  range(len(ts)):
            if prev_ts is not None:
                assert ts[i].seq_id == prev_ts.seq_id + 1
                period_ts = ts[i] - prev_ts
                period = FmcFineDelayTime.from_pico(period_ps)
                if period > period_ts:
                    diff = period - period_ts
                else:
                    diff = period_ts - period
                assert diff < FmcFineDelayTime(0, 1, 0), \
                  "period difference {:s}\n\tcurr: {:s}\n\tprev: {:s}\n\tperi: {:s}".format(str(diff),
                                                                                            str(ts[i]),
                                                                                            str(prev_ts),
                                                                                            str(period_ts))
            prev_ts = ts[i]
