#!/bin/bash

# === Build own QPKG. ===
APP_NAME="syncthing"
APP_VERSION=$1
APP_AUTHOR="Syncthing Community"
APP_LICENSE="MPL-2.0"

SUPPORTED_ARCHS=arm64 arm 386 amd64

if [ -z $APP_VERSION ] ; then
    echo "Desired syncthing version missing."
    echo "Example: $0 1.25.0"
fi

cd $(getcfg QDK Install_Path -f /etc/config/qpkg.conf`)

rm -rf "${APP_NAME}"

qbuild --create-env "${APP_NAME}"

cd `getcfg QDK Install_Path -f /etc/config/qpkg.conf`/"${APP_NAME}"
sed -i -e "s/QPKG_NAME=.*/QPKG_NAME=\"${APP_NAME}\"/gI" "qpkg.cfg"
sed -i -e "s/QPKG_VER=.*/QPKG_VER=\"${APP_VERSION}\"/gI" "qpkg.cfg"
sed -i -e "s/QPKG_AUTHOR=.*/QPKG_AUTHOR=\"${APP_AUTHOR}\"/gI" "qpkg.cfg"
sed -i -e "s/#QPKG_LICENSE=.*/QPKG_LICENSE=\"${APP_LICENSE}\"/gI" "qpkg.cfg"

# 	3 (1+2): support both installation and migration
sed -i -e "s/#QPKG_VOLUME_SELECT=.*/QPKG_VOLUME_SELECT=\"3\"/gI" "qpkg.cfg"
#
# sed -i -e "s/#QNAP_CODE_SIGNING/QNAP_CODE_SIGNING/gI" "qpkg.cfg"
# sed -i -e "s/QNAP_CODE_SIGNING=.*/QNAP_CODE_SIGNING=\"1\"/gI" "qpkg.cfg"
#

for ARCH IN $SUPPORTED_ARCHS ; do
    rm -f syncthing/$ARCH/syncthing
    curl https://github.com/syncthing/syncthing/releases/download/v$APP_VERSION/syncthing-linux-$ARCH-v$APP_VERSION.tar.gz | tar xzf - syncthing-linux-$ARCH-v$APP_VERSION/syncthing -C syncthing/$ARCH
done

# Set permissions.
find syncthing/ -type f -name syncthing -exec chmod +x {} \;

#
# Build QPKG.
qbuild

for ARCH IN $SUPPORTED_ARCHS ; do
    if [ ! -f /share/CACHEDEV1_DATA/.qpkg/QDK/syncthing/build/syncthing_$APP_VERSION_$ARCH.qpkg ] ; then
        echo "No package created for $ARCH, check output above."
done

echo "Finished."