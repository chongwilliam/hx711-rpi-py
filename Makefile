# MIT License
#
# Copyright (c) 2021 Daniel Robertson
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# using CFLAG -Wl,-z,defs results in linker error (undefined refs)

CXX := g++
AR := ar
INCDIR := include
SRCDIR := src
BUILDDIR := build
BINDIR := bin
SRCEXT := cpp
LIBS := -lhx711 -llgpio
INC := -I $(INCDIR)
CFLAGS :=	-O2 \
			-fvisibility=hidden \
			-shared \
			-fPIC \
			-fomit-frame-pointer \
			-pipe \
			-Wall \
			-Wfatal-errors \
			-Werror=format-security \
			-Wl,-z,relro \
			-Wl,-z,now \
			-Wl,--hash-style=gnu \
			-Wl,--as-needed \
			-D_FORTIFY_SOURCE=2 \
			-fstack-clash-protection \
			-DNDEBUG=1 \
			$(shell python3-config --includes) \
			-Iextern/pybind11/include

PYMODULE_FILENAME := HX711$(shell python3-config --extension-suffix)

########################################################################

# https://stackoverflow.com/a/39895302/570787
ifeq ($(PREFIX),)
	PREFIX := /usr/local
endif

ifeq ($(OS),Windows_NT)
	IS_WIN := 1
endif

ifeq ($(GITHUB_ACTIONS),true)
	IS_GHA := 1
endif

ifneq ($(IS_WIN),1)
	IS_PI := $(shell test -f /proc/device-tree/model && grep -qi "raspberry pi" /proc/device-tree/model)
endif

########################################################################

ifeq ($(IS_PI),1)
# only include these flags on rpi
	CFLAGS :=	-march=native \
				-mfpu=vfp \
				-mfloat-abi=hard \
				$(CFLAGS)
endif

CXXFLAGS :=		-std=c++11 \
				-fexceptions \
				$(CFLAGS)

########################################################################

.PHONY: all
all:	dirs \
		build

.PHONY: build
build:
	$(CXX) \
		$(CXXFLAGS) \
		$(SRCDIR)/bindings.$(SRCEXT) \
		-o $(BINDIR)/$(PYMODULE_FILENAME) \
		$(LIBS)

.PHONY: clean
clean:
	rm -r $(BUILDDIR)/*
	rm -r $(BINDIR)/*

.PHONY: dirs
dirs:
	mkdir -p $(BINDIR)
	mkdir -p $(BUILDDIR)

.PHONY: install
install: $(BINDIR)/$(PYMODULE_FILENAME)
	install -d $(DESTDIR)$(PREFIX)/lib/
	install -m 644 $(BUILDDIR)/$(PYMODULE_FILENAME) $(DESTDIR)$(PREFIX)/lib/
#	ldconfig $(DESTDIR)$(PREFIX)/lib

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/lib/HX711.*
	ldconfig $(DESTDIR)$(PREFIX)/lib
