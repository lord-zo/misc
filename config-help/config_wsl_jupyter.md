Last updated: 13/02/2021

# How to automatically open Jupyter Notebooks from WSL2

TL;DR `$ cp misc/config/.jupyter/ ~/.jupyter`

If I ever open a web browser from WSL2, it is usually a Jupyter Notebook.
I'll explain how to configure Jupyter to use the browser you've setup.
Start by creating a configuration file for your Jupyter server for Jupyter
Lab.

```
$ jupyter server --generate-config
```

I am assuming you have a recent version of Jupyter because there is a
[migration](https://jupyter-server.readthedocs.io/en/stable/operators/migrate-from-nbserver.html)
to using Jupyter server for all Jupyter applications (notebook, lab).
However, at the moment I still need a separate configuration file for
Jupyter notebook because it doesn't use the server configuration file
despite the fact it might be soon.

## Telling Jupyter where to find the browser

I would recommend that you edit the configuration file, stored by default
in `~/.jupyter/jupyer_server_config.py`.

### Using configuration file 

In particular, set `c.ServerApp.browser = '<path to browser executable> %s'`.
Assuming `x-www-browser` is a symlink to your browser on the path,
we may use it as the `<path to browser executable>`.

It is very important that you include the ` %s`, otherwise it won't work.
Explanation [here](https://stackoverflow.com/questions/62484888/how-to-change-the-default-browser-to-microsoft-edge-for-jupyter-notebook-in-wind).

### Using python defaults

You won't need to use this if you've done the previous step but anyways:

The text above the `c.ServerApp.browser` explains this, but instead 
of specifying the browser in the configuration file you may also set
the `BROWSER` variable used by python's `webbrowser` module, adding it
to your `.bashrc` or `.profile` (the former is run for every bash shell
opened by you, the later is run only on login shells (i.e. when you
yourself start the shell)).

```
$ echo "export BROWSER=x-www-browser" >> ~/.profile
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
`# c.ServerApp.use_redirect_file = True` to
`c.ServerApp.use_redirect_file = False` in the configuration file.

Jupyter applications will now open seamlessly in a Windows browser from WSL2.

# Configuration files 

```
$ cat ~/.jupyter/jupyter_server_config.py
c.ServerApp.browser = 'x-www-browser %s'
c.ServerApp.use_redirect_file = False

$ cat ~/.jupyter/jupyter_notebook_config.py
c.NotebookApp.browser = 'x-www-browser %s'
c.NotebookApp.use_redirect_file = False
```

# Sources

- [Jupyter Configuration](https://jupyter.readthedocs.io/en/latest/use/config.html)
