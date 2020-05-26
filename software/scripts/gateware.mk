GW_SPEC = spec-fine-delay-v2.0-20140331.bin
GW_SVEC = svec-fine-delay-v2.0-20140331.bin

GW_URL_SPEC = http://www.ohwr.org/attachments/download/2777/$(GW_SPEC)
GW_URL_SVEC = http://www.ohwr.org/attachments/download/2778/$(GW_SVEC)

FIRMWARE_PATH ?= /lib/firmware/fmc

gateware_install:	bin/$(GW_SPEC) bin/$(GW_SVEC)
	install -D bin/$(GW_SPEC) $(FIRMWARE_PATH)/$(GW_SPEC)
	install -D bin/$(GW_SVEC) $(FIRMWARE_PATH)/$(GW_SVEC)
	ln -sf $(GW_SPEC) $(FIRMWARE_PATH)/spec-fine-delay.bin
	ln -sf $(GW_SVEC) $(FIRMWARE_PATH)/svec-fine-delay.bin

bin/$(GW_SPEC):
	wget $(GW_URL_SPEC) -P bin

bin/$(GW_SVEC):
	wget $(GW_URL_SVEC) -P bin

