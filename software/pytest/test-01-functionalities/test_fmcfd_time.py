"""
SPDX-License-Identifier: LGPL-2.1-or-later
SPDX-FileCopyrightText: 2020 CERN
"""

import pytest
import random
import time
from PyFmcFineDelay import FmcFineDelayTime

class TestFmcfdTime(object):

    def test_whiterabbit_mode(self, fmcfd):
        """It must be possible to toggle the White-Rabbit status"""
        fmcfd.whiterabbit_mode = True
        assert fmcfd.whiterabbit_mode == True
        fmcfd.whiterabbit_mode = False
        assert fmcfd.whiterabbit_mode == False

    def test_time_set_fail_wr(self, fmcfd):
        """Time can't be changed when White-Rabbit is enabled"""
        fmcfd.whiterabbit_mode = True
        with pytest.raises(OSError):
            fmcfd.time = FmcFineDelayTime(10, 0, 0, 0, 0)

    @pytest.mark.parametrize("t", random.sample(range(1000000), 10))
    def test_time_set(self, fmcfd, t):
        """Time can be changed when White-Rabbit is disabled"""
        fmcfd.whiterabbit_mode = False
        t_base = FmcFineDelayTime(t, 0, 0, 0, 0)
        fmcfd.time = t_base
        assert t_base.seconds == fmcfd.time.seconds

    @pytest.mark.parametrize("whiterabbit", [False, True])
    def test_time_flows(self, fmcfd, whiterabbit):
        """Just check that the time flows more or less correctly second by
        second for a minute"""
        fmcfd.whiterabbit_mode = whiterabbit
        for i in range(20):
            t_prev = fmcfd.time.seconds
            time.sleep(1)
            assert t_prev + 1 == fmcfd.time.seconds
