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
People report issues with tar in restoring incremental backups.
Feel free to read about it.
These scripts are not rigorously tested, so if you can find any
bugs feel free to tell me about the issue, and, if you can, the
solution as well.

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
If you try to make backups more frequently, the script asks for your input.

# Implementation

The archive created by `backup.sh` has a graph-like structure.
Here is an ascii drawing of what the file structure roughly looks like:

```
x is a .tar (Tape ARchive) file
o is a .snar (SNapshot ARchive) file with metadata about the archive
-| are branches in the graph which indicate dependencies
Symbols in the same column are created at the same time

| Level |                    Archive structure                     |
| ----- | ... >-------------------> Time >-------------------> ... |
|       | ...                                                  ... |
|   3   | ...     o-x o-x-x o-x-x   o-x o-x-x     o-x-x-x o-x- ... |
|       | ...     |   |     |       |   |         |       |    ... |
|   2   | ...   o-x---x-----x     o-x---x       o-x-------x--- ... |
|       | ...   |                 |             |              ... |
|   1   | ... o-x-----------------x           o-x------------- ... |
|       | ... |                               |                ... |
|   0   | ... x                               x                ... |
|       | ...                                                  ... |
| ----- | ... >-------------------> Time >-------------------> ... |

Note: the script is smart enough to repair some missing nodes,
except for N=0 when it is not possible to recover metadata.

Note: when you follow a branch down and left, and extract in reverse
order (from bottom left to top right) all the archives (x's) indicated by
^ and ' symbols along that branch, you recover the filesystem on that branch.

Note: a snapshot "o" at level N>1 is a copy of a snapshot at level N-1
after making the level N-1 archive with the level N-1 snapshot. 
If N=1 was created with the full archive (level 0) or if N>1.
Thus a level N snapshot provides metadata for level N archives.

Note: for illustrative purposes, the number of nodes per branch
is much inconsistent per level and shorter than what it would be,
but this illustrates the connections between the archive files and 
their metadata as the archive is incremented. 
To obtain the graph for a level N-M, truncate the rows for levels 
N, N-1, ..., to N-M+1 from the graph.
```

The scripts only provide an implementation of (up to) 3-level backups
because anything more seems unlikely for personal file backups.
Here is a table showing the frequency of backups made by the scripts
when the level parameter is set to a particular value:

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
