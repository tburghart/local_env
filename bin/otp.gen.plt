#!/bin/bash -e
# ========================================================================
# Copyright (c) 2015-2018 T. R. Burghart.
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
# Generate a central PLT file for an installed OTP instance.
#

readonly  rdir="$(pwd)"
readonly  sdir="$(cd "$(dirname "$0")" && pwd)"
readonly  sname="${0##*/}"
readonly  spath="$sdir/$sname"

. "$LOCAL_ENV_DIR/otp.install.base" || exit $?

if [[ $# -ne 1 ]]
then
    echo "Usage: $sname <local-otp-release-name>*" >&2
    echo "    * under local install path '$otp_install_base'" >&2
    exit 1
fi

readonly otp_inst_dir="$otp_install_base/$1" 

if [[ ! -d "$otp_inst_dir" ]]
then
    echo "$sname error: '$otp_inst_dir' is not a directory" >&2
    exit 2
fi
. "$LOCAL_ENV_DIR/otp.install.version" || exit $?

cd "$otp_inst_dir"

readonly otp_plt_file="otp.$otp_install_version.plt"

otp_plt_apps='erts'

# apps in this list won't be added to otp_plt_apps
readonly plt_skip_apps="$otp_plt_apps"

for dir in lib/erlang/lib/*-*
do
    app="${dir##*/}"
    app="${app%%-*}"

    [[ " $plt_skip_apps " != *\ $app\ * && \
        -d "$dir" && ! -L "$dir" && -d "$dir/ebin" ]] \
    && ls -1 "$dir/ebin" 2>/dev/null | grep -q '\.beam$' || continue

    otp_plt_apps+=" $app"
done
readonly otp_plt_apps

readonly tmp_out="$(mktemp /tmp/ogp.XXXXXXX)"
readonly tmp_tmp="$(mktemp /tmp/ogp.XXXXXXX)"
trap "/bin/rm $tmp_out $tmp_tmp" EXIT

readonly tmp_plt="/tmp/$otp_plt_file"
readonly dst_plt="$otp_inst_dir/$otp_plt_file"

echo Creating PLT "$otp_plt_file" ...
declare -i plt_ret=0

readonly -a cmd=("$otp_inst_dir/bin/dialyzer" --quiet \
    --build_plt --output_plt "$tmp_plt" --apps $otp_plt_apps)

"${cmd[@]}" 1>"$tmp_tmp" 2>&1 || plt_ret=$?

if [[ -s "$tmp_tmp" ]]
then
    # don't trust the return code of various grep implimentations
    grep -Ev '^[[:space:]]*$|\beunit_test:nonexisting_function/0\b' \
        "$tmp_tmp" >"$tmp_out" || true
    # work around a call to nonexistant function in eunit_test
    if [[ $plt_ret -eq 2 && ! -s "$tmp_out" ]]
    then
        plt_ret=0
    fi
fi

if [[ $plt_ret -ne 0 ]]
then
    echo '==>' "${cmd[@]}"
    [[ ! -s "$tmp_out" ]] || cat "$tmp_out" >&2
else
    [[ ! -s "$tmp_out" ]] || cat "$tmp_out"
    /bin/rm -f "$otp_inst_dir"/otp.*.plt
    /bin/mv "$tmp_plt" "$dst_plt"
fi

exit $plt_ret
