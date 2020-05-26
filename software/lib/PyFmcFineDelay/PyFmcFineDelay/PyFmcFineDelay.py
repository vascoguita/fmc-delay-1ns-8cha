"""
@package docstring
@author: Federico Vaga <federico.vaga@cern.ch>

SPDX-License-Identifier: LGPL-3.0-or-later
SPDX-FileCopyrightText: 2020 CERN  (home.cern)
"""

import atexit
import select
import errno
import time
import os

from ctypes import CDLL,\
                   c_uint64, c_uint32, c_int, c_void_p, c_char_p, c_float,\
                   pointer, POINTER, set_errno, get_errno,\
                   Structure


class FmcFineDelayTime(Structure):
    _fields_ = [
                ("seconds", c_uint64),
                ("coarse", c_uint32),
                ("frac", c_uint32),
                ("seq_id", c_uint32),
                ("channel", c_uint32),
                ]

    @classmethod
    def from_pico(cls, pico):
        tim = cls()
        pico_u64 = c_uint64(pico)
        libfdelay.fdelay_pico_to_time(pointer(pico_u64), pointer(tim))
        return tim

    def __str__(self):
        return "seconds: {:d}, coarse: {:d}, frac: {:d}, seq_id: {:d}, channel: {:d}".format(self.seconds, self.coarse, self.frac, self.seq_id, self.channel)

    def __float__(self):
        ts = self.seconds
        ts = ts + (self.coarse / 1000000000.0 * 8)
        ts = ts + ((self.frac * 7.999) / 4095) / 1000000000
        return ts

    def __add__(self, other):
        res = FmcFineDelayTime()
        res.seconds = 0
        res.coarse = 0
        res.frac = 0
        res.seq_id = -1
        res.channel = -1

        res.frac = self.frac + other.frac
        if res.frac >= 4096:
            res.frac -= 4096
            res.coarse += 1
        res.coarse += self.coarse + other.coarse
        if res.coarse >= 125000000:
            res.coarse -= 125000000
            res.seconds += 1
        res.seconds += self.seconds + other.seconds
        return res

    def __sub__(self, other):
        res = FmcFineDelayTime()
        res.seq_id = -1
        res.channel = -1

        frac = self.frac - other.frac
        if frac < 0:
            res.frac = frac + 4096
            carry = 1
        else:
            res.frac = frac
            carry = 0

        coarse = self.coarse - other.coarse - carry
        if coarse < 0:
            res.coarse = coarse + 125000000
            carry = 1
        else:
            res.coarse = coarse
            carry = 0
        res.seconds = self.seconds - other.seconds - carry

        return res

    def __gt__(self, other):
        if self.seconds > other.seconds:
            return True
        elif self.seconds < other.seconds:
            return False
        if self.coarse > other.coarse:
            return True
        elif self.coarse < other.coarse:
            return False
        if self.frac > other.frac:
            return True
        elif self.frac < other.frac:
            return False
        return False


class FmcFineDelayPulse(Structure):
    _fields_ = [
                ("mode", c_int),
                ("rep", c_int),
                ("start", FmcFineDelayTime),
                ("end", FmcFineDelayTime),
                ("loop", FmcFineDelayTime),
    ]


class FmcFineDelayPulsePs(Structure):
    _fields_ = [
                ("mode", c_int),
                ("rep", c_int),
                ("start", FmcFineDelayTime),
                ("length", c_uint64),
                ("period", c_uint64),
    ]


def errcheck_pointer(ret, func, args):
    """Generic error handler for functions returning pointers"""
    lib = CDLL("libfdelay.so", use_errno=True)
    if ret is None:
        raise OSError(get_errno(),
                      lib.fdelay_strerror(get_errno()),
                      "")
    else:
        return ret

def errcheck_int(ret, func, args):
    """Generic error checker for functions returning 0 as success
    and -1 as error"""
    lib = CDLL("libfdelay.so", use_errno=True)
    if ret < 0:
        raise OSError(get_errno(),
                      lib.fdelay_strerror(get_errno()),
                      "")
    else:
        return ret

