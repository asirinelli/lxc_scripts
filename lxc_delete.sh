#!/bin/bash
set -e

. ./conf

if [ $# -ne 1 ] ; then
    echo "Please give the container name to be deleted"
    exit 1
fi

name=$1
ip=`grep "^$name " /root/containers.txt | cut -d " " -f 3`
if [[ -z $ip ]]; then 
    echo Container not found.
    exit 1
fi

lxc-stop -n $name
sed -i "/^$name /d" /root/containers.txt

rm $root_lxc/$name/config
rm /etc/lxc/auto/$name
for vol in $root_lxc/$name/rootfs/.snapshot/*; do
    btrfs subvolume delete $vol
done
btrfs subvolume delete $root_lxc/$name/rootfs
rmdir $root_lxc/$name
/root/remove_snapshot.sh $root_lxc/$name/rootfs

exit 0

