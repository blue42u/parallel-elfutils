WORK=$(shell pwd)/..
INSTALL=$(WORK)/install

CFLAGS=-O3 -g

.PHONY: check run last

# Most of the time you just want to run it again and view the output
check: run last

run: cilk-parse demo/demo
	./check

last:
	less -S errors.last.hel errors.last.drd

cilk-parse: cilk-parse.cpp
	icpc $(CFLAGS) -std=c++11 -I$(INSTALL)/include -o $@ $< \
		-L$(INSTALL)/lib -Wl,-rpath=$(INSTALL)/lib \
		-lsymtabAPI \
		-lparseAPI \
		-linstructionAPI
demo/demo:
	$(MAKE) -C demo
