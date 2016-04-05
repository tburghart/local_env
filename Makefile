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
# Builds a proper profile/rc structure and removes leftover gunk.
#
# The result looks like:
#   /etc/profile
#   /etc/zshenv
#   /etc/zshrc
#   /usr/local/etc/sh.aliases
#   /usr/local/etc/sh.rc
#   /usr/local/etc/sh.terminal
#   ~/.bash_profile
#   ~/.bashrc
#   ~/.kshrc
#   ~/.profile
#   ~/.shrc
#   ~/.zprofile
#   ~/.zshrc
#
# Where applicable:
#   /etc/profile.d/zzz_local.sh
#
# Used if present:
#   /usr/local/etc/sh.paths
#   /usr/local/etc/sh.local
#
# !!! Removed if present:
#
#   /etc/bashrc
#   /usr/local/etc/bash.term.prompt
#   /usr/local/etc/zsh.term.prompt
#
home_deprecated	:= $(wildcard $(HOME)/.pash_profile)
root_deprecated	:= $(wildcard /etc/bashrc \
	/usr/local/etc/bash.term.prompt /usr/local/etc/zsh.term.prompt)

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

# counting on this unlinking the destination file before copying
INSTALL	:= /usr/bin/install -cp

INSTSYS	:= $(INSTALL) -o 0 -g 0
INSTUSR	:= $(INSTALL) -o $(UID) -g $(GID)
LNSYS	:= /bin/ln -fs
LNUSR	:= $(LNSYS)

ifneq ($(UID),0)
INSTSYS	:= @echo $(INSTSYS)
LNSYS	:= @echo $(LNSYS)
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
ifneq ($(shell egrep -qw pathmunge /etc/profile.d/* 2>/dev/null || echo no),no)
$(warning Files in /etc/profile.d use pathmunge)
endif
ROOT_TGTS  += $(patsubst $(PRJDIR)/root/$(STYPE)/etc/profile.d/%, /etc/profile.d/%, \
	$(wildcard $(PRJDIR)/root/$(STYPE)/etc/profile.d/*))
ROOT_TGTS  += $(patsubst $(PRJDIR)/root/etc/profile.d/%, /etc/profile.d/%, \
	$(wildcard $(PRJDIR)/root/etc/profile.d/*))
endif

# these will get symlinked if source files don't exist
HOME_TGTS  += $(foreach fn, zprofile bashrc kshrc zshrc, $(HOME)/.$(fn))
ROOT_TGTS  += $(foreach fn, , /etc/$(fn))

# sort to remove duplicates
HOME_TGTS  := $(sort $(HOME_TGTS))
ROOT_TGTS  := $(sort $(ROOT_TGTS))

.PHONY: default home root

ifeq ($(NO_HOME),)
default: home root
else
default: root
endif

ifneq ($(home_deprecated),)
home ::
	@echo Clean up manually with command:
	@echo /bin/rm $(home_deprecated)
endif

ifneq ($(root_deprecated),)
root ::
	@echo Clean up manually with command:
	@echo /bin/rm $(root_deprecated)
endif

home :: $(HOME_TGTS)
	@echo Home directory layout:
	@/bin/ls -lh $(HOME)/.*rc $(HOME)/.*profile \
		$(wildcard $(HOME)/.*login $(HOME)/.*logout)

root :: $(ROOT_TGTS)

/etc/% : $(PRJDIR)/root/$(STYPE)/etc/%
	$(INSTSF) $< $@

/etc/% : $(PRJDIR)/root/etc/%
	$(INSTSF) $< $@

/usr/local/etc/% : $(PRJDIR)/root/$(STYPE)/usr/local/etc/%
	$(INSTSF) $< $@

/usr/local/etc/% : $(PRJDIR)/root/usr/local/etc/%
	$(INSTSF) $< $@

$(HOME)/.% : $(PRJDIR)/home/$(STYPE)/%
	$(INSTUF) $< $@

$(HOME)/.% : $(PRJDIR)/home/%
	$(INSTUF) $< $@

# create symlinks for files that don't have sources

/etc/zprofile : /etc/profile
	$(LNSYS) $(<F) $@

$(HOME)/.bash_profile : $(HOME)/.profile
	$(LNUSR) $(<F) $@

$(HOME)/.zprofile : $(HOME)/.profile
	$(LNUSR) $(<F) $@

$(HOME)/.bashrc : $(HOME)/.shrc
	$(LNUSR) $(<F) $@

$(HOME)/.kshrc : $(HOME)/.shrc
	$(LNUSR) $(<F) $@

$(HOME)/.zshrc : $(HOME)/.shrc
	$(LNUSR) $(<F) $@

