WORK=$(shell pwd)/..
INSTALL=$(WORK)/install

CFLAGS=-O3 -g

cilk-parse: cilk-parse.cpp
	icpc $(CFLAGS) -std=c++11 -I$(INSTALL)/include -o $@ $< \
		-L$(INSTALL)/lib -Wl,-rpath=$(INSTALL)/lib \
		-lsymtabAPI \
		-lparseAPI \
		-linstructionAPI

.PHONY: check
check: demo/demo
	./check

demo/demo:
	$(MAKE) -C demo
