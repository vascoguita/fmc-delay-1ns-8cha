#!/usr/bin/python

from ctypes import *
import sys
import re
import os

class fd_timestamp(Structure):
	_fields_ = [("utc", c_ulonglong),
                    ("coarse", c_ulong),
                    ("frac", c_ulong),
                    ("seq_id", c_ushort),
                    ("channel", c_int)]

	def nsecs(self):
		return (float(self.frac) * 8000.0 / 4096.0 + float(self.coarse) * 8000.0) / 1000.0;

	def nsecs_full(self):
		return (float(self.frac) * 8000.0 / 4096.0 + float(self.coarse) * 8000.0) / 1000.0 + float(self.utc) * 1000000000.0;

	def __str__(self):
		return "%d:%d" % (self.utc, self.nsecs())

class FineDelay:

    SYNC_LOCAL = 1
    SYNC_WR = 2
		
    def __init__(self, location="udp/192.168.10.11"):
        self.fdelay = CDLL('../lib/libfinedelay.so')

	
        self.handle = self.fdelay.fdelay_create();
        
        if(self.fdelay.fdelay_probe(self.handle, c_char_p(location)) < 0):
            print ("FD enumeration failed")
            sys.exit(-1)

        print "Initializing Fine Delay board..."
        if(self.fdelay.fdelay_init(self.handle) < 0):
            print ("Init failed..");
            sys.exit(-1)

    def conf_trigger(self, enable, termination):
        self.fdelay.fdelay_configure_trigger(self.handle, c_int(enable), c_int(termination))

    def conf_output(self, channel, enable, delay, width):
        self.fdelay.fdelay_configure_output(self.handle, c_int(channel), c_int(enable), c_ulonglong(delay), c_ulonglong(width), c_ulonglong(200000), c_int(1))

    def conf_readout(self, enable):
        self.fdelay.fdelay_configure_readout(self.handle, enable)

    def conf_sync(self, mode):
      self.fdelay.fdelay_configure_sync(self.handle, mode)

#        def conf_pulsegen(self, channel, enable, t_start_utc, t_start_coarse, width, delta, count):
#                t = fd_timestamp(utc=c_ulonglong(t_start_utc), coarse=c_ulong(t_start_coarse))
#                #print "channel:%d  enable:%d  start_t:%d  width:%d  delta:%d  count:%d"%(channel, enable, t.utc, width, delta, count)
#                self.fdelay.fdelay_configure_pulse_gen(self.handle, c_int(channel), c_int(enable), t,
#                                                   c_ulonglong(width), c_ulonglong(delta), c_int(count))

#        def set_time(self, utc, coarse):
#                t = fd_timestamp(utc=c_ulonglong(utc), coarse=c_ulong(coarse))
#                self.fdelay.fdelay_set_time(self.handle, t)

#        def get_time(self):
#                t = fd_timestamp()
#                self.fdelay.fdelay_get_time(self.handle, byref(t))
#                return t

    def get_sync_status(self):
      c = self.fdelay.fdelay_check_sync(self.handle)
      if(c):
    		return "synced"
      else:
    		return "not synced"

    def read_ts(self):
    	buf = (fd_timestamp * 256)();
    	ptr = pointer(buf)
    	n = self.fdelay.fdelay_read(self.handle, ptr, 256)
    	arr = [];
    	for i in range(0,n):
    		arr.append(buf[i])
    	return arr
