"""
SPDX-License-Identifier: GPL-3.0-or-later
SPDX-FileCopyrightText: 2020 CERN
"""

import pytest
import random
from PyFmcFineDelay import FmcFineDelay, FmcFineDelayTime



@pytest.fixture(scope="function", params=range(0, FmcFineDelay.CHANNEL_NUMBER))
def fmcfd_chan(request):
    fd = FmcFineDelay(pytest.fd_id)
    yield fd.chan[request.param]

class TestFmcfdGetterSetter(object):

    def test_disable(self, fmcfd):
        for chan in fmcfd.chan:
            chan.disable()
            assert chan.disabled == True

    @pytest.mark.parametrize("enable", [True, False])
    def test_tdc_disable_input(self, fmcfd, enable):
        fmcfd.tdc.enable_input = enable
        assert fmcfd.tdc.enable_input == enable

    @pytest.mark.parametrize("enable", [True, False])
    def test_tdc_disable_tstamp(self, fmcfd, enable):
        fmcfd.tdc.enable_tstamp = enable
        assert fmcfd.tdc.enable_tstamp == enable

    @pytest.mark.parametrize("term", [True, False])
    def test_tdc_termination(self, fmcfd, term):
        """Set temination and read it back"""
        fmcfd.tdc.termination = term
        assert term == fmcfd.tdc.termination

    @pytest.mark.parametrize("width,period,count", [(FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MIN_WIDTH_PS,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MIN_PERIOD_PS,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MAX_COUNT + 1),
                                                    (FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MIN_WIDTH_PS - 1,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MIN_PERIOD_PS,
                                                     1),
                                                    (FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MAX_WIDTH_PS + 1,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MAX_PERIOD_PS,
                                                     1),
                                                    (FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MIN_WIDTH_PS,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MIN_PERIOD_PS - 1,
                                                     1),
                                                    (FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MAX_WIDTH_PS,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MAX_PERIOD_PS + 1,
                                                     1),
                                                     ])
    def test_pulse_delay_invalid(self, fmcfd_chan, width, period, count):
        """The pulse generation can't work with invalid parameters"""
        with pytest.raises(OSError):
            fmcfd_chan.pulse_delay(FmcFineDelayTime(1, 0, 0),
                                   width, period, count)

    @pytest.mark.parametrize("width,period,count", [(FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MIN_WIDTH_PS,
                                                    FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_DELAY_MIN_PERIOD_PS,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MAX_COUNT + 1),
                                                    (FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MIN_WIDTH_PS,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MIN_PERIOD_PS,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MAX_COUNT + 1),
                                                    (FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MIN_WIDTH_PS - 1,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MIN_PERIOD_PS,
                                                     1),
                                                    (FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MAX_WIDTH_PS + 1,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MAX_PERIOD_PS,
                                                     1),
                                                    (FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MIN_WIDTH_PS,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MIN_PERIOD_PS - 1,
                                                     1),
                                                    (FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MAX_WIDTH_PS,
                                                     FmcFineDelay.FmcFineDelayChannel.OUT_PULSE_MAX_PERIOD_PS + 1,
                                                     1),
                                                     ])
    def test_pulse_generate_invalid(self, fmcfd_chan, width, period, count):
        """The pulse generation can't work with invalid parameters"""
        with pytest.raises(OSError):
            fmcfd_chan.pulse_generate(FmcFineDelayTime(1, 0, 0),
                                   width, period, count)
