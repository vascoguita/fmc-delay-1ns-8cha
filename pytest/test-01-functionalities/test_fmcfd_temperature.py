"""
SPDX-License-Identifier: GPL-3.0-or-later
SPDX-FileCopyrightText: 2020 CERN
"""

import pytest

class TestFmcfdTemperature(object):

    def test_temperature_read(self, fmcfd):
        assert 0 < fmcfd.temperature
