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

# Inspiration
- https://stephenreescarter.net/automatic-backups-for-wsl2/
