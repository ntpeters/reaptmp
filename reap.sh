#!/usr/bin/env bash

# Cleans the /tmp directory based on amount in use and age of files.
# Intended for use with /tmp directory that has been mounted as a separate
# tmpfs partition.

# Used to check where '/tmp' is mounted
tmp_mount="/tmp"
# Used to check the percentage of used space in '/tmp'
tmp_percent=0

# Check the filesystem of the partition '/tmp' is mounted on
tmp_fstype=$(df /tmp --output=fstype | tail -n +2)
if [[ "$tmp_fstype" != "tmpfs" ]]; then
    # Retrieve the partition '/tmp' resides on
    tmp_mount=$(df /tmp --output=target | tail -n +2)

    # Max size of '/tmp' (in megabytes)
    tmp_max=1024

    # Get the current used space of '/tmp'
    tmp_size=$(du -s /tmp | cut -d $'\t' -f1)
    tmp_size=$(echo $(( $tmp_size/1024 + $(if (( $tmp_size%1024 > 511 )); then echo 1; else echo 0; fi) )) )

    # Calculate used percent of '/tmp'
    tmp_percent=$(printf '%i %i' $tmp_size $tmp_max | awk '{ pc=100*$1/$2; i=int(pc); print (pc-i<0.5)?i:i+1 }')
else
    # Get the percentage of the '/tmp' directory currently in use
    tmp_percent=$(df /tmp --output=pcent | \tail -n +2 | \tr -d ' %')
fi

# Check if 'atime' is enabled on the partition where '/tmp' is mounted
atime_enabled=0
cat /proc/mounts | while read mount_info; do
    fs_type=$(echo "$mount_info" | cut -d ' ' -f1)
    mount_point=$(echo "$mount_info" | cut -d ' ' -f2)
    mount_options=$(echo "$mount_info" | cut -d ' ' -f3)
    if [[ "fs_type" != "none" && "$mount_point" = "tmpmnt" && "$mount_options" != *"noatime"* ]]; then
        atime_enabled=1
    fi
done

# Choose if 'find' should use access time or modified time
find_time_type=""
if [ $atime_enabled -eq 1 ]; then
    find_time_type="-amin"
else
    find_time_type="-mmin"
fi

# Specifies age threshold of files to delete (minutes)
clean_age=""
# Denotes whether the /tmp directory should be cleaned up or not (1 = run cleanup)
cleanup=1

# Choose the age of files that should be cleaned based on how full /tmp is
if (($tmp_percent > 95)); then
    clean_age="0"
elif (($tmp_percent > 90)); then
    clean_age="9"
elif (($tmp_percent > 85)); then
    clean_age="14"
elif (($tmp_percent > 80)); then
    clean_age="19"
elif (($tmp_percent > 75)); then
    clean_age="29"
elif (($tmp_percent > 70)); then
    clean_age="59"
elif (($tmp_percent > 60)); then
    clean_age="89"
elif (($tmp_percent > 50)); then
    clean_age="119"
else
    cleanup=0
fi

# Track number of files cleaned
cleaned_files=0

# Build the 'find' parameter used to search for files of a certain age
find_time_param=""$find_time_type" +"$clean_age""

# Perform cleanup if too much space is in use
if [ $cleanup -eq 1 ]; then
    # Get all file in '/tmp/' older than the specified age
    files=$(find /tmp ""$find_time_param"" -type f)
    # Iterate over all files found in '/tmp'
    while read filename; do
        # Delete file if not in use
        if [[ "$filename" != "" &&  ! $(fuser -s "$filename") ]]; then
            rm -f "$filename"
            # Increment file count if removal returned success
            if [ $? -eq 0 ]; then
                cleaned_files=$(($cleaned_files+1))
            fi
        fi
    done <<< "$files"
fi

# Get timestamp for logging
datetime=$(date +%Y-%m-%d--%H:%M:%S)

# Output run data for logging
echo "["$datetime"] "$tmp_percent"% of /tmp in use - Cleaned "$cleaned_files" files"