def libfdelay_create():
    lib = CDLL("libfdelay.so", use_errno=True)

    lib.fdelay_init.argtypes = []
    lib.fdelay_init.restype = c_int
    lib.fdelay_init.errcheck = errcheck_int

    lib.fdelay_strerror.argtypes = [c_int]
    lib.fdelay_strerror.restype = c_char_p

    lib.fdelay_open.argtypes = [c_int]
    lib.fdelay_open.restype = c_void_p
    lib.fdelay_open.errcheck = errcheck_pointer

    lib.fdelay_close.argtypes = [c_void_p]
    lib.fdelay_close.restype = c_int
    lib.fdelay_close.errcheck = errcheck_int

    # Device
    lib.fdelay_read_temperature.argtypes = [c_void_p]
    lib.fdelay_read_temperature.restype = c_float

    lib.fdelay_wr_mode.argtypes = [c_void_p, c_int]
    lib.fdelay_wr_mode.restype = c_int
    lib.fdelay_wr_mode.errcheck = errcheck_int

    lib.fdelay_check_wr_mode.argtypes = [c_void_p]
    lib.fdelay_check_wr_mode.restype = c_int

    lib.fdelay_set_time.argtypes = [c_void_p, POINTER(FmcFineDelayTime)]
    lib.fdelay_set_time.restype = c_int
    lib.fdelay_set_time.errcheck = errcheck_int

    lib.fdelay_get_time.argtypes = [c_void_p, POINTER(FmcFineDelayTime)]
    lib.fdelay_get_time.restype = c_int
    lib.fdelay_get_time.errcheck = errcheck_int

    # Channel
    lib.fdelay_config_pulse.argtypes = [c_void_p, c_int,
                                        POINTER(FmcFineDelayPulse)]
    lib.fdelay_config_pulse.restype = c_int
    lib.fdelay_config_pulse.errcheck = errcheck_int

    lib.fdelay_config_pulse_ps.argtypes = [c_void_p, c_int,
                                           POINTER(FmcFineDelayPulsePs)]
    lib.fdelay_config_pulse_ps.restype = c_int
    lib.fdelay_config_pulse_ps.errcheck = errcheck_int

    lib.fdelay_get_config_pulse.argtypes = [c_void_p, c_int,
                                            POINTER(FmcFineDelayPulse)]
    lib.fdelay_get_config_pulse.restype = c_int
    lib.fdelay_get_config_pulse.errcheck = errcheck_int

    lib.fdelay_get_config_pulse_ps.argtypes = [c_void_p, c_int,
                                               POINTER(FmcFineDelayPulsePs)]
    lib.fdelay_get_config_pulse_ps.restype = c_int
    lib.fdelay_get_config_pulse_ps.errcheck = errcheck_int

    lib.fdelay_has_triggered.argtypes = [c_void_p, c_int]
    lib.fdelay_has_triggered.restype = c_int
    lib.fdelay_has_triggered.errcheck = errcheck_int

    # TDC
    lib.fdelay_set_config_tdc.argtypes = [c_void_p, c_int]
    lib.fdelay_set_config_tdc.restype = c_int
    lib.fdelay_set_config_tdc.errcheck = errcheck_int

    lib.fdelay_get_config_tdc.argtypes = [c_void_p]
    lib.fdelay_get_config_tdc.restype = c_int
    lib.fdelay_get_config_tdc.errcheck = errcheck_int

    lib.fdelay_fileno_tdc.argtypes = [c_void_p]
    lib.fdelay_fileno_tdc.restype = c_int
    lib.fdelay_fileno_tdc.errcheck = errcheck_int

    lib.fdelay_read.argtypes = [c_void_p, POINTER(FmcFineDelayTime),
                                c_int, c_int]
    lib.fdelay_read.restype = c_int
    lib.fdelay_read.errcheck = errcheck_int

    lib.fdelay_fread.argtypes = [c_void_p, POINTER(FmcFineDelayTime), c_int]
    lib.fdelay_fread.restype = c_int
    lib.fdelay_fread.errcheck = errcheck_int

    # util
    lib.fdelay_pico_to_time.argtypes = [POINTER(c_uint64),
                                        POINTER(FmcFineDelayTime)]

    lib.fdelay_time_to_pico.argtypes = [POINTER(FmcFineDelayTime),
                                        POINTER(c_uint64)]

    return lib


