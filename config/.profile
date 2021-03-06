# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Platform-specific actions
if $(echo `uname -n` | grep -q DESKTOP)
then
    # WSL
    # exclude hostname from prompt
    export PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
    # set prompt: "lxvm .../repos/misc main $"
    #export PROMPT_DIRTRIM=2
    #export PS1="\[\033[01;32m\]\u \[\033[01;34m\]\w\[\033[90m\]\$(git branch 2>/dev/null | sed -n \"s/^*//p\" )\[\033[00m\] \$ "
    # set starting directory
    cd $HOME
    # script to switch windows terminal theme
    ~/wt_auto_theme.ps1
fi
