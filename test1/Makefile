WORK=$(shell pwd)/..
INSTALL=$(WORK)/install

DATE=$(shell date '+%F.%T')
VAL=$(INSTALL)/valgrind/bin/valgrind
VFLAGS= --suppressions=system.supp --fair-sched=yes

INPUTFILE=demo/demo
#INPUTFILE=$(INSTALL)/elfutils/lib/libdw.so

ERRORKINDS=helgrind drd coverage
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

errors.%: cilk-parse $(INPUTFILE)
	$(VAL) $(VFLAGS) --tool=$* --log-file=errors.$(DATE).$* ./$+
	ln -sf errors.$(DATE).$* errors.$*

errors.coverage: cilk-parse $(INPUTFILE)
	$(VAL) $(VFLAGS) -q --tool=callgrind \
		--callgrind-out-file=callgrind.$(DATE).coverage ./$+
	lua cgstats.lua --threshold=100 callgrind.$(DATE).coverage errors.$(DATE).coverage
	ln -sf errors.$(DATE).coverage errors.coverage

### Now for the more normal compilation stuff

CFLAGS += -O0 -g

cilk-parse: cilk-parse.cpp
	icpc $(CFLAGS) -std=c++11 \
		-I$(INSTALL)/dyninst/include -I$(INSTALL)/boost/include \
		-o $@ $< \
		-L$(INSTALL)/dyninst/lib -Wl,-rpath=$(INSTALL)/dyninst/lib \
		-L$(INSTALL)/boost/lib -Wl,-rpath=$(INSTALL)/boost/lib \
		-lsymtabAPI -lparseAPI -linstructionAPI
demo/demo:
	$(MAKE) -C demo
