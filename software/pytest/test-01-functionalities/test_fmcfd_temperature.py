"""
SPDX-License-Identifier: LGPL-2.1-or-later
SPDX-FileCopyrightText: 2020 CERN
"""

import pytest

class TestFmcfdTemperature(object):

    def test_temperature_read(self, fmcfd):
        assert 0 < fmcfd.temperature
