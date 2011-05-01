# Makefile for danpenkun
#
# 2011/03/20 opa

DANPENLIB = danpen
DANPENFILES = $(DANPENLIB)/*

DFLAGS = -L $(DANPENLIB) -m '\#=====dpk====='

.PHONY: all install

all: danpenkun.ini danpenkun

danpenkun: danpenkun.ini bat2unix.bat
	bat2unix $<

danpenkun.ini: $(DANPENFILES)
	danpenkun $(DFLAGS) $@

bat2unix.bat: $(DANPENFILES)
	danpenkun $(DFLAGS) $@


install:
	cp -p danpenkun.exe $(USRLOCAL)/bat
	cp -p danpenkun.ini $(USRLOCAL)/bat
	cp -p dpk.bat $(USRLOCAL)/bat

