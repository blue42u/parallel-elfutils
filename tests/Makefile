WORK=$(shell pwd)/..
INSTALL=$(WORK)/install

VFLAGS = --suppressions=system.supp --fair-sched=yes

.PHONY: run last

### Top-level targets

ERRORKINDS=helgrind drd coverage stability
ERRORFILES=$(foreach x,$(ERRORKINDS),errors.$(x))

# Run all the bits and display the resulting logs
run: $(ERRORFILES)
	less -S $+

# View the last logs from the last run without updating them
last:
	less -S $(ERRORFILES)

### Individual input data rules

INPUTS += input1/input
input1/input: input1/main.c input1/print.c
	cc $(CFLAGS) -Wall -g -o $@ $^

### Individual test specifications

CFLAGS += -Wall -g -O0
CFLAGS += -I$(INSTALL)/dyninst/include -I$(INSTALL)/boost/include
LDLIBS += -L$(INSTALL)/dyninst/lib -Wl,-rpath=$(INSTALL)/dyninst/lib
LDLIBS += -L$(INSTALL)/boost/lib -Wl,-rpath=$(INSTALL)/boost/lib
LDLIBS += -Wl,-rpath=$(INSTALL)/gcc/lib -Wl,-rpath=$(INSTALL)/gcc/lib64

GLOBALDEPS += $(INSTALL)/dyninst/lib/libsymtabAPI.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libparseAPI.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libinstructionAPI.so
LDLIBS += -lsymtabAPI -lparseAPI -linstructionAPI

TESTS += test1/main
test1/main: test1/main.cpp 
	cc $(CFLAGS) -std=c++11 -fopenmp -o $@ $^ $(LDLIBS)

### Test output concatination rules

errors = $(dir $(1))errors.$(notdir $(1)).$(subst /,_,$(2)).$(3)
output = $(dir $(1))output.$(notdir $(1)).$(subst /,_,$(2)).$(3)

errors.%: $(foreach t,$(TESTS),$(foreach i,$(INPUTS),$(call errors,$(t),$(i),%)))
	cat $^ > $@

errors.coverage: $(foreach t,$(TESTS),$(foreach i,$(INPUTS),$(call output,$(t),$(i),callgrind)))
	lua cgstats.lua $^ $@

### Valgrind Testing Machinery

VAL=$(INSTALL)/valgrind/bin/valgrind

VFLAGS_callgrind = --callgrind-out-file=$(1)

define valgrind
$(call errors,$(t),$(i),%) $(call output,$(t),$(i),%): $(t) $(i) $(GLOBALDEPS)
	$(VAL) --tool=$$* --log-file=$(call errors,$(t),$(i),$$*) \
		$$(VFLAGS) $$(call VFLAGS_$$*,$(call output,$(t),$(i),$$*)) \
		./$(t) $(i) > /dev/null

endef
$(eval $(foreach t,$(TESTS),$(foreach i,$(INPUTS),$(call valgrind))))

### Stability Testing Machinery, to be rebuilt
define stability
$(call errors,$(t),$(i),stability): $(t) $(i) $(GLOBALDEPS)
	./$(t) $(i) 1 > a.log
	./$(t) $(i) 24 > b.log
	diff -s a.log b.log > $$@
	rm -f a.log b.log

endef
$(eval $(foreach t,$(TESTS),$(foreach i,$(INPUTS),$(call stability))))
