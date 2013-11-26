#!/bin/sh
set -e

. ./conf

## Install LXC scripts
mkdir -p $root_lxc
mkdir -p $(dirname $template)

echo "lxc lxc/directory string /virt/lxc" | debconf-set-selections
apt-get -y install lxc bridge-utils pwgen debootstrap


## Setup bridge interface
# There is a bug in Debian with Ipv6 addresses
cat >> /etc/network/interfaces <<EOF

auto $bridge
iface $bridge inet static
    address ${ip4_gateway}
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    bridge_maxwait 0

iface $bridge inet6 static
    address ${ip6_gateway}
    netmask 64

EOF
ifup lxc0

## Set the kernel routing parameters
echo "cgroup /sys/fs/cgroup cgroup defaults 0 0" >> /etc/fstab
mount /sys/fs/cgroup

echo net.ipv6.conf.all.forwarding=1 >> /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

## Create Debian template
btrfs subvolume create ${template}_tmp
debootstrap wheezy ${template}_tmp http://http.debian.net/debian

cat > ${template}_tmp/etc/apt/apt.conf.d/99recommends <<EOF
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8, en_GB.UTF-8 UTF-8, fr_FR.UTF-8 UTF-8"  | chroot ${template}_tmp debconf-set-selections
echo "locales locales/default_environment_locale select fr_FR.UTF-8" | chroot ${template}_tmp debconf-set-selections
rm -f ${template}_tmp/etc/locale.gen
chroot ${template}_tmp apt-get -y install locales
chroot ${template}_tmp dpkg-reconfigure -u locales

echo "Europe/Paris" > ${template}_tmp/etc/timezone
chroot ${template}_tmp dpkg-reconfigure -f noninteractive tzdata

mkdir ${template}_tmp/root/.ssh
cp /root/.ssh/authorized_keys ${template}_tmp/root/.ssh
chroot ${template}_tmp apt-get install -y openssh-server
chroot ${template}_tmp /etc/init.d/ssh stop
rm -f ${template}_tmp/etc/ssh/ssh_host_*

chroot ${template}_tmp apt-get clean

btrfs subvolume snapshot -r ${template}_tmp $template
btrfs subvolume delete ${template}_tmp
