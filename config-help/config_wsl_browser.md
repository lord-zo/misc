Last updated: 13/02/2021

# How to configure a web browser in WSL2 Debian

You have options to use the Windows browser you are familiar with in WSL2:

## Simple

The easiest is to symlink your Windows browser to some place on `PATH`:

```
$ ln -s <path to browser executable> ~/bin/www-browser
```

Assuming `~/bin` is on your path, `$ www-browser` will open the browser.
In my case, using the Edge browser, `<path to browser executable>`would be
`"/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"`
with the quotes (because Windows likes spaces and Unix doesn't).

## Sleek

To integrate your web browser with Debian's operating system so that it 
is available to other applications, you may "install" your Windows browser
in the Debian `update-alternatives` system:

```
$ sudo update-alternatives --install /usr/bin/www-browser www-browser <path to browser executable> 0
```

This will create a symlink called `/etc/alternatives/www-browser` to
`<path to browser executable>` and another symlink 
`/usr/bin/www-browser` to `/etc/alternatives/www-browser`.
Now applications which look for a browser can use this one by default.
For example `xdg-open` is a common utility which uses `www-browser`.

If you have multiple Windows browsers you want to use, you can install
them under the same alternative and then use the `update-alternatives`
system to configure which one to use.

# Sources

- [Debian Alternatives](https://wiki.debian.org/DebianAlternatives)
