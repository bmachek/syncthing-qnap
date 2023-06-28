#!/bin/bash

# set -x

if [ -z "$1" ] ; then
    echo "Desired syncthing version missing."
    echo "Example: $0 1.25.0"
    exit 2
fi

# === Build own QPKG. ===
APP_NAME="syncthing"
APP_VERSION=$1
APP_AUTHOR="Syncthing Community"
APP_LICENSE="MPL-2.0"

SUPPORTED_ARCHS="arm64 arm 386 amd64"

cd $(getcfg QDK Install_Path -f /etc/config/qpkg.conf)


if [ -d "${APP_NAME}" ] ; then
    echo "build.sh: Deleting pre-existing build directory"
    rm -rf "${APP_NAME}"
fi

echo "build.sh: Creating new build directory"
qbuild --create-env "${APP_NAME}"

echo "build.sh: Downloading icons and configs"
wget https://github.com/bmachek/syncthing-qnap/raw/master/icons_and_txts.zip -O temp.zip 2> /dev/null
unzip -f temp.zip 2> /dev/null
rm temp.zip 2> /dev/null

echo "build.sh: Modifying build configuration"
cd $(getcfg QDK Install_Path -f /etc/config/qpkg.conf)/"${APP_NAME}"
sed -i -e "s/QPKG_NAME=.*/QPKG_NAME=\"${APP_NAME}\"/gI" "qpkg.cfg"
sed -i -e "s/QPKG_VER=.*/QPKG_VER=\"${APP_VERSION}\"/gI" "qpkg.cfg"
sed -i -e "s/QPKG_AUTHOR=.*/QPKG_AUTHOR=\"${APP_AUTHOR}\"/gI" "qpkg.cfg"
sed -i -e "s/#QPKG_LICENSE=.*/QPKG_LICENSE=\"${APP_LICENSE}\"/gI" "qpkg.cfg"

echo "
QDK_DATA_DIR_X19=\"arm\"
# Location of files specific to arm-x31 packages.
QDK_DATA_DIR_X31=\"arm\"
# Location of files specific to arm-x41 packages.
QDK_DATA_DIR_X41=\"arm\"
# Location of files specific to x86 packages.
QDK_DATA_DIR_X86=\"386\"
# Location of files specific to x86 (64-bit) packages.
QDK_DATA_DIR_X86_64=\"amd64\"
# Location of file for arm64
QDK_DATA_DIR_ARM_64=\"arm64\"
" >> $(getcfg QDK Install_Path -f /etc/config/qpkg.conf)/"${APP_NAME}"/qpkg.cfg


echo "build.sh: Downloading syncthing binaries"
for ARCH in $SUPPORTED_ARCHS ; do
    echo "  build.sh: ... for $ARCH"
    mkdir $ARCH
    wget -c https://github.com/syncthing/syncthing/releases/download/v$APP_VERSION/syncthing-linux-$ARCH-v$APP_VERSION.tar.gz -O - 2>/dev/null | tar -xz syncthing-linux-$ARCH-v$APP_VERSION/syncthing --strip-components 1
    chmod +x syncthing
    chown 0:0 syncthing
    mv syncthing $ARCH
done

echo "build.sh: Starting QPKG build process"
qbuild

echo "build.sh: QPKG build process finished"

echo "build.sh: Contents of build directory"
ls -lh build/

echo "build.sh: Finished."
