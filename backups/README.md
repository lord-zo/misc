# Backups (on WSL)

[GNU Tar](https://www.gnu.org/software/tar/)
is an old-school archiving utility used all the time.
Here I write a script and configuration file to use it
for backing up parts of the WSL distro to someplace on
the windows path where something like OneDrive or 
Google Drive sync can magically store my files in the 
cloud.

I write my own script because it might be helpful eventually.
However, you should only trust this as much as you trust tar,
and the security of your backups, because there is no guarantee
that bugs or issues break the backup process.

Otherwise, there is other software to do basically the
same thing.
For instance, the Debian package `tar-scripts` provides
some backup scripts.
But for the life of me, I can't figure out how to use it
effectively because it abstracts away (however slightly)
from the actual process of backing up and has options
I don't understand (and probably don't need to understand
either), so this is an attempt to use the basics.
All things considered, it wouldn't be so hard to read the
GNU backup scripts and cherry-pick what I want, but what
mechanic doesn't want to build their own wheel?

TODO:
- Create a recovery script to restore a particular state from the archive
- Create a script to clean old files from the archive

The easiest way to automate the backups in WSL is to use
the Windows Task Scheduler to run the script using the 
`wsl` command on a daily basis.

# Implementation

The archive created by `backup.sh` has a graph-like structure.
Here is an ascii drawing of what the file structure roughly looks like:

```
x is a .tar file
o is a .snar file with metadata about the archive
xo is a pair of .tar and .snar files created the same day
_/-|\^>< are lines or connectors to draw the graph

| Level |                Archive structure                     |
| ----- | >-------------------> Time >-------------------> ... |
| 0     |    x->x->x   x->x   x->x  x->x   x->x   x->x   x ... |
|       |    |         |      |     |      |      |      | ... |
| 1     |  o-^      xo-^   xo-^   o-^   xo-^    o-^   xo-^ ... |
|       |  |        |      |      |     |       |     |    ... |
| 2     |  o--------^------^      xo----^       o-----^--> ... |
|       |  |                      |             |          ... |
| 3     | xo----------------------^            xo--------> ... |
| ----- | >-------------------> Time >-------------------> ... |

Notes: for illustrative purpose, the number of nodes per branch
is much shorter than what it would really be, but this illustrates
the connections between the archive files and their metadata as the
archive is incremented. To obtain the graph for a level less than 3,
truncate the desired number of rows from the bottom, and add an x
to ever solo o on the new bottom row.
```

The scripts only provide an implementation of (up to) 3-level backups
because anything more seems unlikely for personal file backups.
Here is a table showing the frequency of backups made by scripts of each level.

```
| Level | Frequency of full backups |
| ----- | ------------------------- |
| 0     | Daily                     |
| 1     | Weekly                    |
| 2     | Monthly                   |
| 3     | Yearly                    |
```

# Inspiration
- https://stephenreescarter.net/automatic-backups-for-wsl2/
