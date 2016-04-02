# About Shells

This is more a record for my own reference than anything resembling real documentation. If that's what you're looking for, you'll be better served by reading the docs for specific shells. The ones I care about are here:

* [Bash][]
* [Ksh][] *
* [Sh][]
* [Zsh][]

> * AT&T's Ksh links are hopelessly munged, so I point to an archived snapshot of the man page. The Ksh sources are part of the [AT&T AST][AttAst] open source distribution.

## What I Use

For the last decade or so I have begrudgingly accepted that _Bash_ is the Unix-ish world's de facto shell, so that's what I use for the most part in a terminal. I still use _Ksh_ for a lot of shell programming because it has some handy features that Bash doesn't, and because it's just a LOT faster.

_Note that PDKsh doesn't behave the same way that real Ksh does, so any script I write for Ksh may depend on behavior that PDKsh doesn't have._

I work primarily on Macs, using either Apple Terminal or [iTerm][], but I'm _ssh_'d into all manner of systems, and these files are installed on a lot of them, too. My `ssh` configurations, on clients and servers, are generally set up to forward the `$TERM_PROGRAM` environment variable if it's set, so I can use some terminal features to, for instance, display what directory I'm working in accurately.

When some of the files here started out, high-end Unix servers ran at speeds measured in dozens of MHz, so brevity was important. There's still some cruft lying about in the oldest files ([$HOME/.profile][UsrProf] and [$HOME/.shrc][UsrShrc] are prime examples), but these files are shared across so so so many systems that I don't dare to clean the last of it up for fear that some obscure script I wrote decades ago will break six months (or years) later.

## Shell Startup

Herewith are brief descriptions of what files are sourced by what shells in what order on startup. This is very much for me, but hey, other people may find it handy. Most shells behave differently based on what name they are invoked as - the desriptions here assume they are invoked by their base name. When invoked by another name, it's normally expected that they'll act as described for that name, but there are no guarantees.

### Bash

```
if is-login-shell
  if exists /etc/profile
    source /etc/profile
  endif
  if exists $HOME/.bash_profile
    source $HOME/.bash_profile
  else if exists $HOME/.bash_login
    source $HOME/.bash_login
  else if exists $HOME/.profile
    source $HOME/.profile
  endif
ELSE if interactive
  if exists $HOME/.bashrc
    source $HOME/.bashrc
  endif
ELSE if non-interactive
  if exists $BASH_ENV
    source $BASH_ENV
  endif
endif
```

### Ksh

```
if is-login-shell
  if exists /etc/profile
    source /etc/profile
  endif
  if exists $HOME/.profile
    source $HOME/.profile
  endif
endif
if interactive
  if built-with-SHOPT_SYSRC
    if exists /etc/ksh.kshrc
      source /etc/ksh.kshrc
    endif
  endif
  if exists $ENV
    source $ENV
  else if exists $HOME/.kshrc
    source $HOME/.kshrc
  endif
endif
```

### Sh

_**MOST** `sh` implementations these days operate as follows, though the Unix specification only calls for processing the file pointed to by the `$ENV` environment variable._

```
if is-login-shell
  if exists /etc/profile
    source /etc/profile
  endif
  if exists $HOME/.profile
    source $HOME/.profile
  endif
endif
if interactive
  if exists $ENV
    source $ENV
  endif
endif
```

### Zsh

_This is only a simplified version of what Zsh does, but it's sufficient for how I use shells._

```
if exists /etc/zshenv
  source /etc/zshenv
endif
if exists $HOME/.zshenv
  source $HOME/.zshenv
endif
if is-login-shell
  if exists /etc/zprofile
    source /etc/zprofile
  endif
  if exists $HOME/.zprofile
    source $HOME/.zprofile
  endif
endif
if interactive
  if exists /etc/zshrc
    source /etc/zshrc
  endif
  if exists $HOME/.zshrc
    source $HOME/.zshrc
  endif
endif
```

## License

To the extent anyone cares, consider it all covered by this highly permisive [license][License].

 [Bash]: https://www.gnu.org/software/bash/manual/bash.html
 [Ksh]: https://web.archive.org/web/20130605160033/http://www2.research.att.com/~gsf/man/man1/ksh.html
 [Sh]: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/sh.html
 [Zsh]: http://zsh.sourceforge.net/Doc/Release/zsh_toc.html
 [AttAst]: https://github.com/att/ast
 [iTerm]: https://www.iterm2.com
 [BinDir]: ../bin
 [EnvDir]: ../env
 [UsrProf]: ../home/profile
 [UsrShrc]: ../home/shrc
 [License]: ../LICENSE
