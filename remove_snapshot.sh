#!/bin/sh
set -e

if [ $# -ne 1 ] ; then
        echo "Please give the subvolume name"
        exit 1
fi

subv=$1

sed -i "\# $subv #d" /etc/cron.hourly/btrfs-snap
sed -i "\# $subv #d" /etc/cron.daily/btrfs-snap
sed -i "\# $subv #d" /etc/cron.weekly/btrfs-snap

exit 0