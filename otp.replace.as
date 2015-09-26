#!/bin/ksh -e

typeset -ir makejobs='5'
typeset -ir verbosity='0'

usage()
{
    echo "Usage: ${0##*/} otp-name-or-path otp-inst-label" >&2
    exit 1
}

[[ $# == 2 ]] || usage
[[ "$2" != */* ]] || usage

typeset -lr otp_name="${2}"

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

[[ -z "$(whence -v kerl_deactivate 2>/dev/null)" ]] || kerl_deactivate
[[ -z "$(whence -v reset_lenv 2>/dev/null)" ]] || reset_lenv

cd "$otpsrc"

unset   ERL_TOP ERL_LIBS MAKEFLAGS

. "$LOCAL_ENV_DIR/os.type"
. "$LOCAL_ENV_DIR/otp.install.base"
. "$LOCAL_ENV_DIR/otp.source.version"

arch_flags='-m64 -march=core2 -mcx16'
arch_flags='-m64 -march=native -mcx16'
case "$os_type" in
    darwin )
        osx_ver="$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f1,2)"
        arch_flags+=" -arch x86_64 -mmacosx-version-min=$osx_ver"
        ccands='icc /usr/bin/cc gcc cc'
        cccands='/usr/bin/c++ g++ c++'
        config_os='--enable-darwin-64bit --with-cocoa'
        ;;
    linux )
        ccands='icc gcc cc'
        cccands='g++ gcc c++'
        config_os='--enable-64bit'
        ;;
    freebsd )
        ccands='icc clang37 /usr/bin/cc gcc cc'
        cccands='/usr/bin/c++ g++ c++'
        config_os='--enable-64bit'
        ;;
    * )
        ccands='cc gcc'
        cccands='c++ g++'
        config_os='--enable-64bit'
        ;;
esac
for c in $ccands
do
    CC="$(whence -p $c || true)"
    [[ -z "$CC" ]] || break
done
if [[ "${CC##*/}" == icc || "${CC##*/}" == clang* ]]
then
    CXX="$CC"
else
    for c in $cccands $CC
    do
        CXX="$(whence -p $c || true)"
        [[ -z "$CXX" ]] || break
    done
fi
unset   c ccand cccand
[[ -n "$LANG" ]] || LANG='C'
LDFLAGS="$arch_flags -O4"

CFLAGS="$arch_flags -O3"
if [[ $otp_vsn_major -lt 17 ]]
then
    CFLAGS+=' -Wno-deprecated-declarations'
    CFLAGS+=' -Wno-empty-body'
    CFLAGS+=' -Wno-implicit-function-declaration'
    CFLAGS+=' -Wno-parentheses-equality'
    CFLAGS+=' -Wno-pointer-sign'
    CFLAGS+=' -Wno-tentative-definition-incomplete-type'
    CFLAGS+=' -Wno-unused-function'
    CFLAGS+=' -Wno-unused-value'
    CFLAGS+=' -Wno-unused-variable'
fi
CXXFLAGS="$CFLAGS"

export  CC CFLAGS CXX CXXFLAGS LANG LDFLAGS

config_opts="$config_os --with-ssl --without-odbc"

[[ $otp_vsn_major -ge 16 ]] || config_opts+=' --without-wx'
[[ $otp_vsn_major -lt 17 ]] || config_opts+=' --without-gs'
[[ $otp_vsn_major -lt 17 ]] || config_opts+=' --enable-dirty-schedulers'

ERL_TOP="$(pwd)"
PATH="$ERL_TOP/bin:$PATH"
export  ERL_TOP PATH

for hipe in false true
do
    if $hipe
    then
        otp_label="$otp_name-h1"
        hipe_flag='--enable-hipe'
    else
        otp_label="$otp_name-h0"
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
