# makefile for danpenkun
#
# 2011/03/20 opa

.PHONY: all

DFLAGS = -L danpen -m '\# ----------'

all:
	danpenkun $(DFLAGS) danpenkun.ini

