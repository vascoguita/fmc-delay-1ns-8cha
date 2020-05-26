"""
SPDX-License-Identifier: GPL-3.0-or-later
SPDX-FileCopyrightText: 2020 CERN
"""

import pytest
import random
import time
from PyFmcFineDelay import FmcFineDelay, FmcFineDelayTime

@pytest.fixture(scope="function", params=pytest.channels)
def fmcfd_chan(request):
    fd = FmcFineDelay(pytest.fd_id)
    fd.tdc.enable_input = False
    fd.tdc.enable_tstamp = False
    fd.tdc.termination = False
    fd.chan[request.param].disable()
    yield fd.chan[request.param]
    fd.chan[request.param].disable()


class TestFmcfdOutput(object):

    def __print_configuration(self, chan, delay, width, period, count):
        print("configuration")
        print("  channel: {:d}".format(chan))
        print("  delay  : {:d}ps".format(delay))
        print("  width  : {:d}ps".format(width))
        print("  period : {:d}ps".format(period))
        print("  count  : {:d}".format(count))

    @pytest.mark.parametrize("width",[50000,  # 50ns
                                      60000,  # 60ns
                                      70000,  # 70ns
                                      80000,  # 80ns
                                      90000,  # 90ns
                                      500000,  # 500ns
                                      1000000,  # 1us
                                      500000000,  # 500us
                                      1000000000,  # 1ms
                                      500000000000,  # 500ms
                                      1000000000000,  # 1s
                                      ])
    @pytest.mark.parametrize("count", [1, 3])
    def test_pulse_width(self, capsys, fmcfd_chan, width, count):
        with capsys.disabled():
            print("")
            print("This test needs an external oscilloscope to monitor pulses produced by the fine delay")
            print("1. connect a lemo cable from the fine-delay channel {:d} to the oscilloscope;".format(fmcfd_chan.idx + 1))
            print("2. set up the oscilloscope to catch the pulse(s)")
            input("Press any key to start").lower()

        while True:
            start = fmcfd_chan.dev.time + FmcFineDelayTime(1, 0, 0)
            fmcfd_chan.pulse_generate(start, width, width * 2, count)
            ret = self.__process_outcome(fmcfd_chan.idx + 1, 0,
                                         width, width * 2, count)
            if ret in ["y", "n", "q"]:
                break
        if ret == "q":
            pytest.skip("Quit test")
        assert ret == "y"

    @pytest.mark.parametrize("delay", [600000,  # 600ns
                                       1000000,  # 1us
                                       500000000,  # 500us
                                       1000000000,  # 1ms
                                       500000000000,  # 500ms
                                       1000000000000,  # 1s
                                       10000000000000,  # 10s
                                       120000000000000  # 120s
                                       ])
    def test_pulse_delay_start(self, capsys, fmcfd_chan, delay):
        fmcfd_chan.dev.tdc.enable_input = True
        with capsys.disabled():
            print("")
            print("For this test you need: a pulse-generator, an oscilloscope")
            print("1. connect a lemo cable from the fine-delay channel {:d} to the oscilloscope;".format(fmcfd_chan.idx + 1))
            print("2. connect a lemo cable from the pulse generator to the fine-delay trigger input;")
            print("3. connect a lemo cable from the pulse generator to the oscilloscope;")
            print("4. Configure the pulse generator at 1Hz")
            print("5. set up the oscilloscope to catch the pulse(s)")
            input("Press any key to start").lower()

        while True:
            fmcfd_chan.pulse_delay(delay, 250000, 500000, 1)
            time.sleep(1 + delay/1000000000000.0)
            ret = self.__process_outcome(fmcfd_chan.idx + 1, delay, 250000, 500000, 1)
            if ret in ["y", "n", "q"]:
                break
        if ret == "q":
            pytest.skip("Quit test")
        assert ret == "y"

    @pytest.mark.parametrize("width",[250000,  # 250ns
                                      260000,  # 260ns
                                      270000,  # 270ns
                                      280000,  # 280ns
                                      290000,  # 290ns
                                      500000,  # 500ns
                                      1000000,  # 1us
                                      500000000,  # 500us
                                      1000000000,  # 1ms
                                      500000000000,  # 500ms
                                      1000000000000,  # 1s
                                      ])
    @pytest.mark.parametrize("count", [1, 3])
    def test_pulse_delay_width(self, capsys, fmcfd_chan, width, count):
        fmcfd_chan.dev.tdc.enable_input = True
        with capsys.disabled():
            print("")
            print("For this test you need: a pulse-generator, an oscilloscope")
            print("1. connect a lemo cable from the fine-delay channel {:d} to the oscilloscope;".format(fmcfd_chan.idx + 1))
            print("2. connect a lemo cable from the pulse generator to the fine-delay trigger input;")
            print("3. connect a lemo cable from the pulse generator to the oscilloscope;")
            print("4. Configure the pulse generator at 1Hz")
            print("5. set up the oscilloscope to catch the pulse(s)")
            input("Press any key to start").lower()

        while True:
            fmcfd_chan.pulse_delay(width, width, 500000, 1)
            time.sleep(1 + delay/1000000000000.0)
            ret = self.__process_outcome(fmcfd_chan.idx + 1, 600000, width, 500000, 1)
            if ret in ["y", "n", "q"]:
                break
        if ret == "q":
            pytest.skip("Quit test")
        assert ret == "y"

    def __process_outcome(chan, start, width, period, count):
        while True:
            with capsys.disabled():
                self.__print_configuration(chan, start, width, period, count)
                a = input("Did you see it on the oscilloscope? [Y/N/R/Q]").lower()[0]
            if a in ["y", "n", "r", "q"]:
                break
        return a
