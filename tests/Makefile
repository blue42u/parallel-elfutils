WORK=$(shell pwd)/..
INSTALL=$(WORK)/install
SHELL=/bin/bash

.PHONY: all vrun view run prep
.SECONDARY:
.DELETE_ON_ERROR:

### Error report control variables

ERRORKINDS=memcheck helgrind

ifdef NONE
ERRORKINDS=
endif

ifdef ALL
DRD=1
PROF=1
STABLE=1
BIGGER=1
endif

ifdef MEMCHECK
ERRORKINDS += memcheck
endif

ifdef HELGRIND
ERRORS += helgrind
endif

ifdef DRD
ERRORKINDS += drd
endif

ifdef CALLGRIND
ERRORKINDS += callgrind
OUTPUTFILES += output.callgrind.txz
endif

ifdef PROF
OUTPUTFILES += output.prof.txz
ifndef PREP
.NOTPARALLEL:
endif
endif

ifdef STABLE
ERRORKINDS += stable
ifndef PREP
.NOTPARALLEL:
endif
endif

# The top-level target is to view the logs
all: vrun

### Individual input data rules
SMALLINPUTS :=
BIGINPUTS :=
BIGGERINPUTS :=

SMALLINPUTS += input1/input
input1/input: input1/main.c input1/print.c
	cc $(CFLAGS) -Wall -g -o $@ $^

BIGINPUTS += biginputs/libasm.so
biginputs/libasm.so: $(INSTALL)/elfutils/lib/libasm-0.175.so
	@mkdir -p biginputs
	ln -s $< $@

BIGINPUTS += biginputs/libInst.so
biginputs/libInst.so: $(INSTALL)/dyninst/lib/libInst.so
	@mkdir -p biginputs
	ln -s $< $@

BIGGERINPUTS += biginputs/libdyninstAPI.so
biginputs/libdyninstAPI.so: $(INSTALL)/dyninst/lib/libdyninstAPI.so
	@mkdir -p biginputs
	ln -s $< $@

INPUTS := $(SMALLINPUTS)
ifdef BIG
INPUTS += $(BIGINPUTS)
else
ifdef BIGGER
INPUTS += $(BIGINPUTS) $(BIGGERINPUTS)
endif
endif

ALLINPUTS := $(SMALLINPUTS) $(BIGINPUTS) $(BIGGERINPUTS)
prep: $(ALLINPUTS)

### Individual test specifications

CFLAGS += -Wall -g -O0
CFLAGS += -I$(INSTALL)/dyninst/include -I$(INSTALL)/boost/include
LDFLAGS += -L$(INSTALL)/elfutils/lib
#-Wl,-rpath=$(INSTALL)/elfutils/lib
LDFLAGS += -L$(INSTALL)/dyninst/lib
#-Wl,-rpath=$(INSTALL)/dyninst/lib
LDFLAGS += -L$(INSTALL)/boost/lib -Wl,-rpath=$(INSTALL)/boost/lib
LDFLAGS += -L/projects/comp522/jma14/tbb -Wl,-rpath=/projects/comp522/jma14/tbb
LDFLAGS += -ltbb_debug

LDLPATH = $(INSTALL)/dyninst/lib:$(INSTALL)/elfutils/lib:/projects/comp522/jma14/tbb/lib

GLOBALDEPS += $(INSTALL)/dyninst/lib/libsymtabAPI.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libparseAPI.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libinstructionAPI.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libdynElf.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libdynDwarf.so
GLOBALDEPS += $(INSTALL)/dyninst/lib/libcommon.so

TESTS += test1/main
LDLIBS = -lsymtabAPI -lparseAPI -linstructionAPI
test1/main: test1/main.cpp $(GLOBALDEPS)
	cc $(CFLAGS) -std=c++11 -fopenmp -o $@ $^ $(LDFLAGS) $(LDLIBS)
test1/main_ENV = OMP_NUM_THREADS=$(2) LD_LIBRARY_PATH=$(LDLPATH)
test1/main = ./$(0) $(1) > $(3)

TESTS += unstrip/unstrip
unstrip/unstrip:
	@mkdir -p unstrip
	ln -s $(INSTALL)/dyninst/bin/ddb.db unstrip/ddb.db
	ln -s $(INSTALL)/dyninst/bin/params.db unstrip/params.db
	ln -s $(INSTALL)/dyninst/bin/unistd.db unstrip/unistd.db
	ln -s $(INSTALL)/dyninst/bin/unstrip $@
