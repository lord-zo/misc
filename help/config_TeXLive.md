Last updated: 13/02/2021

# TeXLive

All serious TeX users should know that the TeX project distributes packages
from [CTAN](ctan.org) (Comprehensive TeX Archive Network) and is maintained
by the [TUG](tug.org) (TeX Users Group).
So regardless of what TeX distribution you use, all the packages are
delivered from a CTAN mirror.

Depending on your operating system, there are various TeX distributions
available to you.
Depending on how much control you want over what your TeX distribution
installs, there are various TeX distributions available to you.
If you want to know all there is to TeX, TeXLive is the right distribution.
All the other distributions are basically a wrapper to TeXLive and may
include some more sophisticated package manager.
And if you like to use Overleaf, you should know it is running TeXLive
in the background.

TeXLive can be installed for a user or as root.
This just depends on who is going to use it, who is allowed to 
install packages, and in what folder TeXLive is installed.
I recommend a user installation if you are the only user of TeX on your
computer.

## User installation of TeXLive from tug.org

To do this, get the latest TeXLive installer from tug.org, and unzip it.
Then cd into the unzipped directory and run `$ perl install-tl`
(not as root).
This will start the command line installer whose interface you should try
to figure out as it is not a GUI.
Then choose the installation scheme: scheme-basic should suffice if you 
intend to add on packages later.
Then change the installation directory to some folder you have permissions in
such as `~/texlive/YYYY`
Then adjust any options, such as letter size pages.
You can try to activate the option to create symlinks in default directories,
but this likely won't work unless you ran the installer as root.
When ready, run the installer.

Afterwards, since the installation directories weren't symlinked, commands
like `tlmgr` won't work.
Instead add these appropriate folders to your path, in your `.profile` 
or `.bashrc`:

```
export PATH=$PATH:~/texlive/2020/bin/x86_64-linux
export MANPATH=$MANPATH:~/texlive/2020/texmf-dist/doc/man
export INFOPATH=$INFOPATH:~/texlive/2020/texmf-dist/doc/info
```

then `tlmgr` and all the TeX help and tools will be available.
You can also ask `tlmgr` to symlink these for you in one of the `/usr/`
directories with `$ sudo tlmgr path add`, but don't because your life
will be easier if `tlmgr` doesn't ask for root permissions every time
you install some package.

`tlmgr` is the package manager for TeXLive.
It will be your friend, so at least skim its info or man pages.

## User installation of TeXLive from apt

You can install TeXLive from apt, but best to do so only on Debian testing
or if there is an up-to-date backport of TeXLive to your distribution.
Otherwise you may get an out-dated version of TeXLive it is harder to 
manage as the mirrors may become out-of-date.
To install a reasonably equipped version of TeXLive with common packages
for LaTeX,`$ apt install texlive` should suffice.
Debian will always run `tlmgr` in user mode (it says so in the `tlmgr` man
page), but to install your own packages you first need to run 
`$ tlmgr init-usertree`.
You can then use `tlmgr` to install packages, collections, and schemes
as per your needs.
Debian is courteous and sets up all the man and info pages for you.


# Sources

_**RTFM**_
