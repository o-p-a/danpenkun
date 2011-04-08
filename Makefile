# makefile for danpenkun
#
# 2011/03/20 opa

DANPENLIB = danpen
DANPENFILES = $(DANPENLIB)/*

DFLAGS = -L $(DANPENLIB) -m '\#=====dpk====='

.PHONY: all

all: danpenkun.ini bat2unix.bat

danpenkun.ini: $(DANPENFILES) bat2unix.bat
	danpenkun $(DFLAGS) $@
	bat2unix $@

bat2unix.bat: $(DANPENFILES)
	danpenkun $(DFLAGS) $@

