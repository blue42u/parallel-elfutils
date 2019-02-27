WORK=$(shell pwd)/..
INSTALL=$(WORK)/install

DATE=$(shell date '+%F.%T')
VAL=$(INSTALL)/valgrind/bin/valgrind

INPUTFILE=demo/demo
#INPUTFILE=$(INSTALL)/elfutils/lib/libdw.so

ERRORKINDS=helgrind drd coverage stability
ERRORFILES=$(foreach x,$(ERRORKINDS),errors.$(x))

.PHONY: run last

### Top-level targets

# Run all the bits and display the resulting logs
run: $(ERRORFILES)
	less -S $+

# View the last logs from the last run without updating them
last:
	less -S $(ERRORFILES)

### Test machinery

ERRORS=errors.$(DATE)
OUTPUT=output.$(DATE)

VFLAGS=--suppressions=system.supp --fair-sched=yes
VFLAGS_callgrind=--callgrind-out-file=$(OUTPUT).callgrind

DEPS=cilk-parse $(INPUTFILE) system.supp 
DEPS += $(INSTALL)/dyninst/lib/libsymtabAPI.so
DEPS += $(INSTALL)/dyninst/lib/libparseAPI.so
DEPS += $(INSTALL)/dyninst/lib/libinstructionAPI.so
CMD=./cilk-parse -q $(INPUTFILE)
CMDT=./cilk-parse $(INPUTFILE)

# For helgrind and drd
errors.%: $(DEPS)
	$(VAL) $(VFLAGS) $(VFLAGS_$*) --tool=$* --log-file=$(ERRORS).$* $(CMD)
	ln -sf $(ERRORS).$* errors.$*

# For callgrind
output.%: $(DEPS)
	$(VAL) $(VFLAGS) $(VFLAGS_$*) -q --tool=$* $(CMD)
	ln -sf $(OUTPUT).$* output.$*

# Simple check for stability
errors.stability: $(DEPS)
	$(CMDT) 1 > a.log
	$(CMDT) 24 > b.log
	diff -s a.log b.log > $(ERRORS).stability
	rm a.log b.log
	ln -sf $(ERRORS).stability errors.stability

# Coarse, inaccurate coverage results
errors.coverage: output.callgrind cgstats.lua
	lua cgstats.lua output.callgrind $(ERRORS).coverage
	ln -sf $(ERRORS).coverage errors.coverage

### Now for the more normal compilation stuff

CFLAGS += -O0 -g -Wall

cilk-parse: cilk-parse.cpp
	cc $(CFLAGS) -std=c++11 -fopenmp \
		-I$(INSTALL)/dyninst/include -I$(INSTALL)/boost/include \
		-o $@ $< \
		-L$(INSTALL)/dyninst/lib -Wl,-rpath=$(INSTALL)/dyninst/lib \
		-L$(INSTALL)/boost/lib -Wl,-rpath=$(INSTALL)/boost/lib \
		-lsymtabAPI -lparseAPI -linstructionAPI
demo/demo:
	$(MAKE) -C demo
