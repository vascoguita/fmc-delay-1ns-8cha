"""
SPDX-License-Identifier: GPL-3.0-or-later
SPDX-FileCopyrightText: 2020 CERN
"""

import pytest
from PyFmcFineDelay import FmcFineDelay


@pytest.fixture(scope="function")
def fmcfd():
    fd =  FmcFineDelay(pytest.fd_id)
    yield fd
    for chan in fd.chan:
        chan.disable()

def pytest_addoption(parser):
    parser.addoption("--fd-id", type=lambda x : int(x, 16),
                     required=True, help="Fmc Fine-Delay Linux Identifier")
    parser.addoption("--channel", type=int, default=[],
                     action="append", choices=range(FmcFineDelay.CHANNEL_NUMBER),
                     help="Channel(s) to be used for acquisition tests. Default all channels")

def pytest_configure(config):
    pytest.fd_id = config.getoption("--fd-id")
    pytest.channels = config.getoption("--channel")
    if len(pytest.channels) == 0:
        pytest.channels = range(FmcFineDelay.CHANNEL_NUMBER)
