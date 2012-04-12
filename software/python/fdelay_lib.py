#!/usr/bin/python

from ctypes import *
import sys
import re

class fd_timestamp(Structure):
	_fields_ = [("utc", c_ulong),
				("coarse", c_ulong),
				("frac", c_ulong),
				("seq_id", c_ushort)]

	def nsecs(self):
		return (float(self.frac) * 8000.0 / 4096.0 + float(self.coarse) * 8000.0) / 1000.0;

	def nsecs_full(self):
		return (float(self.frac) * 8000.0 / 4096.0 + float(self.coarse) * 8000.0) / 1000.0 + float(self.utc) * 1000000000.0;

	def __str__(self):
		return "%d:%d" % (self.utc, self.nsecs())

class FineDelay:

	FREE_RUNNING = 0x10
	WR_OFFLINE =  0x8
	WR_READY  =  0x1
	WR_SYNCING =  0x2
	WR_SYNCED = 0x4
	SYNC_LOCAL = 0x1
	SYNC_WR = 0x2

	def __init__(self, dev_path):
		s = re.split("\/", dev_path)
		self.fd = CDLL('../lib/libfinedelay.so')
		if(s[0] == "local"):
			print("Initializing local at %x" % int(s[1], 16))
			self.handle = c_voidp(self.fd.fdelay_create_rawrabbit(int(s[1],16)));
		elif(s[0] == "minibone"):
			print("Initializing minibone at %s [%s]\n" %( s[1], s[2]))
			self.handle = c_voidp(self.fd.fdelay_create_minibone(c_char_p(s[1]), c_char_p(s[2]), int(s[3], 16)));

		if(self.fd.fdelay_init(self.handle) < 0):
			print ("Init failed..");
#			sys.exit(-1)

	def conf_trigger(self, enable, termination):
		self.fd.fdelay_configure_trigger(self.handle, c_int(enable), c_int(termination))
	
	def conf_output(self, channel, enable, delay, width):
		self.fd.fdelay_configure_output(self.handle, c_int(channel), c_int(enable), c_ulonglong(delay), c_ulonglong(width))
	
	def conf_readout(self, enable):
		self.fd.fdelay_configure_readout(self.handle, enable)
	
	def conf_sync(self, mode):
		self.fd.fdelay_configure_sync(self.handle, mode)
	
	def get_sync_status(self):
		htab = { self.FREE_RUNNING : "oscillator free-running",
				 self.WR_OFFLINE : "WR core offline",
				 self.WR_READY : "WR core ready",
				 self.WR_SYNCING : "Syncing local clock with WR",
				 self.WR_SYNCED : "Synced with WR" }
#		status = c_int(self.fd.fdelay_get_sync_status(self.handle));
#		print("GetSyncStatus %x" % status.value);
		return "none"; #htab[status.value]
		
	def read_ts(self):
		buf = (fd_timestamp * 256)();
		ptr = pointer(buf)
		n = self.fd.fdelay_read(self.handle, ptr, 256)
		arr = [];
		for i in range(0,n):
			arr.append(buf[i])
		return arr
