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

# Summary

The functionality of these shell scripts is made available in
the following executables:
- `backup.sh`: This actually makes a daily backup
- `backup_restore.sh`: This restores some archive files
- `backup_clean.sh`: This removes old files from the archive
For more details, read the scripts since they are quite short
and the behavior of certain calls to tar is controlled by these.
Feel free to fiddle with them

The majority of the internals of these scripts are contained in:
- `backup_utils.`: This contains common and useful archival functions
- `backup_brains.sh`: This automates making archive filenames
- `backup_graphs.sh`: This navigates the archive dependency graph

Please do not run these scripts using bash - there may be all
sorts of baffling errors due to its POSIX incompliance in places.
I tested this script using dash, in case you can find it too,
but I'm not going to make any claims that this is truly portable.
Just check which shell `/bin/sh` points to.

The easiest way to automate the backups in WSL is to use
the Windows Task Scheduler to run the script using the 
`wsl` command on a daily basis.
If you try to make backups more frequently, the script asks for your input.

# Implementation

The scripts only provide an implementation of (up to) 3-level backups
because anything more seems unlikely for personal file backups.
Here is a table showing the frequency of backups made by the scripts
when the level parameter is set to a particular value:

```
| Level | Frequency of full backups |
| ----- | ------------------------- |
|   0   | Daily                     |
|   1   | Weekly                    |
|   2   | Monthly                   |
|   3   | Quarterly                 |
|   4   | Yearly                    |
```

The archive created by `backup.sh` has a graph-like structure.
Here is an ascii drawing of what the file structure roughly looks like:

```
x is a .tar (Tape ARchive) file
o is a .snar (SNapshot ARchive) file with metadata about the archive
-| are branches in the graph which indicate dependencies
Symbols in the same column are created at the same time

| Level |                       Archive structure                         |
| ----- | ... >----------------------> Time >-----------------------> ... |
|       | ...                                                         ... |
|   3   | ...      o-x-x-x o-x-x-x o-x-x-x   o-x-x-x o-x-x-x o-x-x-x  ... |
|       | ...      |       |       |         |       |       |        ... |
|   2   | ...    o-x-------x-------x       o-x-------x-------x        ... |
|       | ...    |                         |                          ... |
|   1   | ...  o-x-------------------------x                          ... |
|       | ...  |                                                      ... |
|   0   | ...  x                                                      ... |
|       | ...                                                         ... |
| ----- | ... >----------------------> Time >-----------------------> ... |
```

**Note:** when you follow a branch down and left, and extract in reverse
order (from bottom left to top right) all the archives (x's) along that
path, you recover the filesystem on that branch.

**Note:** a snapshot "o" at level N>1 is a copy of a snapshot at level N-1
after making the level N-1 archive with the level N-1 snapshot. 
If N=1 was created with the full archive (level 0) or if N>1.
Thus a level N snapshot provides metadata for level N archives.

**Note:** for illustrative purposes, the number of nodes per branch
is shorter than what it would be, but this illustrates the connections
between the archive files and their metadata as the archive is incremented. 
To obtain the graph for a level N-M archive, truncate the rows for levels 
N, N-1, ..., to N-M+1 from the graph.

# Tests

A test function `test_brains` is included in `backup_brains.sh`
so you can verify that `backup.sh` works ahead of time.

```
$ . backup_brains.sh
$ test_brains
| YYYY_Q_MM_WW_D | 0 1 2 3 4 | I |
| -----date----- | --level-- | - |
| 2020_1_01_01_1 | x o       | 1 |
| 2020_1_01_01_2 |   x o     | 1 |
| 2020_1_01_01_3 |     x o   | 1 |
| 2020_1_01_01_4 |       x o | 1 |
| 2020_1_01_01_5 |         x | 1 |
| 2020_1_01_01_6 |         x | 1 |
| 2020_1_01_01_7 |         x | 1 |
| 2020_1_01_02_1 |       x o | 1 |
| 2020_1_01_02_2 |         x | 1 |
| 2020_1_01_02_3 |         x | 1 |

# Output Truncated here

```

To test the other scripts, try out the examples in their command-line help
on the test files.

**Note:** You may also supply a file to the drawing function
in `backup_utils.sh`, `draw_arxv` which will emphasize the
marks in the same day and level as archive filenames in the file.

# Inspiration
- https://stephenreescarter.net/automatic-backups-for-wsl2/
