#!/bin/sh

yum check-update
if [[ $? -eq 100 ]]; then
        echo "There are updates"
        yum -y update
        echo now we will reboot
        reboot
fi

if [[ $? -eq 0 ]]; then
        echo "No updates... We're good"
fi
