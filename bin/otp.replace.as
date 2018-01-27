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
# Build and install/replace an OTP instance from source.
#

readonly  sdir="$(cd "$(dirname "$0")" && pwd)"
readonly  sname="${0##*/}"
readonly  spath="$sdir/$sname"

readonly  makejobs='5'
readonly  verbosity="${V:-0}"

# EQC install script taking a destination OTP installation directory.
# Do NOT define this without an active license!
# readonly  qc_inst='/opt/QuickCheck/install_qc'

. "$LOCAL_ENV_DIR/otp.install.base" || exit 1

usage_exit()
{
    echo 'Usage:' "$sname" '[options]' '<otp-source-path>' '<local-otp-release-name>*' >&2
    echo "    * under local install path '$otp_install_base'" >&2
    echo 'Options:' >&2
    # keep options in sync with 'otp.update.installs'
    echo '    -h{0|1|2} 0=without HiPE, 1=with HiPE, 2=both, default auto' >&2
    echo '    -d{0|1}   0=force docs off, 1=force docs on, default auto' >&2
    echo '    -p{0|1}   0=force PLT off, 1=force PLT on, default auto' >&2
    exit 1
}

hipe_modes=''
doc_mode=''
plt_mode=''

while [[ "$1" == -* ]]
do
    case "$1" in
        '-d0')  doc_mode='false' ;;
        '-d1')  doc_mode='true' ;;
        '-h0')  hipe_modes='false' ;;
        '-h1')  hipe_modes='true' ;;
        '-h2')  hipe_modes='false true' ;;
        '-p0')  plt_mode='false' ;;
        '-p1')  plt_mode='true' ;;
        *)  echo "$sname: error: illegal switch '$1'" >&2
            usage_exit ;;
    esac
    shift
done
readonly doc_mode plt_mode

[[ $# -eq 2 ]] || usage_exit
[[ "$2" != */* ]] || usage_exit

readonly  otp_name="${2}"

case "$1" in
    .)
        otp_src_dir="$(pwd)"
        ;;
    ..)
        otp_src_dir="$(dirname "$(pwd)")"
        ;;
    *)
        otp_src_dir="$(cd "$1" && pwd)"
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
        echo 'HiPE is not supported on this Release/Platform' >&2
        exit 1
    fi
elif $otp_hipe_supported
then
    hipe_modes='false true'
else
    hipe_modes='false'
fi
readonly hipe_modes

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

if type -P curl 1>/dev/null 2>&1
then
    dl_cmd="$(type -P curl) -SsLRo"
elif type -P wget 1>/dev/null 2>&1
then
    dl_cmd="$(type -P wget) -qNO"
else
    echo "$sname: error: neither curl nor wget found" >&2
    exit 2
fi
unset rebar3_dl

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
    declare -a logs

    $GIT clean -fdqx -e /env -e /env.local -e /.idea/ -e '*.iml' -e '/*.txt' \
    || $GIT clean -f -f -dqx -e /env -e /env.local -e /.idea/ -e '*.iml' -e '/*.txt' \
    || true

    [[ $makejobs -lt 2 ]] || export MAKEFLAGS="-j$makejobs"
    [[ $verbosity -lt 1 ]] || export V="$verbosity"

    printf 'commit:\t' >"$build_log"
    logs+=("$build_log")
    $GIT show-ref --heads --head --hash | head -1 >>"$build_log"
    /bin/date >>"$build_log"
    env | sort >>"$build_log"
    echo "==> ./otp_build setup -a $build_cfg" | tee -a "$build_log"
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
    logs+=("$install_log")
    echo "==> $MAKE install" | tee -a "$install_log"
    $MAKE install 1>>"$install_log" 2>&1
    /bin/date >>"$install_log"

    [[ -e "$otp_dest/activate" ]] || \
        ln -s "$LOCAL_ENV_DIR/otp.activate" "$otp_dest/activate"

    if [[ "$otp_install_base/otp-$otp_src_vsn_major" -ef "$otp_dest" \
    && "$(uname -n | cut -f1 -d.)" != vm[0-9][0-9] ]]
    then
        dflt_mode='true'
    else
        dflt_mode='false'
    fi
    doc="${doc_mode:-${dflt_mode}}"
    if [[ -z "$plt_mode" ]]
    then
        if [[ $otp_src_vsn_major -lt 18 ]] && $dflt_mode
        then
            plt='false'
            printf '!!! %s\n' \
                "Skipping old OTP-$otp_src_vsn_major PLT generation" \
                'Run manually (if you dare) with:' | tee -a "$install_log"
            printf '!!!\t%s\n' "$sdir/otp.gen.plt $otp_label" | tee -a "$install_log"
        else
            plt="$dflt_mode"
        fi
    else
        plt="$plt_mode"
    fi

    if $plt
    then
        echo '==>' "$sdir/otp.gen.plt" "$otp_label" | tee -a "$install_log"
        "$sdir/otp.gen.plt" "$otp_label" 1>>"$install_log" 2>&1
    else
        /bin/rm -f "$otp_dest"/otp.*.plt
    fi
    # Run dialyzer before installing QuickCheck, as the beams are non-debug.
    if [[ -n "qc_inst" && -f "$qc_inst" && -x "$qc_inst" ]]
    then
        echo '==>' "$qc_inst" "$otp_dest" | tee -a "$install_log"
        "$qc_inst" "$otp_dest" 1>>"$install_log" 2>&1
    fi
    /bin/date >>"$install_log"

    if $doc
    then
        /bin/date >"$docs_log"
        logs+=("$docs_log")
        echo "==> $MAKE docs install-docs" | tee -a "$docs_log"
        $MAKE docs install-docs 1>>"$docs_log" 2>&1
        echo '==>' "$sdir/otp.gen.doc.index" "$otp_label" | tee -a "$docs_log"
        "$sdir/otp.gen.doc.index" "$otp_label" >>"$docs_log"
        /bin/date >>"$docs_log"
    fi

    echo '==>' /bin/cp -p "${logs[@]}" "$otp_dest"
    /bin/cp -p "${logs[@]}" "$otp_dest"
done
