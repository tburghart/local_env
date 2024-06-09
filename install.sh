#!/bin/bash -e
# ========================================================================
# Copyright (c) 2014-2024 T. R. Burghart.
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
#   ~/.profile
#   ~/.shrc
#   ~/.bash_profile     -> ~/.profile
#   ~/.bashrc           -> ~/.shrc
#   ~/.kshrc            -> ~/.shrc
#   ~/.zprofile         -> ~/.profile
#   ~/.zshrc            -> ~/.shrc
#   ~/etc/shell/sh.*
#
umask 022

sys=$(/usr/bin/uname -s)
uid=${EUID:-$(/usr/bin/id -u)}

src="$(cd "$(dirname "$0")" && pwd)"
cp='/bin/cp'
[[ $sys != Darwin ]] || cp+=' -X'

declare -a remove
remove+=( ~/.zshenv )
if [[ $uid -eq 0 ]]
then
    remove+=( /etc/kshrc )
    remove+=( /etc/zshenv )
    remove+=( /etc/profile.d/zzz_local.sh )
    remove+=( /usr/local/etc/sh.local )
    remove+=( /usr/local/etc/bash.term.prompt )
    remove+=( /usr/local/etc/zsh.term.prompt )
fi

run()
{
    echo '==>' "$@"
    "$@"
}

[[ "$PWD" -ef "$src" ]] || run cd "$src"
/bin/rm -rf ~/etc/shell
run /bin/mkdir -p ~/etc/shell

run $cp home/profile ~/.profile
run $cp home/shrc ~/.shrc
cd home/etc/shell
for f in sh.*
do
    # ensure we strip EAs
    echo '==>' $cp home/etc/shell/$f ~/etc/shell/$f
    /bin/cat $f > ~/etc/shell/$f
done
cd "$src"

run /bin/ln -sf .profile ~/.bash_profile
run /bin/ln -sf .profile ~/.zprofile

run /bin/ln -sf .shrc ~/.bashrc
run /bin/ln -sf .shrc ~/.kshrc
run /bin/ln -sf .shrc ~/.zshrc

for f in "${remove[@]}"
do
    if [[ -f "$f" ]]
    then
        run /bin/rm -f "$f"
    fi
done