libfdelay = libfdelay_create()


def libfdelay_load():
    libfdelay.fdelay_init()


def libfdelay_unload():
    libfdelay.fdelay_exit()


atexit.register(libfdelay_unload)


class FmcFineDelay(object):
    """
    It is a Python class that represent an FMC Fine Delay device

    :param devid: FMC Fine Delay device identifier

    :ivar device_id: device ID associated with the instance
    :ivar tkn: device token to be used with the libfmcfd library
    """

    CHANNEL_NUMBER = 4

    class FmcFineDelayChannel(object):

        OUT_MODE_DISABLED = 0
        OUT_MODE_DELAY = 1
        OUT_MODE_PULSE = 2

        OUT_PULSE_MAX_COUNT = 0xFFFF
        OUT_PULSE_MIN_WIDTH_PS = 50000
        OUT_PULSE_MIN_PERIOD_PS = 100000
        OUT_PULSE_MAX_WIDTH_PS = 1000000000000
        OUT_PULSE_MAX_PERIOD_PS = 2000000000000
        OUT_PULSE_DELAY_MIN_WIDTH_PS = 250000
        OUT_PULSE_DELAY_MIN_PERIOD_PS = 500000
        OUT_PULSE_DELAY_MAX_WIDTH_PS = 1000000000000
        OUT_PULSE_DELAY_MAX_PERIOD_PS = 2000000000000

        def __init__(self, dev, channel):
            self.dev = dev
            self.tkn = self.dev.tkn
            self.idx = channel

        @property
        def triggered(self):
            return libfdelay.fdelay_has_triggered(self.tkn, self.idx) == 1

        @property
        def disabled(self):
            mode = self.pulse_config_raw.mode & 0x7F
            return mode == self.OUT_MODE_DISABLED

        def disable(self):
            cfg = FmcFineDelayPulse()
            cfg.mode = self.OUT_MODE_DISABLED
            cfg.rep = 1
            cfg.end.seconds = 0
            cfg.start.coarse = 75
            cfg.start.frac = 0
            cfg.end.seconds = 0
            cfg.end.coarse = 125
            cfg.end.frac = 0
            cfg.loop.seconds = 1
            cfg.loop.coarse = 0
            cfg.loop.frac = 0
            self.pulse_config_raw = cfg

        def pulse_delay(self, delay, width, period, count):
            if count > self.OUT_PULSE_MAX_COUNT:
                raise OSError(errno.EINVAL,
                              "'count' can be maximum {:d}".format(self.OUT_PULSE_MAX_COUNT))
            if width < self.OUT_PULSE_DELAY_MIN_WIDTH_PS or \
               width > self.OUT_PULSE_DELAY_MAX_WIDTH_PS:
                raise OSError(errno.EINVAL,
                              "'width' must be in range [{:d}, {:d}]ps".format(self.OUT_PULSE_DELAY_MIN_WIDTH_PS,
                                                                               self.OUT_PULSE_DELAY_MAX_WIDTH_PS))
            if period < self.OUT_PULSE_DELAY_MIN_PERIOD_PS or \
               period > self.OUT_PULSE_DELAY_MAX_PERIOD_PS:
                raise OSError(errno.EINVAL,
                              "'period' must be in range [{:d}, {:d}]ps".format(self.OUT_PULSE_DELAY_MIN_PERIOD_PS,
                                                                                self.OUT_PULSE_DELAY_MAX_PERIOD_PS))
            start = FmcFineDelayTime()
            delay_u64 = c_uint64(delay)
            libfdelay.fdelay_pico_to_time(pointer(delay_u64),
                                          pointer(start))
            cfg = FmcFineDelayPulsePs()
            cfg.mode = self.OUT_MODE_DELAY
            cfg.rep = count
            cfg.start = start
            cfg.length = width
            cfg.period = period
            self.pulse_config_ps_raw = cfg

        def pulse_generate(self, start, width, period, count):
            if count > self.OUT_PULSE_MAX_COUNT:
                raise OSError(errno.EINVAL,
                              "'count' can be maximum {:d}".format(self.OUT_PULSE_MAX_COUNT))
            if width < self.OUT_PULSE_MIN_WIDTH_PS or \
               width > self.OUT_PULSE_MAX_WIDTH_PS:
                raise OSError(errno.EINVAL,
                              "'width' must be in range [{:d}, {:d}]ps".format(self.OUT_PULSE_MIN_WIDTH_PS,
                                                                               self.OUT_PULSE_MAX_WIDTH_PS))
            if period < self.OUT_PULSE_MIN_PERIOD_PS or \
               period > self.OUT_PULSE_MAX_PERIOD_PS:
                raise OSError(errno.EINVAL,
                              "'period' must be in range [{:d}, {:d}]ps".format(self.OUT_PULSE_MIN_PERIOD_PS,
                                                                                self.OUT_PULSE_MAX_PERIOD_PS))
            p = c_uint64(period)
            cfg = FmcFineDelayPulse()
