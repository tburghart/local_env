# ========================================================================
# Copyright (c) 2014-2018 T. R. Burghart.
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
#   /etc/bashrc         -> /etc/shrc *
#   /etc/profile
#   /etc/shrc
#   /etc/zprofile       -> /etc/profile
#   /etc/zshrc          -> /etc/shrc
#   /usr/local/etc/sh.aliases
#   /usr/local/etc/sh.rc
#   /usr/local/etc/sh.terminal
#   ~/.profile
#   ~/.shrc
#   ~/.bash_profile     -> ~/.profile
#   ~/.bashrc           -> ~/.shrc
#   ~/.kshrc            -> ~/.shrc
#   ~/.zprofile         -> ~/.profile
#   ~/.zshrc            -> ~/.shrc
#
# * /etc/bashrc gets special handling
#   It's not a recognized startup file for bash, but its presence has been
#   co-opted by enough default system configurations that I replace it so
#   that if it does get sourced at least I'll control what it contains.
#
# Used if present:
#   /etc/profile.d/*.sh
#   /usr/local/etc/sh.*
#
# !!! Removed if present:
#
#   /etc/kshrc
#   /etc/zshenv
#   /etc/profile.d/zzz_local.sh
#   /usr/local/etc/sh.local
#   /usr/local/etc/bash.term.prompt
#   /usr/local/etc/zsh.term.prompt
#   ~/.zshenv
#
home_deprecated	:= $(wildcard $(HOME)/.zshenv)
root_deprecated	:= $(wildcard \
	/etc/kshrc \
	/etc/zshenv \
	/etc/profile.d/zzz_local.sh \
	/usr/local/etc/sh.local \
	/usr/local/etc/bash.term.prompt \
	/usr/local/etc/zsh.term.prompt)

SHELL	:= /bin/bash
export	SHELL

