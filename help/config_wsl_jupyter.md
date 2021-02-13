Last updated: 13/02/2021

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
Assuming `win-www-browser` is a symlink to your Windows browser on the path,
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

- [Jupyter Configuration](https://jupyter.readthedocs.io/en/latest/use/config.html)
