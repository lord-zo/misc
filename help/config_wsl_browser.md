Written by: Lorenzo Van Munoz
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


# How to automatically open Jupyter Notebooks from WSL2

If I ever open a web browser from WSL2, it is usually a Jupyter Notebook.
I'll explain how to configure Jupyter to use the browser you've setup.
Start by creating a configuration file for your Jupyter application

```
$ jupyter <application> --generate-config
```

If you are using Jupyter notebook, replace `<application>` with `notebook`.
If you are using Jupyter lab, replace `<application>` with `lab`.
Each application uses its own configuration file.

## Telling Jupyter where to find the browser

I would recommend that you edit the configuration file, stored by default
in `~/.jupyter/jupyer_<application>_config.py`.

### Using configuration file 

In particular, replace `# c.NotebookApp.browser = ''` with 
`c.NotebookApp.browser = '<path to browser executable>'`.
Assuming `win-www-browser` was setup as before and is on the path,
we may use it as the `<path to browser executable>`.

### Using python defaults

The text above the `c.NotebookApp.browser` explains this, but instead 
of specifying the browser in the configuration file you may also set
the `BROWSER` variable used by python's `webbrowser` module, adding it
to your `.bashrc` or `.profile` (the former is run for every bash shell
opened by you, the later is run only on login shells (i.e. when you
yourself start the shell)).

```
$ echo "export BROWSER=win-www-browser" > ~/.profile
```

## Telling Jupyter to open https://localhost/8888/

By default, Jupyter opens the application in the browser using a `file://`
link for security reasons.
However, in WSL2, Jupyter, which is a Linux application, is using a 
different file system than the Windows browser, so the browser will not
be able to find the `file://` link.
Instead, you can open the Jupyter application using the
`https://localhost/8888/` link display when the Jupyter server is started.

To tell Jupyter to open this link by default, change 
`# c.NotebookApp.use_redirect_file = True` to
`c.NotebookApp.use_redirect_file = False` in the configuration file.

Note that this configuration option is only available in recent versions of
Jupyter.
Jupyter notebooks will now open seamlessly in a Windows browser from WSL2.

# Sources

- [Debian Alternatives](https://wiki.debian.org/DebianAlternatives)
- [Jupyter Configuration](https://jupyter.readthedocs.io/en/latest/use/config.html)
