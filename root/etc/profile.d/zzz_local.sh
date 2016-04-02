for _zzz_f in sh.rc sh.paths sh.aliases bash.term.prompt sh.local
do
	if [ -f "/usr/local/etc/$_zzz_f" ] && [ -r "/usr/local/etc/$_zzz_f" ]
	then
		. "/usr/local/etc/$_zzz_f"
	fi
done
unset	_zzz_f
