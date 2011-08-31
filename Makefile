# Makefile for danpenkun
#
# 2011/03/20 opa

DANPENLIB = danpen
DANPENFILES = $(DANPENLIB)/*

DFLAGS = -L $(DANPENLIB) -m '\#=====dpk====='

.PHONY: all install

all: danpenkun dpk bat2unix.bat

danpenkun: $(DANPENFILES)
	danpenkun $(DFLAGS) $@

dpk: $(DANPENFILES)
	danpenkun $(DFLAGS) $@

bat2unix.bat: $(DANPENFILES)
	danpenkun $(DFLAGS) $@


install:
	cp -p danpenkun $(USRLOCAL)/bin
	cp -p danpenkun.exe $(USRLOCAL)/bin
	cp -p dpk $(USRLOCAL)/bin
	cp -p dpk.exe $(USRLOCAL)/bin

