#!/bin/bash
set -e

. ./conf

if [ $# -ne 2 ] ; then
        echo "Please give a name and and index"
        exit 1
fi

name=$1
id=$2

root=$root_lxc/$name
rootfs=$root"/rootfs"
ip=$ip6_template$id
ip4=$ip4_template$id

hexchars="0123456789ABCDEF"
end=$( for i in {1..6} ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/:\1/g' )
mac="06:06:2F$end"

# password=`pwgen -s -y 32 1`

echo "Creating container '$name' in '$root' with:"
echo "IPv4: $ip4 / IPv6: $ip"
echo "MAC: $mac"
# echo "root password: $password"

mkdir -p $root
btrfs subvolume snapshot $template $rootfs
chroot $rootfs apt-get update
chroot $rootfs apt-get upgrade -y
cat > $root/config << EOF
lxc.tty = 1
lxc.pts = 1024
lxc.rootfs = $rootfs
lxc.utsname = $name
lxc.cgroup.devices.deny = a
# /dev/null and zero
lxc.cgroup.devices.allow = c 1:3 rwm
lxc.cgroup.devices.allow = c 1:5 rwm
# consoles
lxc.cgroup.devices.allow = c 5:1 rwm
lxc.cgroup.devices.allow = c 5:0 rwm
lxc.cgroup.devices.allow = c 4:0 rwm
lxc.cgroup.devices.allow = c 4:1 rwm
# /dev/{,u}random
lxc.cgroup.devices.allow = c 1:9 rwm
lxc.cgroup.devices.allow = c 1:8 rwm
lxc.cgroup.devices.allow = c 136:* rwm
lxc.cgroup.devices.allow = c 5:2 rwm
# rtc
lxc.cgroup.devices.allow = c 254:0 rwm

# mounts point
lxc.mount.entry=proc $rootfs/proc proc nodev,noexec,nosuid 0 0
lxc.mount.entry=sysfs $rootfs/sys sysfs defaults  0 0

lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = $bridge
lxc.network.hwaddr = $mac
lxc.network.ipv4 = $ip4
lxc.network.ipv6 = $ip
lxc.network.veth.pair = lxc-$name
lxc.network.ipv6.gateway = $ip6_gateway
# lxc.network.ipv4.gateway = $ip4_gateway

# drop capabilities
lxc.cap.drop = audit_control audit_write fsetid ipc_lock ipc_owner lease linux_immutable mac_admin mac_override mac_admin mknod setfcap setpcap sys_admin sys_boot sys_module sys_nice sys_pacct sys_ptrace sys_rawio sys_resource sys_time sys_tty_config net_admin syslog
EOF
 
cat > $rootfs/etc/inittab << EOF
id:3:initdefault:
si::sysinit:/etc/init.d/rcS
l0:0:wait:/etc/init.d/rc 0
l1:1:wait:/etc/init.d/rc 1
l2:2:wait:/etc/init.d/rc 2
l3:3:wait:/etc/init.d/rc 3
l4:4:wait:/etc/init.d/rc 4
l5:5:wait:/etc/init.d/rc 5
l6:6:wait:/etc/init.d/rc 6
# Normally not reached, but fallthrough in case of emergency.
z6:6:respawn:/sbin/sulogin
1:2345:respawn:/sbin/getty 38400 console
c1:12345:respawn:/sbin/getty 38400 tty1 linux
EOF

echo nameserver $dns_ip6_1 > $rootfs/etc/resolv.conf
echo nameserver $dns_ip6_2 >> $rootfs/etc/resolv.conf
# echo root:$password | chroot $rootfs chpasswd
chroot $rootfs passwd -l root
mknod -m 660 $rootfs/dev/tty1 c 4 1
chown root:tty $rootfs/dev/tty1

echo $name $ip $ip4 >> /root/containers.txt
chmod 600 /root/containers.txt
ln -s $root/config /etc/lxc/auto/$name

chroot $rootfs dpkg-reconfigure openssh-server
chroot $rootfs /etc/init.d/ssh stop

rm -rf $rootfs/root/.ssh
mkdir $rootfs/root/.ssh
cat /root/.ssh/authorized_keys /root/.ssh/id_rsa.pub > $rootfs/root/.ssh/authorized_keys
chmod 600 $rootfs/root/.ssh/authorized_keys

lxc-start -n $name -d
/root/add_snapshot.sh $rootfs

exit 0
