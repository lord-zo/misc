# LXVM-DEFINED ALIASES
# ---INTERACTIVE NO CLOBBERING TO PROTECT FILES---
alias cp='cp -i'
alias mv='mv -i'
# ---command line history---
alias r='fc -s'

# Platform-specifc aliases
if $(echo `uname -n` | grep -q DESKTOP)
then
    # WSL
    # ---Directories---
    WHOME=/mnt/c/Users/lxvm
    alias win="cd ${WHOME}"
    alias doc="cd ${WHOME}/Documents"
    alias db="cd ${WHOME}/Dropbox"
    alias surf="cd '${WHOME}/Dropbox/Inverse Design UROP S21'"
    # ---Python---
    alias python=python3
    # ---Julia---
    alias jdoc='explorer.exe $(wslpath -w /usr/share/doc/julia/html/en/index.html)'
else
    # Linux
    # ---Directories---
    alias db="cd ${HOME}/Dropbox"
    alias surf="cd '${HOME}/Dropbox/Inverse Design UROP S21'"
    # ---Julia---
    alias jdoc="xdg-open /usr/share/doc/julia/html/en/index.html"
fi
