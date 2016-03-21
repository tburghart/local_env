# Local Environment Setup

_**WARNING:**
These files are maintained strictly for use in my own environment.
If you find them helpful, cool, but they're here basically just so I can
point people to them and say "here's how I do it."
The odds of them being how YOU want to do it are sketchy, at best._

## Basic Information

I develop software for a living, and at present my primary languages are
Erlang, C, C++, and a LOT of shell scripts.
The stuff in here is used across numerous Unix-y systems.
Despite misgivings, I've pretty much settled on Bash as my default shell, but
I write most significant scripts to use Ksh.
That may be changing slowly, but back in the olde days Ksh had some significant
benefits over Bash, and I've just stuck with it.

## Where The Pieces Go

This directory lives at `$LOCAL_ENV_DIR`, which is set in
[$HOME/.profile](home/profile) and included in my `$PATH`.
The files in the [home] subdirectory here are installed in my `$HOME`
directory with `.` prepended to their names, becoming the initializers
of my shell environment.

## Per-Project Environment

Among the myriad custom commands in my environment is `lenv`, for Load
ENVironment file.  If there's a file named `env` in the current directory
when this command runs, it is sourced into the current shell, allowing it to
set up yet more custom commands.  It also has a reset capability, so if I
`cd` to a different directory and run `lenv` again (or use `cdl` instead of
`cd ... && lenv`) it unloads the previous environment and loads the new one.

Since a lot of the projects I work on are different versions of the same
packages, `lenv` is often a symbolic link to one of the `env...shared` files
in this directory, so I can maintain them in a single place.

## Other Stuff

There's a bunch of other stuff in here as well, and you're welcome to prowl
around and see if anything catches your eye.  There aint no documentation, and
that's not likely to change.

## License

To the extent anyone cares, consider it all covered by this BSD-ish [LICENSE].
