WORK=$(shell pwd)/..
INSTALL=$(WORK)/install

VFLAGS = --suppressions=system.supp --suppressions=toreport.supp --fair-sched=yes
GLOBALDEPS += system.supp toreport.supp

.PHONY: run last

### Top-level targets

ERRORKINDS=memcheck helgrind
ERRORFILES=$(foreach x,$(ERRORKINDS),errors.$(x))

ifdef DRD
ERRORKINDS += drd
endif

ifdef CALLGRIND
ERRORKINDS += callgrind
OUTPUTFILES += output.callgrind.txz
endif

ifdef PROF
OUTPUTFILES += output.prof.txz
endif

# Run all the bits and display the resulting logs
run: $(ERRORFILES) $(OUTPUTFILES)
	less -S $(ERRORFILES)

# View the last logs from the last run without updating them
last:
	less -S $(ERRORFILES)

### Individual input data rules

INPUTS += input1/input
input1/input: input1/main.c input1/print.c
	cc $(CFLAGS) -Wall -g -o $@ $^

INPUTS += biginputs/libasm.so
biginputs/libasm.so: $(INSTALL)/elfutils/lib/libasm-0.175.so
	@mkdir -p biginputs
	ln -sf $< $@

ifdef REALBIG
INPUTS += biginputs/libdyninstAPI.so
biginputs/libdyninstAPI.so: $(INSTALL)/dyninst/lib/libdyninstAPI.so
	@mkdir -p biginputs
	ln -sf $< $@
endif

### Individual test specifications

CFLAGS += -Wall -g -O0
CFLAGS += -I$(INSTALL)/dyninst/include -I$(INSTALL)/boost/include
LDFLAGS += -L$(INSTALL)/elfutils/lib -Wl,-rpath=$(INSTALL)/elfutils/lib
LDFLAGS += -L$(INSTALL)/dyninst/lib -Wl,-rpath=$(INSTALL)/dyninst/lib
LDFLAGS += -L$(INSTALL)/boost/lib -Wl,-rpath=$(INSTALL)/boost/lib
LDFLAGS += -Wl,-rpath=$(INSTALL)/gcc/lib -Wl,-rpath=$(INSTALL)/gcc/lib64

LDLPATH = $(INSTALL)/dyninst/lib:$(INSTALL)/elfutils/lib:$(INSTALL)/gcc/lib64:/projects/comp522/jma14/tbb/lib

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
test1/main_ENV = OMP_NUM_THREADS=$(2)
test1/main = ./$(0) $(1) > /dev/null

TESTS += unstrip/unstrip
LDLIBS = -lelf -lparseAPI -lsymtabAPI -ldynElf -ldynDwarf -linstructionAPI -lcommon
FILES = unstrip.C fingerprint.C database.C semanticDescriptor.C types.C callback.C util.C
unstrip/unstrip: $(foreach f,$(FILES),$(WORK)/dyninst/examples/unstrip.dir/$(f))
	@mkdir -p unstrip
	ln -sf $(WORK)/dyninst/examples/unstrip.dir/ddb.db unstrip/ddb.db
	ln -sf $(WORK)/dyninst/examples/unstrip.dir/params.db unstrip/params.db
	ln -sf $(WORK)/dyninst/examples/unstrip.dir/unistd.db unstrip/unistd.db
	c++ $(CFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)
unstrip/unstrip_ENV = OMP_NUM_THREADS=$(2)
unstrip/unstrip = ./$(0) -f $(1) -o /dev/null

TESTS += hpc/hpcstruct-bin
hpc/hpcstruct-bin:
	@mkdir -p hpc
	ln -s $(INSTALL)/hpctoolkit/libexec/hpctoolkit/hpcstruct-bin $@
hpc/hpcstruct-bin_ENV = LD_LIBRARY_PATH=$(INSTALL)/hpctoolkit/lib/hpctoolkit/ext-libs:$(INSTALL)/gcc/lib64:/projects/comp522/jma14/tbb/lib
hpc/hpcstruct-bin = ./$(0) -o /dev/null -j$(2) --jobs-symtab $(2) $(1)

### Test output concatination rules

errors = $(dir $(1))errors.$(notdir $(1)).$(subst /,_,$(2)).$(3)
output = $(dir $(1))output.$(notdir $(1)).$(subst /,_,$(2)).$(3)

errors.%: $(foreach i,$(INPUTS),$(foreach t,$(TESTS),$(call errors,$(t),$(i),%)))
	cat $^ > $@

errors.coverage: cgstats.lua \
	$(foreach i,$(INPUTS),$(foreach t,$(TESTS),$(call output,$(t),$(i),callgrind)))
	lua cgstats.lua $(filter-out cgstats.lua,$^) $@

output.%.txz: \
	$(foreach i,$(INPUTS),$(foreach t,$(TESTS),$(call output,$(t),$(i),%)))
	@rm -f $@
	tar cvJf $@ $^

### Valgrind Testing Machinery

VAL=$(INSTALL)/valgrind/bin/valgrind
VALTOOLS=memcheck helgrind drd callgrind cachegrind massif

VFLAGS += --tool=$(v) --log-file=$(call errors,$(t),$(i),$(v))
VOUT_callgrind = --callgrind-out-file=$(call output,$(t),$(i),$(v))

VFLAGS_callgrind = --collect-jumps=yes --collect-bus=yes --cache-sim=yes
VFLAGS_callgrind += --simulate-wb=yes --cacheuse=yes --simulate-hwpref=yes
VFLAGS_memcheck = --leak-check=full

VTHREADS = 30

define valgrind
$(call errors,$(t),$(i),$(v)) $(if VOUT_$(v),$(call output,$(t),$(i),$(v))): \
		$(t) $(i) $(GLOBALDEPS)
	$(call $(t)_ENV,$(i),$(VTHREADS)) $(VAL) $(VFLAGS) \
		$(VFLAGS_$(v)) $(VOUT_$(v)) \
		$(call $(t),$(i),$(VTHREADS))

endef
$(eval $(foreach i,$(INPUTS),$(foreach t,$(TESTS),$(foreach v,$(VALTOOLS),$(call valgrind)))))

### HPCToolkit Profiling Macherinery

define hpcstruct
$(t).hpcstruct: $(t) $(GLOBALDEPS)
	./hpcstruct -o $$@ $$<
#	LD_LIBRARY_PATH=$(LDLPATH) ./hpcstruct/hpcstruct-bin -o $$@ $$<

endef
$(eval $(foreach t,$(TESTS),$(call hpcstruct)))

HTHREADS = 24

define hpcrun
$(call output,$(t),$(i),prof): $(t).hpcstruct $(i) $(GLOBALDEPS)
	@rm -rf $$@.pre $$@
	$(call $(t)_ENV,$(i),$(HTHREADS)) ./hpcrun -t -o $$@.pre \
		$(call $(t),$(i),$(HTHREADS))
	./hpcprof -o $$@ -S $$< \
		-I $(WORK)/dyninst/+ -I $(WORK)/elfutils/+ \
		$$@.pre

endef
$(eval $(foreach i,$(INPUTS),$(foreach t,$(TESTS),$(call hpcrun))))
