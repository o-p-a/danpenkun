# makefile for danpenkun
#
# 2011/03/20 opa

DANPENLIB = danpen
DANPENFILES = $(DANPENLIB)/*

DFLAGS = -L $(DANPENLIB) -m '\#=====dpk====='

.PHONY: all

all: danpenkun.ini

danpenkun.ini: $(DANPENFILES)
	danpenkun $(DFLAGS) $@
	bat2unix $@

