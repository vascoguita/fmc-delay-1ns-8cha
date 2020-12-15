"""
SPDX-License-Identifier: GPL-3.0-or-later
SPDX-FileCopyrightText: 2020 CERN
"""

import pytest
import select
import time
import os
from PyFmcFineDelay import FmcFineDelay, FmcFineDelayTime

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

pulse_train = [(200000, 10000000000)]

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
    proportional = ((count * period_ps)/1000000000000.0)
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

    @pytest.mark.parametrize("count", [10])
    @pytest.mark.parametrize("width,period", [(200000, 400000)])
    def test_output_flush(self, fmcfd, fmcfd_chan, fmcfd_tdc,
                          width, period, count):
        fmcfd_chan.pulse_generate(fmcfd.time + FmcFineDelayTime(2, 0, 0),
                                  width, period, count)
        assert len(fmcfd_tdc.poll(4000)) > 0
        fmcfd_tdc.flush()
        assert len(fmcfd_tdc.poll(4000)) ==0

    @pytest.mark.parametrize("count", [1, 2, 3, 5, 7, 10,
                                       100, 1000, 10000, 65535])
    @pytest.mark.parametrize("width,period", pulse_train)
    def test_output_counter(self, fmcfd, fmcfd_chan, fmcfd_tdc,
                            width, period, count):
        """
        In pulse mode, the Fine-Delay generates the exact number of
        required pulses and we are able to read them all from the input
        channel.
        """
        ts = []
        start_s = 2
        start = fmcfd.time + FmcFineDelayTime(start_s, 0, 0)
        fmcfd_chan.pulse_generate(start, width, period, count)
        timeout = timeout_compute(start_s, period, count)
        while len(ts) < count and time.time() < timeout:
            if len(fmcfd_tdc.poll()) == 0:
                continue
            t = fmcfd_tdc.read(100, os.O_NONBLOCK)
            assert len(t) > 0
            ts = ts + t
        assert len(ts) == count
        assert len(fmcfd_tdc.poll(int(period / 1000000000.0))) == 0
        del ts

    @pytest.mark.parametrize("count", [10000])
    @pytest.mark.parametrize("width,period", pulse_train)
    def test_input_sequence_number(self, capsys, fmcfd_chan, fmcfd_tdc,
                                   width, period, count):
        """
        The input channel has time-stamps with increasing sequence number
        with step 1.
        """
        pending = count
        ts = []
        start_s = 2
        start = FmcFineDelayTime(start_s, 0, 0)
        fmcfd_chan.pulse_generate(fmcfd_chan.dev.time + start,
                                  width, period, count)

        timeout = timeout_compute(start_s, period, count)
        while pending > 0 and time.time() < timeout:
            if len(fmcfd_tdc.poll()) == 0:
                continue
            t = fmcfd_tdc.read(pending, os.O_NONBLOCK)
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

    @pytest.mark.parametrize("start_rel", [FmcFineDelayTime(0, 78125000, 0),  # + 0.0625s
                                           FmcFineDelayTime(0, 15625000, 0),  # + 0.125s
                                           FmcFineDelayTime(0, 31250000, 0),  # + 0.25s
                                           FmcFineDelayTime(0, 62500000, 0),  # + 0.5s
                                           FmcFineDelayTime(1, 0, 0),         # + 1s
                                           FmcFineDelayTime(1, 78125000, 0),  # + 1.0625s
                                           FmcFineDelayTime(1, 15625000, 0),  # + 1.125s
                                           FmcFineDelayTime(1, 31250000, 0),  # + 1.25s
                                           FmcFineDelayTime(1, 62500000, 0),  # + 1.5s
                                           FmcFineDelayTime(2, 0, 0),         # + 2s
                                           FmcFineDelayTime(60, 0, 0),        # + 60s
                                           FmcFineDelayTime(120, 0, 0),       # + 120s
                                           ])
    @pytest.mark.parametrize("wr", [False, True])
    @pytest.mark.parametrize("count", [1])
    @pytest.mark.parametrize("width,period", pulse_train)
    def test_output_input_start(self, fmcfd_chan, fmcfd_tdc,
                                wr, start_rel, width, period, count):
        """
        The output channel generates a pulse at a given time and the input
        channel timestamps it. The two times must be almost the same excluding
        the propagation time (cable length).
        """
        fmcfd_chan.dev.whiterabbit_mode = wr
        ts = []

        start = fmcfd_chan.dev.time + start_rel
        fmcfd_chan.pulse_generate(start, width, period, count)
        assert len(fmcfd_tdc.poll(int(float(start_rel) * 1000) + 2000)) > 0
        ts = fmcfd_tdc.read(count, os.O_NONBLOCK)
        assert len(ts) == count
        assert start.seconds == ts[0].seconds
        assert ts[0].coarse - start.coarse <= 3 # there is < 3ns cable


    @pytest.mark.parametrize("width,period_ps", [(200000, 1000000),
                                                (200000, 10000000),
                                                (200000, 100000000),
                                                (200000, 1000000000),
                                                (200000, 10000000000),
                                                (200000, 100000000000),
                                                (200000, 1000000000000),
                                                ])
    @pytest.mark.parametrize("count", [10])
    def test_output_period(self, fmcfd_chan, fmcfd_tdc,
                           width, period_ps, count):
        """
        The test produces pulses on the given channels and catch them using
        the on board TDC. The period between two timestamps must be as close
        as possible (ideally equal) to the period used to generate them.
        """
        ts = []

        start = fmcfd_chan.dev.time + FmcFineDelayTime(2, 0, 0, 0, 0)
        fmcfd_chan.pulse_generate(start, width, period_ps, count)
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
