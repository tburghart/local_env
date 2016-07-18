#!/bin/bash -e
# ========================================================================
# Copyright (c) 2015-2016 T. R. Burghart.
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
    echo "Usage: $sname local-otp-release-name (under 'local' install path)" >&2
    echo "       * local install path is '$otp_install_base'" >&2
    exit 1
fi

readonly  otp_inst_dir="$otp_install_base/$1" 

if [[ ! -d "$otp_inst_dir" ]]
then
    echo "$sname error: '$otp_inst_dir' is not a directory" >&2
    exit 2
fi
. "$LOCAL_ENV_DIR/otp.install.version" || exit $?

cd "$otp_inst_dir"

readonly  otp_plt_file="$otp_inst_dir/otp.$otp_install_version.plt"

otp_plt_apps='erts'

for dir in lib/erlang/lib/*-*
do
    [[ -d "$dir" && ! -L "$dir" && -d "$dir/ebin" \
    && $(ls -1d $dir/ebin/*.beam 2>/dev/null | wc -l) -gt 0 ]] || continue

    app="${dir##*/}"
    app="${app%%-*}"
    otp_plt_apps+=" $app"
done

echo Creating PLT "$otp_plt_file" ...
"$otp_inst_dir/bin/dialyzer" --quiet --build_plt --output_plt "$otp_plt_file" --apps $otp_plt_apps
