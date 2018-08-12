#!/bin/sh

/usr/sbin/service nginx stop
/usr/local/letsencrypt/letsencrypt-auto renew
/usr/sbin/service nginx start
