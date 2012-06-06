TESTS = dmtd_calibration gs_logger random_pulse_test sweep_test temperature_calibration

CFLAGS = -I../include
LDFLAGS = -L../lib -static -lfinedelay -lm
CC=gcc

.PHONY: all

all: $(TESTS)

define TEST_template =
	$(1): $$($(1).o)
endef

$(foreach test,$(TESTS),$(eval $(call TEST_template,$(test))))

$(TESTS):
		gcc $@.c -o $@ $(CFLAGS) $(LDFLAGS)

clean:
	rm -f $(ALL_OBJS) $(TESTS)