#            cfg = FmcFineDelayPulsePs()
            cfg.mode = self.OUT_MODE_PULSE
            cfg.rep = count
            cfg.start = start
            libfdelay.fdelay_pico_to_time(pointer(c_uint64(width)),
                                          pointer(cfg.end))
            cfg.end += start
#            cfg.length = width
            libfdelay.fdelay_pico_to_time(pointer(c_uint64(period)),
                                          pointer(cfg.loop))
#            cfg.period = period
            self.pulse_config_raw = cfg
#            self.pulse_config_ps_raw = cfg

        @property
        def status(self):
            return self.pulse_config_ps_raw

        @property
        def pulse_config_raw(self):
            cfg = FmcFineDelayPulse()
            libfdelay.fdelay_get_config_pulse(self.tkn, self.idx, pointer(cfg))
            return cfg

        @pulse_config_raw.setter
        def pulse_config_raw(self, cfg):
            libfdelay.fdelay_config_pulse(self.tkn, self.idx, pointer(cfg))

        @property
        def pulse_config_ps_raw(self):
            cfg = FmcFineDelayPulsePs()
            libfdelay.fdelay_get_config_pulse_ps(self.tkn, self.idx,
                                                 pointer(cfg))
            return cfg

        @pulse_config_ps_raw.setter
        def pulse_config_ps_raw(self, cfg):
            libfdelay.fdelay_config_pulse_ps(self.tkn, self.idx, pointer(cfg))

    class FmcFineDelayTDC(object):

        TDC_FLAG_INPUT_DISABLE = 0x1
        TDC_FLAG_TSTAMP_DISABLE = 0x2
        TDC_FLAG_TERM_ENABLE = 0x4
        TDC_FLAG_MASK = TDC_FLAG_INPUT_DISABLE |\
                        TDC_FLAG_TSTAMP_DISABLE |\
                        TDC_FLAG_TERM_ENABLE

        def __init__(self, tkn):
            self.tkn = tkn
            self.poll_desc = select.poll()
            self.poll_desc.register(self.fileno, select.POLLIN)

        @property
        def enable_input(self):
            return not bool(self.__config_get() & self.TDC_FLAG_INPUT_DISABLE)

        @enable_input.setter
        def enable_input(self, val):
            old = self.__config_get()
            if val:
                old &= ~self.TDC_FLAG_INPUT_DISABLE
            else:
                old |= self.TDC_FLAG_INPUT_DISABLE
            self.__config_set(old)

        @property
        def enable_tstamp(self):
            return not bool(self.__config_get() & self.TDC_FLAG_TSTAMP_DISABLE)

        @enable_tstamp.setter
        def enable_tstamp(self, val):
            old = self.__config_get()
            if val:
                old &= ~self.TDC_FLAG_TSTAMP_DISABLE
            else:
                old |= self.TDC_FLAG_TSTAMP_DISABLE
            self.__config_set(old)

        @property
        def termination(self):
            return bool(self.__config_get() & self.TDC_FLAG_TERM_ENABLE)

        @termination.setter
        def termination(self, val):
            old = self.__config_get()
            if val:
                old |= self.TDC_FLAG_TERM_ENABLE
            else:
                old &= ~self.TDC_FLAG_TERM_ENABLE
            self.__config_set(old)

        @property
        def fileno(self):
            return libfdelay.fdelay_fileno_tdc(self.tkn)

        def __config_get(self):
            return libfdelay.fdelay_get_config_tdc(self.tkn)

        def __config_set(self, flags):
            return libfdelay.fdelay_set_config_tdc(self.tkn, flags)

        def poll(self, timeout=10):
            return self.poll_desc.poll(timeout)

        def read(self, n=1, flags=0):
            ts = (FmcFineDelayTime * n)()
            ret = libfdelay.fdelay_read(self.tkn, ts, n, flags)
            return list(ts)[:ret]

        def fread(self, n=1, flags=0):
            ts = (FmcFineDelayTime * n)()
            ret = libfdelay.fdelay_fread(self.tkn, ts, n, flags)
            return list(ts)[:ret]

        def flush(self):
            while True:
                try:
                    if len(self.read(1024, os.O_NONBLOCK)) == 0:
                        break
                except OSError:
                    break

    def __init__(self, devid):
        if devid is None:
            raise Exception("Invalid device ID")
        self.device_id = devid
        libfdelay.fdelay_init()
        set_errno(0)
        self.tkn = libfdelay.fdelay_open(self.device_id)

        self.chan = []
        for i in range(self.CHANNEL_NUMBER):
            self.chan.append(self.FmcFineDelayChannel(self, i))
        self.tdc = self.FmcFineDelayTDC(self.tkn)

    def __del__(self):
        if hasattr(self, 'tkn'):
            libfdelay.fdelay_close(self.tkn)
        libfdelay.fdelay_exit()

    @property
    def temperature(self):
        return libfdelay.fdelay_read_temperature(self.tkn)

    @property
    def time(self):
        ts = FmcFineDelayTime()
        libfdelay.fdelay_get_time(self.tkn, pointer(ts))
        return ts

    @time.setter
    def time(self, val):
        libfdelay.fdelay_set_time(self.tkn, pointer(val))

    @property
    def whiterabbit_mode(self):
        ret = libfdelay.fdelay_check_wr_mode(self.tkn)
        if ret == 0:
            return True
        elif ret == errno.ENODEV or \
             ret == errno.ENOLINK or \
             ret == errno.EAGAIN:
            return False
        else:
            raise OSError(get_errno(),
                          libfdelay.fdelay_strerror(get_errno()),
                          "")

    @whiterabbit_mode.setter
    def whiterabbit_mode(self, val):
        ret = libfdelay.fdelay_wr_mode(self.tkn, int(val))
        if ret == errno.ENOTSUP:
            raise OSError(ret,
                          libfdelay.fdelay_strerror(get_errno()),
                          "")

        end = time.time() + 30
        timeout = True
        while time.time() < end:
            time.sleep(0.1)
            ret = libfdelay.fdelay_check_wr_mode(self.tkn)
            if val and ret == 0:
                timeout = False
                break
            if not val and ret == errno.ENODEV:
                timeout = False
                break
        if timeout:
            raise OSError(get_errno(), libfdelay.fdelay_strerror(get_errno()),
                          "")
