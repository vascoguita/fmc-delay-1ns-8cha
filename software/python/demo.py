#!/usr/bin/python2

import sys
import PyQt4
import PyQt4.QtGui
import PyQt4.QtCore
import PyQt4.uic
from PyQt4.QtGui import *
from PyQt4.QtCore import *
from fdelay_lib import FineDelay

FormClass = PyQt4.uic.loadUiType('fd_demo.ui')[0]

class MainWindow(QMainWindow, FormClass):
	def __init__(self):
		super(MainWindow, self).__init__()
		self.setupUi(self)
#		self.setWindowTitle("ion")

	

def channel_update(channel):
	print("UpdateCh: %d" % channel)
	en = ch_enable[channel-1].checkState();
	dly = int(ch_nsec[channel-1].value() * 1000 + (ch_sec[channel-1].value() * 1000000000000))
	w = int(ch_width[channel-1].value() * 1000)
	card.conf_output(channel, en, dly, w) 
	

def trigger_update():
	card.conf_trigger(m.en_trigger.checkState(), m.en_term.checkState())
	
def on_ts_enable_disable():
	print("ontsen")
	card.conf_readout(m.en_ts.checkState())

prev_ts = 0
	
def on_ts_clear():
	print("ontabclear")
	poll_timer.stop()
	for i in range(0, m.ts_table.rowCount()):
		m.ts_table.removeRow(i)
	prev_ts = 0
	poll_timer.start()

def poll_timer_cb():
	buf = card.read_ts()
	for ts in buf:
		global prev_ts
		row = m.ts_table.rowCount()
		m.ts_table.insertRow(row)
		m.ts_table.setItem(row, 0, QTableWidgetItem("%d"%ts.seq_id))
		m.ts_table.setItem(row, 1, QTableWidgetItem("%d"%ts.utc))
		m.ts_table.setItem(row, 2, QTableWidgetItem("%.3f"%ts.nsecs()))
		m.ts_table.setItem(row, 3, QTableWidgetItem("%.3f"%(ts.nsecs_full()-prev_ts)))
		prev_ts = ts.nsecs_full()
#		i = QTableWidgetItem()
		m.ts_table.scrollToBottom()
	m.wr_status.setText(card.get_sync_status())


def on_chk_wr():
	if(m.wr_checkbox.checkState()):
		card.conf_sync(card.SYNC_WR)
	else:
		card.conf_sync(card.SYNC_LOCAL)


if __name__ == "__main__":
	app = QApplication(sys.argv)
	if(sys.argv[1] == "1"):
		location = "minibone/eth0/00:50:0c:de:bc:f8/0x100000"
	else:
		location = "minibone/eth0/00:50:e4:95:36:f8/0x100000"
	
	m = MainWindow()
	m.show()
	m.setWindowTitle("Fine Delay Demo @ %s" % location)
	card = FineDelay(location)
	m.wr_status.setText("")
	ch_enable = [m.en_ch1, m.en_ch2, m.en_ch3, m.en_ch4];
	ch_nsec = [m.nsec_ch1, m.nsec_ch2, m.nsec_ch3, m.nsec_ch4];
	ch_sec = [m.sec_ch1, m.sec_ch2, m.sec_ch3, m.sec_ch4];
	ch_width = [m.width_ch1, m.width_ch2, m.width_ch3, m.width_ch4];
	for i in range(1,5):
		channel_update(i)

	ch_enable[0].stateChanged.connect(lambda :channel_update(1))
	ch_enable[1].stateChanged.connect(lambda :channel_update(2))
	ch_enable[2].stateChanged.connect(lambda :channel_update(3))
	ch_enable[3].stateChanged.connect(lambda :channel_update(4))
	ch_nsec[0].valueChanged.connect(lambda :channel_update(1))
	ch_nsec[1].valueChanged.connect(lambda :channel_update(2))
	ch_nsec[2].valueChanged.connect(lambda :channel_update(3))
	ch_nsec[3].valueChanged.connect(lambda :channel_update(4))
	ch_sec[0].valueChanged.connect(lambda :channel_update(1))
	ch_sec[1].valueChanged.connect(lambda :channel_update(2))
	ch_sec[2].valueChanged.connect(lambda :channel_update(3))
	ch_sec[3].valueChanged.connect(lambda :channel_update(4))
	ch_width[0].valueChanged.connect(lambda :channel_update(1))
	ch_width[1].valueChanged.connect(lambda :channel_update(2))
	ch_width[2].valueChanged.connect(lambda :channel_update(3))
	ch_width[3].valueChanged.connect(lambda :channel_update(4))
	m.en_trigger.stateChanged.connect(lambda :trigger_update())
	m.en_term.stateChanged.connect(lambda :trigger_update())
	m.en_ts.stateChanged.connect(on_ts_enable_disable)
	m.wr_checkbox.stateChanged.connect(on_chk_wr)
	m.btn_clear.clicked.connect(on_ts_clear)
	

	trigger_update();
	on_ts_enable_disable()
	m.ts_table.clearContents()
#	m.ts_table
	poll_timer = QTimer()
	poll_timer.setInterval(200)
	poll_timer.timeout.connect(poll_timer_cb)
	poll_timer.start()
	app.exec_()
