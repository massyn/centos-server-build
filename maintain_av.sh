#!/bin/sh

# == check if clamav is installed
rpm -q clamav | grep -Eq "^clamav-"
if [[ $? -ne 0 ]]; then
        echo "Installing clamav..."
        yum install -y clamav
fi

# == update the AV database
/usr/bin/freshclam

# == run the AV scan
/usr/bin/clamscan -o -r -i /

