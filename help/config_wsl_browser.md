Last updated: 13/02/2021

# How to configure a web browser in WSL2 Debian

You have options to use the Windows browser you are familiar with in WSL2:

## Simple

The easiest is to symlink your Windows browser to some place on `PATH`:

```
$ ln -s <path to browser executable> ~/bin/win-www-browser
```

Assuming `~/bin` is on your path, `win-www-browser` will open the browser.
In my case, using the Microsoft Edge browser, `<path to browser executable>`
would be `"/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"`
with the quotes (because Windows likes spaces and Unix doesn't).

## Sleek

To integrate your web browser with Debian's operating system so that it 
is available to other applications, you may "install" your Windows browser
in the Debian `update-alternatives` system:

```
$ sudo update-alternatives --install "/usr/bin/win-www-browser" "win-www-browser" <path to browser executable> 0
```

This will create a symlink called `/etc/alternatives/win-www-browser` to
`<path to browser executable>` and another symlink 
`/usr/bin/win-www-browser` to `/etc/alternatives/win-www-browser`.
Now Debian applications which look for a browser will look for these 
alternatives.
For example, the default `sensible-browser` utility will find the browser
you've installed and open it.

If you have multiple Windows browsers you want to use, you can install
them under the same alternative and then use the `update-alternatives`
system to configure which one to use.

However, you should note that it is more typical to name the alternative
`x-www-browser` (for GUI browsers) or `www-browser` (for text-editor
browsers) since these are the alternatives applications are usually
looking for.
I have named the alternative `win-www-browser` to make clear it is a
Windows application, and because I rarely open a browser from a terminal.


# Sources

- [Debian Alternatives](https://wiki.debian.org/DebianAlternatives)
