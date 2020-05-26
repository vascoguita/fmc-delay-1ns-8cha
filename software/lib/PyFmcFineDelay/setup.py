#!/usr/bin/env python

"""
SPDX-License-Identifier: CC0-1.0
SPDX-FileCopyrightText: 2020 CERN
"""

from distutils.core import setup

setup(name='PyFmcTdc',
      version='3.0',
      description='Python Module to handle FMC Fine Delay devices',
      author='Federico Vaga',
      author_email='federico.vaga@cern.ch',
      maintainer="Federico Vaga",
      maintainer_email="federico.vaga@cern.ch",
      url='https://www.ohwr.org/project/fmc-delay-1ns-8cha',
      packages=['PyFmcFineDelay'],
      license='LGPL-3.0-or-later',
     )
