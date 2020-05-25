SPEC_SW ?= $(shell readlink -f ~/wr-repos/spec-sw)
ETHERBONE ?= $(shell readlink -f ~/wr-repos/etherbone-core/api)

all:
	make -C lib SPEC_SW=$(SPEC_SW) ETHERBONE=$(ETHERBONE)
	make -C tests SPEC_SW=$(SPEC_SW) ETHERBONE=$(ETHERBONE)

clean:
	make -C lib clean SPEC_SW=$(SPEC_SW) ETHERBONE=$(ETHERBONE)
	make -C tests clean	 SPEC_SW=$(SPEC_SW) ETHERBONE=$(ETHERBONE)