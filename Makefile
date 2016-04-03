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
# Installs shell configuration files.
#
# Requires GNU Make functionality and a Unix-y environment.
#

PRJDIR	:= $(CURDIR)
STYPE	:= $(or $(shell /usr/bin/uname -s 2>/dev/null \
		| /usr/bin/tr '[A-Z]' '[a-z]' 2>/dev/null), \
		$(error Can't determine system type))

UID	:= $(or $(shell /usr/bin/id -u 2>/dev/null), \
		$(error Can't figure out your UID))
GID	:= $(or $(shell /usr/bin/id -g 2>/dev/null), \
		$(error Can't figure out your GID))

# try to get the actual login name, for the test below
UNM	:= $(or $(LOGNAME),$(USER),$(shell /usr/bin/id -un 2>/dev/null), \
		$(error Can't figure out your login name))

# only install to root's home directory if there's no alternate superuser
# on my systems, by convention that's 'toor'
ifeq ($(UID)/$(UNM),0/root)
NO_HOME	:= $(shell /usr/bin/id -u toor 2>/dev/null)
endif

ifeq ($(shell test -d /etc/profile.d || echo no),)
PROF_D	:= true
else
PROF_D	:= false
endif

ifeq ($(STYPE),linux)
INSTALL	:= /usr/bin/install -p
else
INSTALL	:= /usr/bin/install -Cp
endif
INSTSYS	:= $(INSTALL) -o 0 -g 0
INSTUSR	:= $(INSTALL) -o $(UID) -g $(GID)
ifneq ($(UID),0)
INSTSYS	:= @echo $(INSTSYS)
endif

INSTUF	:= $(INSTUSR) -m 0644
INSTSF	:= $(INSTSYS) -m 0644

INSTUX	:= $(INSTUSR) -m 0755
INSTSX	:= $(INSTSYS) -m 0755

# these will be wildcard patterns, sort to remove duplicates
SH_ETC	:= $(sort profile ksh.kshrc bashrc zshenv zprofile zshrc)
SH_LOC	:= $(sort sh.* *sh.term.prompt)
SH_USR	:= $(sort $(filter-out ksh.kshrc,$(SH_ETC)) \
		bash_profile kshrc shrc *login *logout)

HOME_TGTS  := $(patsubst $(PRJDIR)/home/$(STYPE)/%, $(HOME)/.%, \
	$(wildcard $(foreach pat,$(SH_USR),$(PRJDIR)/home/$(STYPE)/$(pat))))
HOME_TGTS  += $(patsubst $(PRJDIR)/home/%, $(HOME)/.%, \
	$(wildcard $(foreach pat,$(SH_USR),$(PRJDIR)/home/$(pat))))

ROOT_TGTS  := $(patsubst $(PRJDIR)/root/$(STYPE)/etc/%, /etc/%, \
	$(wildcard $(foreach pat,$(SH_ETC),$(PRJDIR)/root/$(STYPE)/etc/$(pat))))
ROOT_TGTS  += $(patsubst $(PRJDIR)/root/etc/%, /etc/%, \
	$(wildcard $(foreach pat,$(SH_ETC),$(PRJDIR)/root/etc/$(pat))))
ROOT_TGTS  += $(patsubst $(PRJDIR)/root/$(STYPE)/usr/local/etc/%, /usr/local/etc/%, \
	$(wildcard $(foreach pat,$(SH_LOC),$(PRJDIR)/root/$(STYPE)/usr/local/etc/$(pat))))
ROOT_TGTS  += $(patsubst $(PRJDIR)/root/usr/local/etc/%, /usr/local/etc/%, \
	$(wildcard $(foreach pat,$(SH_LOC),$(PRJDIR)/root/usr/local/etc/$(pat))))

ifeq ($(PROF_D),true)
ROOT_TGTS  += $(patsubst $(PRJDIR)/root/$(STYPE)/etc/profile.d/%, /etc/profile.d/%, \
	$(wildcard $(PRJDIR)/root/$(STYPE)/etc/profile.d/*))
ROOT_TGTS  += $(patsubst $(PRJDIR)/root/etc/profile.d/%, /etc/profile.d/%, \
	$(wildcard $(PRJDIR)/root/etc/profile.d/*))
endif

# sort to remove duplicates
HOME_TGTS  := $(sort $(HOME_TGTS))
ROOT_TGTS  := $(sort $(ROOT_TGTS))

.PHONY: default home root

ifeq ($(NO_HOME),)
default: home root
else
default: root
endif

home: $(HOME_TGTS)

root: $(ROOT_TGTS)

$(HOME)/.% : $(PRJDIR)/home/%
	$(INSTALL) -m0644 $^ $@

/etc/% : $(PRJDIR)/root/$(STYPE)/etc/%
	$(INSTSF) $^ $@

/etc/% : $(PRJDIR)/root/etc/%
	$(INSTSF) $^ $@

/usr/local/etc/% : $(PRJDIR)/root/$(STYPE)/usr/local/etc/%
	$(INSTSF) $^ $@

/usr/local/etc/% : $(PRJDIR)/root/usr/local/etc/%
	$(INSTSF) $^ $@

$(HOME)/.% : $(PRJDIR)/home/$(STYPE)/%
	$(INSTUF) $^ $@

$(HOME)/.% : $(PRJDIR)/home/%
	$(INSTUF) $^ $@

