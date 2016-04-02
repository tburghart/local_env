# ========================================================================
# Copyright (c) 2014-2016 T. R. Burghart.
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# ========================================================================
#
# Install shell configuration files
#

ECP	?= /bin/cp -p
INSTALL	:= /usr/bin/install
PRJDIR	:= $(shell pwd)
UID	:= $(shell /usr/bin/id -u)
SYS	:= $(shell /usr/bin/uname -s | /usr/bin/tr '[A-Z]' '[a-z]')

HOME_TGTS  := $(patsubst $(PRJDIR)/home/%,$(HOME)/.%,$(wildcard \
	$(PRJDIR)/home/bashrc $(PRJDIR)/home/profile $(PRJDIR)/home/shrc))

ROOT_TGTS  := \
	$(patsubst $(PRJDIR)/root/%,/%, \
		$(wildcard \
			$(PRJDIR)/root/usr/local/etc/sh.* \
			$(PRJDIR)/root/usr/local/etc/*sh.term.prompt)) \
	$(patsubst $(PRJDIR)/root/etc/$(SYS).%,/etc/%, \
		$(wildcard $(PRJDIR)/root/etc/$(SYS).*))

.PHONY: all home root

all: home root

home: $(HOME_TGTS)

root: $(ROOT_TGTS)

$(HOME)/.% : $(PRJDIR)/home/%
	$(INSTALL) -C -p -m0644 $^ $@

/etc/% : $(PRJDIR)/root/etc/$(SYS).%
	@echo $(INSTALL) -C -p -m0644 -o0 -g0 $^ $@

/usr/local/etc/% : $(PRJDIR)/root/usr/local/etc/%
	@echo $(INSTALL) -C -p -m0644 -o0 -g0 $^ $@

