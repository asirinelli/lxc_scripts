#!/bin/sh
set -e

if [ $# -ne 1 ] ; then
        echo "Please give the subvolume name"
        exit 1
fi

subv=$1

mkdir $subv/.snapshot
echo /root/btrfs-snap $subv hourly 48 >> /etc/cron.hourly/btrfs-snap
echo /root/btrfs-snap $subv daily 14 >> /etc/cron.daily/btrfs-snap
echo /root/btrfs-snap $subv weekly 8 >> /etc/cron.weekly/btrfs-snap

exit 0