prjdir	:= $(CURDIR)
uname	:= $(or $(wildcard /bin/uname), \
		$(wildcard /usr/bin/uname), \
		$(error Can't find system uname program))
stype	:= $(or $(shell $(uname) -s 2>/dev/null \
		| /usr/bin/tr '[A-Z]' '[a-z]' 2>/dev/null), \
		$(error Can't determine system type))
uid	:= $(or $(shell /usr/bin/id -u 2>/dev/null), \
		$(error Can't figure out your User ID))
gid	:= $(or $(shell /usr/bin/id -g 2>/dev/null), \
		$(error Can't figure out your Group ID))
unm	:= $(or $(shell /usr/bin/id -un 2>/dev/null), \
		$(error Can't figure out your User Name))
gnm	:= $(or $(shell /usr/bin/id -gn 2>/dev/null), \
		$(error Can't figure out your Group Name))

INSTALL	:= $(or $(wildcard /usr/gnu/bin/install), \
		$(wildcard /usr/ucb/install), \
		$(wildcard /usr/bin/install), \
		$(error Can't find compatible install program))

# whether to install files to /usr/local/bin
lclinst	:= false

ifeq	($(stype),sunos)
sys_usr	:= root
sys_grp	:= root
else
sys_usr	:= 0
sys_grp	:= 0
endif

ifeq	($(stype),darwin)
adm_grp	:= admin
else
adm_grp	:= $(sys_grp)
endif

ifeq	($(stype),darwin)
ifneq	($(uid),0)
lclinst	:= true
endif
else
ifeq	($(uid),0)
lclinst	:= true
endif
endif

# try to get the actual login name, for the test below
usrname	:= $(or $(LOGNAME),$(USER),$(shell /usr/bin/id -un 2>/dev/null), \
		$(error Can't figure out your login name))

# only install to root's home directory if there's no alternate superuser
# on my systems, by convention that's 'toor'
ifeq	($(uid)/$(usrname),0/root)
no_home	:= $(shell /usr/bin/id -u toor 2>/dev/null)
endif

ifeq	($(shell test -d /etc/profile.d || echo no),)
ifneq	($(shell egrep -qw pathmunge /etc/profile.d/* 2>/dev/null || echo no),no)
$(warning Files in /etc/profile.d use pathmunge)
endif
prof_d	:= true
else
prof_d	:= false
endif

dl_cmd	:= $(shell type -p curl 2>/dev/null || true)
ifneq ($(wildcard $(dl_cmd)),)
dl_cmd	+= -SsLRo
else
dl_cmd	:= $(shell type -p wget 2>/dev/null || true)
ifneq ($(wildcard $(dl_cmd)),)
dl_cmd	+= -qNO
else
undefine dl_cmd
$(warning Need curl or wget to download files)
endif
endif

# counting on install unlinking the destination file before copying

INSTADM	:= $(INSTALL) -o $(uid) -g $(adm_grp)
INSTSYS	:= $(INSTALL) -o $(sys_usr) -g $(sys_grp)
INSTUSR	:= $(INSTALL) -o $(uid) -g $(gid)
LNADM	:= /bin/ln -fs
LNSYS	:= /bin/ln -fs
LNUSR	:= /bin/ln -fs

ifneq	($(uid),0)
INSTSYS	:= @echo $(INSTSYS)
LNSYS	:= @echo $(LNSYS)
endif

ifneq	($(adm_grp),$(adm_grp))
INSTAF	:= $(INSTADM) -m 0664
INSTAL	:= $(LNADM)
INSTAX	:= $(INSTADM) -m 0775
else
INSTAF	:= $(INSTADM) -m 0644
INSTAL	:= $(LNADM)
INSTAX	:= $(INSTADM) -m 0755
endif

INSTSF	:= $(INSTSYS) -m 0644
INSTSL	:= $(LNSYS)
INSTSX	:= $(INSTSYS) -m 0755

INSTUF	:= $(INSTUSR) -m 0644
INSTUL	:= $(LNUSR)
INSTUX	:= $(INSTUSR) -m 0755

# files to be installed from downloads defined elsewhere
dl_tgts	:= /usr/local/bin/rmate /usr/local/bin/rebar /usr/local/bin/rebar3

# these will be wildcard patterns, sort to remove duplicates
sh_etc	:= $(sort profile ksh.kshrc bashrc kshrc shrc zshenv zprofile zshrc)
sh_loc	:= $(sort sh.* env.local)
sh_usr	:= $(sort $(filter-out ksh.kshrc, $(sh_etc)) \
		bash_profile *login *logout)

h_srcs	:= $(wildcard $(foreach pat, $(sh_usr), \
		$(prjdir)/home/$(stype)/$(pat) \
		$(prjdir)/home/$(pat) ))

r_srcs	:= $(wildcard $(foreach pat, $(sh_etc), \
		$(prjdir)/root/$(stype)/etc/$(pat) \
		$(prjdir)/root/etc/$(pat) ))
r_srcs	+= $(wildcard $(foreach pat, $(sh_loc), \
		$(prjdir)/root/$(stype)/usr/local/etc/$(pat) \
		$(prjdir)/root/usr/local/etc/$(pat) ))
ifeq	($(prof_d),true)
r_srcs	+= $(wildcard $(foreach pat, $(sh_loc), \
		$(prjdir)/root/$(stype)/etc/profile.d/$(pat) \
		$(prjdir)/root/etc/profile.d/$(pat) ))
endif

# pattern substitutions are nested to avoid system-specific
# paths winding up as targets
h_tgts	:= $(patsubst $(prjdir)/home/%, $(HOME)/.%, \
		$(patsubst $(prjdir)/home/$(stype)/%, $(HOME)/.%, $(h_srcs)))

r_tgts	:= $(patsubst $(prjdir)/root/%, /%, \
		$(patsubst $(prjdir)/root/$(stype)/%, /%, $(r_srcs)))

# these will get symlinked if source files don't exist
# the definitive list is in the Makefile header

h_tgts	+= $(foreach fn, bash_profile zprofile bashrc kshrc zshrc, $(HOME)/.$(fn))
r_tgts	+= $(foreach fn, zprofile bashrc zshrc, /etc/$(fn))

# sort to remove duplicates
h_tgts  := $(sort $(h_tgts))
r_tgts  := $(sort $(r_tgts))

.PHONY: default home root touch vars

ifeq	($(no_home),)
default :: home
endif

default :: root

touch ::
	@find $(prjdir)/root $(prjdir)/home -type f -exec touch {} \;

# for debugging
vars ::
	@$(MAKE) -Rrnp -C $(prjdir) \
		| egrep '^[[:alnum:]_]+[[:space:]]*:?=' | sort

ifneq	($(home_deprecated),)
home ::
	@echo '***' Clean up manually with command:
	@echo /bin/rm $(home_deprecated)
endif

ifneq	($(root_deprecated),)
root ::
	@echo '***' Clean up manually with command:
	@echo /bin/rm $(root_deprecated)
endif

home :: $(h_tgts)
	@echo '***' Home directory layout:
	@/bin/ls -lh $(sort $(wildcard \
		$(HOME)/.*shrc $(HOME)/.*profile \
		$(HOME)/.*login $(HOME)/.*logout \
		$(h_tgts) $(home_deprecated) ))

ifeq	($(lclinst),true)
home :: $(dl_tgts)
endif

ifneq	($(uid),0)
root ::
	@echo '***' Root commands must be executed manually.
endif

root :: $(r_tgts)
	@echo '***' Root directory layout:
	@/bin/ls -lh $(sort $(wildcard $(r_tgts) $(root_deprecated)))

# for each target directory, single-colon rules for the the
# system-specific source first, then the generic source
# gmake will use the first match only with single-colon rules

/etc/% : $(prjdir)/root/$(stype)/etc/%
	$(INSTSF) $< $@

ifeq	($(prof_d),true)
/etc/% : $(prjdir)/root/etc/%.profile.d
	$(INSTSF) $< $@
endif

/etc/% : $(prjdir)/root/etc/%
	$(INSTSF) $< $@

/usr/local/etc/% : $(prjdir)/root/$(stype)/usr/local/etc/%
	@test -d $(@D) || /bin/mkdir -p $(@D)
	$(INSTSF) $< $@

/usr/local/etc/% : $(prjdir)/root/usr/local/etc/%
	@test -d $(@D) || /bin/mkdir -p $(@D)
	$(INSTSF) $< $@

$(HOME)/.% : $(prjdir)/home/$(stype)/%
	$(INSTUF) $< $@

$(HOME)/.% : $(prjdir)/home/%
	$(INSTUF) $< $@

# create symlinks for files that don't have sources
# NO wildcards - too much chance to screw up!
# the definitive list is in the Makefile header

/etc/bashrc : /etc/shrc
	$(INSTSL) $(<F) $@

/etc/zprofile : /etc/profile
	$(INSTSL) $(<F) $@

/etc/zshrc : /etc/shrc
	$(INSTSL) $(<F) $@

$(HOME)/.bash_profile : $(HOME)/.profile
	$(INSTUL) $(<F) $@

$(HOME)/.zprofile : $(HOME)/.profile
	$(INSTUL) $(<F) $@

$(HOME)/.bashrc : $(HOME)/.shrc
	$(INSTUL) $(<F) $@

$(HOME)/.kshrc : $(HOME)/.shrc
	$(INSTUL) $(<F) $@

$(HOME)/.zshrc : $(HOME)/.shrc
	$(INSTUL) $(<F) $@

# downloaded files are always installed from a temporary copy
# so their timestamps can be checked

ifeq	($(dl_cmd),)
$(warning Skipping download/check of $(dl_tgts))
else
escript	:= $(or $(shell type -P escript 2>/dev/null || true), \
		$(lastword $(sort $(wildcard \
        $(if $(LOCAL_OTP_DIR),$(LOCAL_OTP_DIR),/opt/erlang)/otp-??-ga/bin/escript))))

/usr/local/bin/% : /tmp/ledl/%
	@test -d $(@D) || /bin/mkdir -p $(@D)
	$(INSTAX) -p $< $@

/tmp/ledl/rmate :
	@test -d $(@D) || /bin/mkdir -p $(@D)
	@echo Downloading $@ ...
	@$(prjdir)/bin/github.download textmate rmate bin/rmate $@

# if no escript, sets the hard-coded timestamp from rebar v2.6.4
/tmp/ledl/rebar :
	@test -d $(@D) || /bin/mkdir -p $(@D)
	@echo Downloading $@ ...
	@$(dl_cmd) $@ https://github.com/rebar/rebar/wiki/rebar
	@echo '#!/bin/bash -e' >$@.sts
	@echo 'if [[ -z "$$2" ]]' >>$@.sts
	@echo 'then' >>$@.sts
	@echo '    echo Warning: Missing escript, using hard-coded Rebar file time >&2' >>$@.sts
	@echo '    touch -t 201608311451.36 "$$1"' >>$@.sts
	@echo '    exit $$?' >>$@.sts
	@echo 'fi' >>$@.sts
	@echo 'ts="$$("$$2" "$$1" -V | tr -d _ | \' >>$@.sts
	@echo "    awk '{print substr(\$$4,1,12) \".\" substr(\$$4,13,14)}')\"" >>$@.sts
	@echo 'touch -t "$$ts" "$$1"' >>$@.sts
	@chmod +x $@.sts
	$@.sts "$@" "$(escript)"

/tmp/ledl/rebar3 :
	@test -d $(@D) || /bin/mkdir -p $(@D)
	@echo Downloading $@ ...
	@$(dl_cmd) $@ https://s3.amazonaws.com/rebar3/rebar3

endif

