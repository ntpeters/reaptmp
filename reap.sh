#!/usr/bin/env bash

# Cleans the /tmp directory based on amount in use and age of files.
# Intended for use with /tmp directory that has been mounted as a separate
# tmpfs partition.

# Get the percentage of the /tmp directory currently in use
tmp_percent=`\df /tmp --output=pcent | \tail -n +2 | \tr -d ' %'`

# Parameter to find controlling the age of files returned
clean_age=""
# Denotes whether the /tmp directory should be cleaned up or not (0 = run cleanup)
cleanup=0

# Choose the age of files that should be cleaned based on how full /tmp is
if (($tmp_percent > 95)); then
    clean_age="-mmin +0"
elif (($tmp_percent > 90)); then
    clean_age="-mmin +9"
elif (($tmp_percent > 85)); then
    clean_age="-mmin +14"
elif (($tmp_percent > 80)); then
    clean_age="-mmin +19"
elif (($tmp_percent > 75)); then
    clean_age="-mmin +29"
elif (($tmp_percent > 70)); then
    clean_age="-mmin +59"
elif (($tmp_percent > 60)); then
    clean_age="-mmin +89"
elif (($tmp_percent > 50)); then
    clean_age="-mmin +119"
else
    cleanup=1
fi

# Perform cleanup if too much space is in use
if [ $cleanup = 0 ]; then
    # Iterate over all files in /tmp of the specified age
    for filename in `find /tmp ""$clean_age"" -type f`; do
        # Delete file if not in use
        if [ ! $(fuser -s "$filename") ]; then
            rm -f "$filename" > /dev/null 2>&1
        fi
    done
fi
