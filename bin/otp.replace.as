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
# Build and install/replace an OTP instance from source.
#

readonly  sdir="$(cd "$(dirname "$0")" && pwd)"
readonly  sname="${0##*/}"
readonly  spath="$sdir/$sname"

readonly  makejobs='5'
readonly  verbosity="${V:-0}"

usage()
{
    echo "Usage: $sname [-h{0|1|2}] otp-name-or-path otp-inst-label" >&2
    exit 1
}

case "$1" in
    '-h0' )
        hipe_modes='false'
        shift
        ;;
    '-h1' )
        hipe_modes='true'
        shift
        ;;
    '-h2' )
        hipe_modes='false true'
        shift
        ;;
    * )
        unset hipe_modes
        ;;
esac

[[ $# -eq 2 ]] || usage
[[ "$2" != */* ]] || usage

readonly  otp_name="${2}"

case "$1" in
    */* )
        otp_src_dir="$1"
        ;;
    . )
        otp_src_dir="$(pwd)"
        ;;
    .. )
        otp_src_dir="$(dirname "$(pwd)")"
        ;;
    * )
        if [[ -d "$1" ]]
        then
            otp_src_dir="$1"
        else
            otp_src_dir="$BASHO_PRJ_BASE/$1"
        fi
        ;;
esac

kerl_deactivate 2>/dev/null || true
reset_lenv 2>/dev/null || true

cd "$otp_src_dir"
readonly  otp_src_dir="$(pwd)"

unset   ERL_TOP ERL_LIBS MAKEFLAGS V
unset   EXCLUDE_OSX_RT_VERS_FLAG

for n in \
    os.type \
    otp.install.base \
    otp.source.base \
    otp.source.version \
    env.tool.defaults \
    otp.config.opts
do
    . "$LOCAL_ENV_DIR/$n" || exit $?
done

if [[ -n "$hipe_modes" ]]
then
    if [[ " $hipe_modes " == *\ true\ * ]] && ! $otp_hipe_supported
    then
        echo HiPE is not supported on this Release/Platform >&2
        exit 1
    fi
elif $otp_hipe_supported
then
    hipe_modes='false true'
else
    hipe_modes='false'
fi

ERL_TOP="$(pwd)"
[[ "$PATH" == "$ERL_TOP/bin":* ]] || PATH="$ERL_TOP/bin:$PATH"
export  ERL_TOP PATH

case " $otp_config_opts " in
    *\ --with-odbc[\ =]*)
        ;;
    *\ --without-odbc\ *)
        ;;
    *)
        otp_config_opts+=' --without-odbc'
        ;;
esac

for hipe in $hipe_modes
do
    if $hipe
    then
        otp_label="${otp_name}h"
        hipe_flag='--enable-hipe'
    else
        otp_label="$otp_name"
        hipe_flag='--disable-hipe'
    fi
    otp_dest="$otp_install_base/$otp_label"
    build_cfg="--prefix $otp_dest $otp_config_opts $hipe_flag"
    build_log="build.$os_type.$otp_label.txt"
    docs_log="docs.$os_type.$otp_label.txt"
    install_log="install.$os_type.$otp_label.txt"

    $GIT clean -fdqx -e /env -e /.idea/ -e '*.iml' -e '/*.txt' \
    || $GIT clean -f -f -dqx -e /env -e /.idea/ -e '*.iml' -e '/*.txt' \
    || true

    [[ $makejobs -lt 2 ]] || export MAKEFLAGS="-j$makejobs"
    [[ $verbosity -lt 1 ]] || export V="$verbosity"

    /bin/date >"$build_log"
    env | sort >>"$build_log"
    echo "./otp_build setup -a $build_cfg" | tee -a "$build_log"
    ./otp_build setup -a $build_cfg 1>>"$build_log" 2>&1
    /bin/date >>"$build_log"

    unset   V MAKEFLAGS

    if [[ -d "$otp_dest" ]]
    then
        /bin/rm -rf "$otp_dest/bin" "$otp_dest/lib" "$otp_dest/index.html"
    else
        /bin/mkdir -m 2775 "$otp_dest"
    fi

    /bin/date >"$install_log"
    echo "$MAKE install" | tee -a "$install_log"
    $MAKE install 1>>"$install_log" 2>&1
    /bin/date >>"$install_log"

    $ECP "$build_log" "$install_log" "$otp_dest"
    [[ -e "$otp_dest/activate" ]] || \
        ln -s "$LOCAL_ENV_DIR/otp.activate" "$otp_dest/activate"

    if [[ "$otp_install_base/otp-$otp_src_vsn_major" -ef "$otp_dest" ]]
    then
        /bin/date >"$docs_log"
        echo "$MAKE docs install-docs" | tee -a "$docs_log"
        $MAKE docs install-docs 1>>"$docs_log" 2>&1
        otp.gen.doc.index "$otp_label" >>"$docs_log"
        /bin/date >>"$docs_log"
        $ECP $docs_log "$otp_dest"
    fi
done
