#!/bin/sh

INSTALL_DIR=/usr/local/

if [[ ! -d $INSTALL_DIR ]]; then
  echo "Installation directory $INSTALL_DIR does not exist"
  exit 1
fi

cp setup_web.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/setup_web.sh

cp config.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/config.sh

cp cronwrapper.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/cronwrapper.sh

bash $INSTALL_DIR/config.sh
