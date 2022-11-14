#!/usr/bin/env python

# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: LGPL-2.1-or-later


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
      license='LGPL-2.1-or-later',
     )