unstrip/unstrip_ENV = OMP_NUM_THREADS=$(2) LD_LIBRARY_PATH=$(LDLPATH)
unstrip/unstrip = ./$(0) -f $(1) -o $(3)

TESTS += hpc/hpcstruct-bin
hpc/hpcstruct-bin:
	@mkdir -p hpc
	ln -s $(INSTALL)/hpctoolkit/libexec/hpctoolkit/hpcstruct-bin $@
hpc/hpcstruct-bin_ENV = LD_LIBRARY_PATH=$(INSTALL)/hpctoolkit/lib/hpctoolkit/ext-libs:/projects/comp522/jma14/tbb/lib
hpc/hpcstruct-bin = ./$(0) -o $(3) -j$(2) --jobs-symtab $(2) $(1)

prep: $(TESTS)

### Test output presentation and composition rules

# Error filename macros
errors = $(dir $(1))errors.$(notdir $(1)).$(subst /,_,$(2)).$(3)
output = $(dir $(1))output.$(notdir $(1)).$(subst /,_,$(2)).$(3)

ERRORFILES := $(foreach x,$(ERRORKINDS),$(foreach i,$(INPUTS),$(foreach t,$(TESTS),$(call errors,$(t),$(i),$(x)))))
errorfiles = $(foreach i,$(INPUTS),$(foreach t,$(TESTS),$(call errors,$(t),$(i),$(1))))

ifdef PROF
PRERUN = subprep
.PHONY: subprep
subprep:
	$(MAKE) prep PREP=1
endif

run: $(PRERUN) $(ERRORFILES) $(OUTPUTFILES)

view:
	@less -Sf $(foreach x,$(ERRORKINDS), <( cat \
		$(foreach f,$(call errorfiles,$(x)), `[ -e $(f) ] && echo $(f)` ) \
		/dev/null \
	))

vrun: run
	@less -Sf $(foreach x,$(ERRORKINDS), <( cat \
		$(foreach f,$(call errorfiles,$(x)), `[ -e $(f) ] && echo $(f)` ) \
		/dev/null \
	))

output.%.txz: \
	$(foreach i,$(INPUTS),$(foreach t,$(TESTS),$(call output,$(t),$(i),%)))
	@rm -f $@
	tar cJf $@ $^

### Valgrind Testing Machinery

VAL=$(INSTALL)/valgrind/bin/valgrind
VALTOOLS=memcheck helgrind drd callgrind cachegrind massif

VFLAGS = --suppressions=system.supp --suppressions=toreport.supp
VFLAGS += --tool=$(v) --log-file=$(call errors,$(t),$(i),$(v))
VFLAGS +=  --soname-synonyms=somalloc='*tbbmalloc*'
VOUT_callgrind = --callgrind-out-file=$(call output,$(t),$(i),$(v))

VFLAGS_callgrind = --collect-jumps=yes --collect-bus=yes --cache-sim=yes
VFLAGS_callgrind += --simulate-wb=yes --cacheuse=yes --simulate-hwpref=yes
VFLAGS_memcheck = --leak-check=full --track-origins=yes
VFLAGS_drd += --check-stack-var=yes

ifdef SHOWLEAKS
#VFLAGS_memcheck += --show-leak-kinds=all
else
VFLAGS_memcheck += --show-leak-kinds=none
endif

ifdef UNFAIR
VFLAGS += --fair-sched=no
else
VFLAGS += --fair-sched=yes
endif

ifdef HELFAST
VFLAGS_helgrind += --history-level=none
endif

VTHREADS = 30

define valgrind
$(call errors,$(t),$(i),$(v)) $(if VOUT_$(v),$(call output,$(t),$(i),$(v))): \
		$(t) $(i) system.supp toreport.supp $(GLOBALDEPS)
	-$(call $(t)_ENV,$(i),$(VTHREADS)) \
		LD_LIBRARY_PATH="$$$$LD_LIBRARY_PATH:$(INSTALL)/gcc/lib64" \
		$(VAL) $(VFLAGS) \
		$(VFLAGS_$(v)) $(VOUT_$(v)) \
		$(call $(t),$(i),$(VTHREADS),/dev/null)

endef
$(eval $(foreach i,$(ALLINPUTS),$(foreach t,$(TESTS),$(foreach v,$(VALTOOLS),$(call valgrind)))))

### HPCToolkit Profiling Macherinery

