WORK=$(shell pwd)/..
INSTALL=$(WORK)/install

VFLAGS = --suppressions=system.supp --fair-sched=yes
GLOBALDEPS += system.supp

.PHONY: run last

### Top-level targets

ERRORKINDS=helgrind drd coverage
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
LDFLAGS += -L$(INSTALL)/elfutils/lib -Wl,-rpath=$(INSTALL)/elfutils/lib
LDFLAGS += -L$(INSTALL)/dyninst/lib -Wl,-rpath=$(INSTALL)/dyninst/lib
LDFLAGS += -L$(INSTALL)/boost/lib -Wl,-rpath=$(INSTALL)/boost/lib
LDFLAGS += -Wl,-rpath=$(INSTALL)/gcc/lib -Wl,-rpath=$(INSTALL)/gcc/lib64

GLOBALDEPS += $(INSTALL)/dyninst/lib/libsymtabAPI.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libparseAPI.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libinstructionAPI.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libdynElf.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libdynDwarf.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libcommon.so

TESTS += test1/main
LDLIBS = -lsymtabAPI -lparseAPI -linstructionAPI
test1/main: test1/main.cpp 
	cc $(CFLAGS) -std=c++11 -fopenmp -o $@ $^ $(LDFLAGS) $(LDLIBS)
test1/main = ./$(0) $(1)

TESTS += unstrip/unstrip
LDLIBS = -lelf -lparseAPI -lsymtabAPI -ldynElf -ldynDwarf -linstructionAPI -lcommon
FILES = unstrip.C fingerprint.C database.C semanticDescriptor.C types.C callback.C util.C
unstrip/unstrip: $(foreach f,$(FILES),$(WORK)/dyninst/examples/unstrip.dir/$(f))
	@mkdir -p unstrip
	ln -sf $(WORK)/dyninst/examples/unstrip.dir/ddb.db unstrip/ddb.db
	ln -sf $(WORK)/dyninst/examples/unstrip.dir/params.db unstrip/params.db
	ln -sf $(WORK)/dyninst/examples/unstrip.dir/unistd.db unstrip/unistd.db
	c++ $(CFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)
unstrip/unstrip = ./$(0) -f $(1) -o /dev/null

### Test output concatination rules

errors = $(dir $(1))errors.$(notdir $(1)).$(subst /,_,$(2)).$(3)
output = $(dir $(1))output.$(notdir $(1)).$(subst /,_,$(2)).$(3)

errors.%: $(foreach t,$(TESTS),$(foreach i,$(INPUTS),$(call errors,$(t),$(i),%)))
	cat $^ > $@

errors.coverage: cgstats.lua \
	$(foreach t,$(TESTS),$(foreach i,$(INPUTS),$(call output,$(t),$(i),callgrind)))
	lua cgstats.lua $(filter-out cgstats.lua,$^) $@

### Valgrind Testing Machinery

VAL=$(INSTALL)/valgrind/bin/valgrind
VALTOOLS=memcheck helgrind drd callgrind cachegrind massif

VFLAGS += --tool=$(v) --log-file=$(call errors,$(t),$(i),$(v))
VOUT_callgrind = --callgrind-out-file=$(call output,$(t),$(i),$(v))

define valgrind
$(call errors,$(t),$(i),$(v)) $(if VOUT_$(v),$(call output,$(t),$(i),$(v))): \
		$(t) $(i) $(GLOBALDEPS)
	OMP_NUM_THREADS=30 $(VAL) $(VFLAGS) $(VFLAGS_$(v)) $(VOUT_$(v)) \
		$(call $(t),$(i)) > /dev/null

endef
$(eval $(foreach t,$(TESTS),$(foreach i,$(INPUTS),$(foreach v,$(VALTOOLS),$(call valgrind)))))

### Stability Testing Machinery, to be rebuilt
#define stability
#$(call errors,$(t),$(i),stability): $(t) $(i) $(GLOBALDEPS)
#	$(call $(t),$(i),1) > a.log
#	$(call $(t),$(i),24) > b.log
#	diff -s a.log b.log > $$@
#	rm -f a.log b.log

#endef
#$(eval $(foreach t,$(TESTS),$(foreach i,$(INPUTS),$(call stability))))
