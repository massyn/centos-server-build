#!/bin/bash

# A very basic firewall that blocks all incoming ports, except the ssh and web ports (80 & 443)

# == it has to run as root

if [ `whoami` == "root" ]; then

        # == get the sshd port
        export P=`cat /etc/ssh/sshd_config | grep ^Port | head -1 | awk {'print \$2'}`

        # == flush it all
        iptables -P INPUT ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -F

        # == setup the rules
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A OUTPUT -o lo -j ACCEPT

        iptables -A INPUT -p tcp --dport $P -j ACCEPT
        iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -j ACCEPT

        iptables -I INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        iptables -A INPUT -j DROP

        iptables -L
else
        echo "You are not root.  Run the script as sudo"
fi
