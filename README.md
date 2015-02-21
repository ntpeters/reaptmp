# reaptmp
This script cleans the `/tmp` directory of old files once it reaches a certain threshold
of disk usage.  Each disk usage threshold selects a different age threshold used to choose
which files to delete.  The higher the disk usage, the more agressive the set age threshold
will be.

Reaptmp was inspired by the similar `tmpreaper` tool, but is geared more towards those with
`/tmp` mounted as its own `tmpfs` partition.

##Installation
Ideally this script should be installed as a cron job under root:

1.  Copy `reap.sh` to `/usr/local/sbin`
2.  Add the included `reapcron` as a crontab under root

This will cause the script to run every 15 minutes to keep `/tmp` in check.
Log output of each run can be found at: `/var/log/reaptmp.log`
