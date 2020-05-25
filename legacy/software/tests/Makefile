TESTS = gs_logger simple_delay random_pulse_gen

CFLAGS = -I../include
LDFLAGS = -L../lib ../lib/libfinedelay.a -lm 
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