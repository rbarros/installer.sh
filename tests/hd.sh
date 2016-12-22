#!/bin/sh
df -H | grep -vE '^Sist.|^Filesystem|tmpfs|cdrom|udev' | awk '{ print $5 " " $1 }' | while read output;
do
  usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
  partition=$(echo $output | awk '{ print $2 }')
  if [ $usep -ge "90" ]; then
    echo "Running out of space \"$partition ($usep%)\" on $(hostname) as on $(date)"
    #| mail -s "Alert: Almost out of disk space $usep%" contato@main.com
  fi
done
