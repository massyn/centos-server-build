#!/bin/sh

function check_php {
        phpini=$1

        echo Checking $phpini

        cat $phpini | grep -v "^;" | grep expose_php | grep -q Off || echo " - expose_php is not set to off"
        cat $phpini | grep -v "^;" | grep "session.cookie_httponly" | grep -q " = 1" || echo " - session.cookie_httponly is not set to 1"
        cat $phpini | grep -v "^;" | grep "session.cookie_secure" | grep -q " = 1" || echo " - session.cookie_secure is not set to 1"
        cat $phpini | grep -v "^;" | grep "session.name" | grep -q "PHPSESSID" && echo " - PHPSESSID is set - change it to something else"
        cat $phpini | grep -v "^;" | grep "session.sid_length" | grep -q "= 26" && echo " - sid_length is too short"

        echo
}



# == find php files
for php in $(find / -name php.ini 2>/dev/null); do
        check_php $php
done
