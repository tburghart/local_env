# Local Environment Setup

_**WARNING:**
These files are maintained strictly for use in my own environment.
If you find them helpful, cool, but they're here basically just so I can point people to them and say "here's how I do it."
The odds of them being how YOU want to do it are sketchy, at best._

## Basic Information

I develop software for a living, and at present my primary languages are Erlang, C, C++, and a LOT of shell scripts.
The stuff in here is used across numerous Unix-y systems.
Despite misgivings, I've pretty much settled on [Bash][] as my default shell, but I write most significant scripts to use [Ksh][].
That may be changing slowly, but back in the olde days Ksh had some significant benefits over Bash, and I've just stuck with it.

## Where The Pieces Go

The environment variable `$LOCAL_ENV_DIR` is set in [$HOME/.profile][UsrProf] to point to the [env][EnvDir] subdirectory, so that environment files can be sourced directly via `. $LOCAL_ENV_DIR/some.file.name`.

During startup, `$HOME/.profile` adds the directory resulting from the evaluation of [$LOCAL_ENV_DIR/../bin][BinDir] to the `$PATH`. The files in the [home](home) subdirectory here are installed in the `$HOME` directory with `.` prepended to their names, becoming the initializers of the shell environment. There's more about shells in [SHELLS.md][Shells].

Running `make` (or `gmake` on platforms where the default `make` is not [GNU make][gmake]) installs the files in the `$HOME` directory and echos the commands to install the system-wide files.
If running as `root`, the `[g]make install` target performs the actual installation, but it's advisable to run the default target first and ***carefully*** examine the output before running `install` - installing files that are buggy or otherwise not compattible with your system layout can require a single-user reboot and lots of command-line editing to clean up.

## Per-Project Environment

Among the myriad custom commands in my environment is `lenv` (defined in [$HOME/.shrc][UsrShrc]), for **L**oad **ENV**ironment file. If there's a file named `env` in the current directory when this command runs, it is sourced into the current shell, allowing it to set up yet more custom commands.
It also has a reset capability, so if I `cd` to a different directory and run `lenv` again (or use `cdl` instead of `cd ... && lenv`) it unloads the previous environment and loads the new one.

Since a lot of the projects I work on are different versions of the same packages, `env` is often a symbolic link to one of the `env...shared` files in the [env][EnvDir] directory, so I can maintain them in a single place.

I'm trying to move more and more to separating discrete functionality out into discrete files so I can tinker with them individually, so you'll find a lot of files source other files in here to pick up common functionality.

## Other Stuff

There's a bunch of other stuff in here as well, and you're welcome to prowl around and see if anything catches your eye.
Very little is documented, and that's not likely to change - if I document something, more often than not it's for my own ease of reference.

## License

To the extent anyone cares, consider it all covered by this highly permisive [license][License].

 [Bash]: https://www.gnu.org/software/bash/manual/bash.html
 [Ksh]: https://web.archive.org/web/20130605160033/http://www2.research.att.com/~gsf/man/man1/ksh.html
 [Zsh]: http://zsh.sourceforge.net/Doc/Release/zsh_toc.html
 [gmake]: http://www.gnu.org/software/make/manual/make.html
 [BinDir]: bin
 [EnvDir]: env
 [Shells]: doc/SHELLS.md
 [UsrProf]: home/profile
 [UsrShrc]: home/shrc
 [License]: LICENSE