define hpcstruct
STRUCT += prof/$(notdir $(f)).hpcstruct
SS += -S prof/$(notdir $(f)).hpcstruct
prof/$(notdir $(f)).hpcstruct: $(f)
	@mkdir -p prof
	./hpcstruct -o $$@ $$<

endef
$(eval $(foreach f,$(TESTS),$(call hpcstruct)))
$(eval $(foreach f,$(wildcard $(INSTALL)/dyninst/lib/*.so),$(call hpcstruct)))
$(eval $(foreach f,$(wildcard $(INSTALL)/elfutils/lib/*.so),$(call hpcstruct)))
$(eval $(foreach f,$(wildcard $(INSTALL)/gcc/lib64/libgomp*.so),$(call hpcstruct)))
$(eval $(foreach f,$(wildcard $(INSTALL)/gcc/lib64/libstd*.so),$(call hpcstruct)))
$(eval $(foreach f,$(addprefix $(INSTALL)/hpctoolkit/lib/hpctoolkit/ext-libs/, \
	libparseAPI.so.10.0.0 libinstructionAPI.so.10.0.0 libsymtabAPI.so.10.0.0 \
	libdynElf.so.10.0.0 libcommon.so.10.0.0 \
),$(call hpcstruct)))
prep: $(STRUCT)

HTHREADS = $(shell nproc)

define hpcrun
$(call output,$(t),$(i),prof.pre.%): $(t) $(i) $(GLOBALDEPS)
	@rm -rf $$@
	./hpcrun -e REALTIME@100 -t -o $$@ bash -c \
	'$(call $(t)_ENV,$(i),$$*) \
		LD_LIBRARY_PATH=$$$$LD_LIBRARY_PATH:/opt/apps/software/Core/GCCcore/6.4.0/lib64 \
		exec $(call $(t),$(i),$$*,/dev/null)'

$(call output,$(t),$(i),prof.%): $(call output,$(t),$(i),prof.pre.%) $(STRUCT)
	@rm -rf $$@
	./hpcprof -o $$@ $(SS) -I $(WORK)/dyninst/+ -I $(WORK)/elfutils/+ $$<

$(call output,$(t),$(i),prof): $(call output,$(t),$(i),prof.$(HTHREADS))
	@rm -rf $$@
	cp -r $$^ $$@

endef
$(eval $(foreach i,$(ALLINPUTS),$(foreach t,$(TESTS),$(call hpcrun))))

### Stability Testing Machinery

define pass
	$(call $(t)_ENV,$(i),$(2)) \
		LD_LIBRARY_PATH=$$$$LD_LIBRARY_PATH:/opt/apps/software/Core/GCCcore/6.4.0/lib64 \
		/usr/bin/time -ao $$@ -f ' Pass $(1): %E ~ %Uu/%Sk (%P)' \
		$(call $(t),$(i),$(2),$$@.tmp/pass.$(1)) 2>> $$@.tmp/pass.$(1).err \
		|| (echo "        | Failed with exit code $$$$?!" >> $$@.tmp/pass.$(1).err; \
		cat $$@.tmp/pass.$(1).err >> $$@)
	@if cmp -s $$@.tmp/base $$@.tmp/pass.$(1); \
	then echo '        | Output is stable' >> $$@; \
	else echo '        | Output is not stable!' >> $$@; \
	fi
endef

define stable
$(call errors,$(t),$(i),stable): $(t) $(i) $(GLOBALDEPS)
	@rm -rf $$@ $$@.tmp
	@mkdir $$@.tmp
	@echo '### Command $(call $(t),$(i),N,O)' > $$@
	$(call $(t)_ENV,$(i),1) \
		LD_LIBRARY_PATH=$$$$LD_LIBRARY_PATH:/opt/apps/software/Core/GCCcore/6.4.0/lib64 \
		/usr/bin/time -ao $$@ -f 'Baseline: %E ~ %Uu/%Sk (%P)' \
		$(call $(t),$(i),1,$$@.tmp/base) 2>> $$@.tmp/base.err \
		|| (echo "        | Baseline failed ($$$$?), something is very broken!" >> $$@.tmp/base.err; \
		cat $$@.tmp/base.err >> $$@)
	$(call pass,02,2)
	$(call pass,04,4)
	$(call pass,08,8)
	$(call pass,16,16)
	$(call pass,32,32)
	@echo '' >> $$@

endef
$(eval $(foreach i,$(ALLINPUTS),$(foreach t,$(TESTS),$(call stable))))
