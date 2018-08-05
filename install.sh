#!/bin/sh

INSTALL_DIR=/usr/local/

# == we must run as root
if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

if [[ ! -d $INSTALL_DIR ]]; then
  echo "Installation directory $INSTALL_DIR does not exist"
  exit 1
fi

cp setup_web.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/setup_web.sh

cp letsencrypt.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/letsencrypt.sh

cp config.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/config.sh

cp cronwrapper.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/cronwrapper.sh

cp maintain_os.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/maintain_os.sh

bash $INSTALL_DIR/config.sh

bash install_crontab.sh
