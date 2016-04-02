#
# System-wide .bashrc file for interactive bash(1) shells.
#
# VERY much bash-specific
#

[[ -n "$PS1" ]] || return

PS1='\t \u@\h \w rc:$?\n\$ '

# Make bash check its window size after a process completes
shopt -s checkwinsize

for f in sh.rc sh.paths sh.aliases bash.term.prompt sh.local 
do
    [ ! -f "/usr/local/etc/$f" ] || . "/usr/local/etc/$f"
done
unset f
