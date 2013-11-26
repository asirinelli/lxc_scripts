#!/bin/sh
set -e

. ./conf

echo 1 > /proc/sys/net/ipv4/ip_forward 

iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

iptables -t nat -F
iptables -t nat -A PREROUTING --dst $public_ip4 -p tcp --dport 80 -j DNAT --to-destination ${ip4_template}80


ip6tables -F
ip6tables -P INPUT ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -P FORWARD DROP
ip6tables -A FORWARD -o eth0 -j ACCEPT
ip6tables -A FORWARD -p tcp --dport 22 -j ACCEPT
ip6tables -A FORWARD -p tcp --dport 80 --dst ${ip6_template}80 -j ACCEPT
ip6tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

