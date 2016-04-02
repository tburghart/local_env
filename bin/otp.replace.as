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
        otpsrc="$1"
        ;;
    . )
        otpsrc="$(pwd)"
        ;;
    .. )
        otpsrc="$(dirname "$(pwd)")"
        ;;
    * )
        if [[ -d "$1" ]]
        then
            otpsrc="$1"
        else
            otpsrc="$BASHO_PRJ_BASE/$1"
        fi
        ;;
esac
readonly  otp_src

kerl_deactivate 2>/dev/null || true
reset_lenv 2>/dev/null || true

cd "$otpsrc"

unset   ERL_TOP ERL_LIBS MAKEFLAGS V
unset   EXCLUDE_OSX_RT_VERS_FLAG

. "$LOCAL_ENV_DIR/os.type"
. "$LOCAL_ENV_DIR/otp.install.base"
. "$LOCAL_ENV_DIR/otp.source.base"
. "$LOCAL_ENV_DIR/otp.source.version"
. "$LOCAL_ENV_DIR/env.tool.defaults"

hipe_supported()
{
    if [[ $otp_vsn_major -gt 16 && "$os_type" != 'darwin' ]] \
    || [[ $otp_vsn_major -gt 15 && "$os_type" == 'linux' ]]
    then
        return 0
    else
        return 1
    fi
}

if [[ -n "$hipe_modes" ]]
then
    if [[ "$hipe_modes" == *true* ]] && ! hipe_supported
    then
        echo HiPE is not supported on this Release/Platform >&2
        exit 1
    fi
elif hipe_supported
then
    hipe_modes='false true'
else
    hipe_modes='false'
fi

if [[ $otp_vsn_major -lt 17 ]]
then
    add_flags=''
    add_flags+=' -Wno-deprecated-declarations'
    add_flags+=' -Wno-empty-body'
    add_flags+=' -Wno-implicit-function-declaration'
    add_flags+=' -Wno-parentheses-equality'
    add_flags+=' -Wno-pointer-sign'
    add_flags+=' -Wno-tentative-definition-incomplete-type'
    add_flags+=' -Wno-unused-function'
    add_flags+=' -Wno-unused-value'
    add_flags+=' -Wno-unused-variable'

    CFLAGS+="$add_flags"
    CXXFLAGS+="$add_flags"
    export  CFLAGS CXXFLAGS
    unset   add_flags
fi

if [[ "$os_type" == 'darwin' ]]
then
    config_opts='--enable-darwin-64bit --with-cocoa'
    if [[ -d '/usr/include/openssl' ]]
    then
        config_opts+=' --with-ssl'
    else
        xc_toolchains='/Applications/Xcode.app/Contents/Developer/Toolchains'
        unset alt_sys_base
        for n in \
            '/XcodeDefault.xctoolchain/usr/lib/swift-migrator/sdk/MacOSX.sdk'
        do
            if [[ -d "$xc_toolchains/$n/usr/include/openssl" ]]
            then
                alt_sys_base="$xc_toolchains/$n"
                break
            fi
        done
        if [[ -z "$alt_sys_base" ]]
        then
            echo 'error: no OpenSSL headers found!' >&2
            exit 2
        fi
        if [[ $otp_vsn_major -ge 17 ]]
        then
            config_opts+=" --with-ssl --with-ssl-incl=$alt_sys_base/usr"
        else
            config_opts+=" --with-ssl=$alt_sys_base/usr"
        fi
        unset xc_toolchains alt_sys_incl
    fi
else
    config_opts='--enable-64bit --with-ssl'
fi
config_opts+=" --without-odbc"

[[ $otp_vsn_major -ge 16 ]] || config_opts+=' --without-wx'
[[ $otp_vsn_major -lt 17 ]] || config_opts+=' --without-gs'
[[ $otp_vsn_major -lt 17 ]] || config_opts+=' --enable-dirty-schedulers'

ERL_TOP="$(pwd)"
PATH="$ERL_TOP/bin:$PATH"
export  ERL_TOP PATH

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
    build_cfg="--prefix $otp_dest $config_opts $hipe_flag"
    build_log="build.$os_type.$otp_label.txt"
    install_log="install.$os_type.$otp_label.txt"

    $GIT clean -fdqx -e /env -e /.idea/ -e '*.iml' -e '/*.txt'

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
        rm -rf "$otp_dest/bin" "$otp_dest/lib"
    else
        mkdir -m 2775 "$otp_dest"
    fi

    /bin/date >"$install_log"
    echo "$MAKE install" | tee -a "$install_log"
    $MAKE install 1>>"$install_log" 2>&1
    /bin/date >>"$install_log"

    cp -p "$build_log" "$install_log" "$otp_dest"
    [[ -e "$otp_dest/activate" ]] || \
        ln -s "$LOCAL_ENV_DIR/otp.activate" "$otp_dest/activate"
done
