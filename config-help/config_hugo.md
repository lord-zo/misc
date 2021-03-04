# Configuring Hugo for Github pages

I tried reading a lot of tutorials about this and none of them got it
quite right so here's my implementation.

Big picture:
- host a website on github pages built by hugo
- use 2 repositories: 
  - public (which github will use to build the site)
  - source (where you will work on the website)
- coordinate these 2 repositories as git submodules

Advantages of this approach:
- hugo will build your site for you
- all your work in the local repository will look like one project
- push changes to source or public directories separately, if useful
- github pages requires you to have the public directory public so that
your website is free for you, but by separating the public and source
directories, you can keep the source directory private if you want

## Starting a hugo website from scratch

Note: I don't intend to explain how to migrate an existing hugo website to 
github. If you are trying to do this, I believe you can figure it out:
you are smart! Maybe this helps you too. 

Note: This is just a demonstration of how you can structure a hugo
but there are certainly more ways than one to do it. I think hugo's
website currently recommends a github action. The focus here is on the
infrastructure/integrating with github and not on the design of the website.

Install hugo and git (all the dependencies you'll need :) )

On github.com, create repositories with the following names:
- `<username>.github.io`, if this is for a [user github page](https://docs.github.com/en/github/working-with-github-pages/about-github-pages#user--organization-pages)
- `<username>.github.io.src`, or whatever you prefer

Start the [hugo website](https://gohugo.io/getting-started/quick-start/).

```
cd ~/repos # or wherever you prefer
hugo new site <username>.github.io.src
```

Start the source repo within

```
cd <username>.github.io.src 
git init
git remote add origin https://github.com/<username>/<username>.github.io.src.git
```

From now on, the key idea will be to use git submodules,
which you should read about on the terminal with `git help submodules`
for a readable explanation or `git help submodule` for more detail.
This allows you to embed one repository inside another without ever
commiting the submodule's contents into the superrepository.

As the hugo quickstart suggests, start by adding a theme as a submodule:

```
git submodule add https://github.com/HelloRusk/HugoTeX.git themes/HugoTeX
```

This creates a submodule in the folder `themes/HugoTeX` cloned from `https://github.com/HelloRusk/HugoTeX.git`.
I just chose that theme, but hugo has [many more](https://themes.gohugo.io/).
Make sure to do this before building the site:

```
echo 'theme = "HugoTeX"' >> config.toml
```

The second and last submodule will be your project site:

```
git submodule add -b main https://github.com/<username>/<username>.github.io.git public
```

This will create a submodule called `public` which will basically be a repo
for `<username>/<username>.github.io` that isn't copied by
`<username>/<userame>.github.io.src`.
The choice for the name `public` is that hugo by default publishes 
the website there.
I've also specified the branch `main` here for clarity.

This is basically all that needs to be setup.
You can build the website

```
hugo -D 
```

and commit your changes to the repositories (both of them)

```
git add . # source
commit -m "first commit"
cd public
git add . # public
commit -m "first commit"
```

I suppose that to see the website you should actually 
turn `<username>/<username>.github.io` into a github page
inside of its settings.
