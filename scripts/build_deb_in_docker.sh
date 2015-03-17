#!/bin/bash

set -x

  # sudo cp -r $(BUILD_DIR)/packages/sources/$1/* $$(SANDBOX_UBUNTU)/tmp/$1/
  # sudo cp -r $(SOURCE_DIR)/packages/deb/specs/$1/* $$(SANDBOX_UBUNTU)/tmp/$1/
  # dpkg-checkbuilddeps $(SOURCE_DIR)/packages/deb/specs/$1/debian/control 2>&1 | sed 's/^dpkg-checkbuilddeps: Unmet build dependencies: //g' | sed 's/([^()]*)//g;s/|//g' | sudo tee $$(SANDBOX_UBUNTU)/tmp/$1.installdeps
  # sudo chroot $$(SANDBOX_UBUNTU) /bin/sh -c "cat /tmp/$1.installdeps | xargs apt-get -y install"
  # sudo chroot $$(SANDBOX_UBUNTU) /bin/sh -c "cd /tmp/$1 ; DEB_BUILD_OPTIONS=nocheck debuild -us -uc -b -d"
  # cp $$(SANDBOX_UBUNTU)/tmp/*$1*.deb $(BUILD_DIR)/packages/deb/packages

for pkgs in $(ls /opt/sandbox/SPECS/); do
  mkdir /tmp/${pkgs}
  cp -rv /opt/sandbox/SOURCES/${pkgs}/* /tmp/${pkgs}/
  cp -rv /opt/sandbox/SPECS/${pkgs}/* /tmp/${pkgs}/
  dpkg-checkbuilddeps /opt/sandbox/SPECS/${pkgs}/debian/control 2>&1 | sed 's/^dpkg-checkbuilddeps: Unmet build dependencies: //g' | sed 's/([^()]*)//g;s/|//g' | tee /tmp/${pkgs}.installdeps
  /bin/sh -c "cat /tmp/${pkgs}.installdeps | xargs apt-get -y install"
  /bin/sh -c "cd /tmp/${pkgs} ; DEB_BUILD_OPTIONS=nocheck debuild -us -uc -b -d"
  cp -v /tmp/*${pkgs}*.deb /opt/sandbox/DEB
done