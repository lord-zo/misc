# Lessons from terminal sessions

## Command substitution can be better-suited than pipes

```
$ echo $(ls)
bin docs repos 
```

```
$ echo `ls`
bin docs repos 
```

Backticks are the more portable option but cannot be nested.

## Quoted command substitution preserves newlines and whitespace

```
$ echo "$(ls)"
bin
docs
repos
```

## echo doesn't take in stdout as stdin

```
$ ls | echo
```

## cat takes prints stdout to stdin

```
$ ls | cat
bin
docs
repos
```
