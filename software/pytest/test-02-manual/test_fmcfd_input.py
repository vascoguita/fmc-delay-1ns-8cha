"""
SPDX-License-Identifier: LGPL-2.1-or-later
SPDX-FileCopyrightText: 2020 CERN
"""

import pytest
import random
import select
import time
import os
from PyFmcFineDelay import FmcFineDelay, FmcFineDelayTime

@pytest.fixture(scope="function", params=pytest.channels)
def fmcfd_tdc(request):
    fd = FmcFineDelay(pytest.fd_id)
    fd.tdc.enable_input = False
    fd.tdc.enable_tstamp = False
    fd.tdc.termination = False
    for ch in fd.chan:
        ch.disable()
    yield fd.tdc
    fd.tdc.enable_input = False
    fd.tdc.enable_tstamp = False
    for ch in fd.chan:
        ch.disable()


class TestFmcfdInput(object):

    @pytest.mark.parametrize("hz", [1, 10, 100, 1000, 10000])
    def test_tdc_burst_manual(self, capsys, fmcfd_tdc, hz):
        count = 1000
        pending = count
        prev_ts = None

        fmcfd_tdc.enable_tstamp = True
        fmcfd_tdc.enable_input = True
        poll = select.poll()
        poll.register(fmcfd_tdc.fileno, select.POLLIN)
        ts = []
        with capsys.disabled():
            print("")
            print("This test needs an external pulse generator that you manually configure according to the following instructions")
            print("1. connect a lemo cable from the pulse generator to the fine-delay trigger input;")
            print("2. configure the pulse generator to produce a {:d}Hz burst of {:d} pulses;".format(hz, count))
            while True:
                a = input("Ready to start? [Y/N]").lower()
                if a == 'y' or a == 'n':
                    break
            assert a == "y"
            print("### Trigger the burst of pulses and wait for the test to complete (timeout 1 minute)###")

        timeout = time.time() + 60
        while pending > 0:
            t = time.time()
            if t >= timeout:
                break
            ret = poll.poll(1)
            if len(ret) == 0:
                continue
            t = fmcfd_tdc.read(pending, os.O_NONBLOCK)
            assert len(t) > 0
            ts = ts + t
            pending -= len(t)

        import pdb
        pdb.set_trace()
        for i in  range(len(ts)):
            if prev_ts is not None:
                assert ts[i].seq_id == prev_ts.seq_id + 1
                diff = float(ts[i]) - float(prev_ts)
                assert hz == int(1 / diff)
            prev_ts = ts[i]
