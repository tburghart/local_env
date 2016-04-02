# System-wide .profile for sh(1)

if [ -x /usr/libexec/path_helper ]; then
	eval `/usr/libexec/path_helper -s`
fi

if [ "${BASH-no}" != "no" ]
then
	[ ! -r /etc/bashrc ] || . /etc/bashrc
else
	for f in sh.rc sh.paths sh.aliases sh.local
	do
		[ ! -f "/usr/local/etc/$f" ] || . "/usr/local/etc/$f"
	done
	unset f
fi
