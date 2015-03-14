#!/bin/bash -x

# This script will create docker image, that can be used
# for building rpm packages

# Some part of the code was adopted from
# https://github.com/docker/docker/blob/master/contrib/mkimage.sh

# docker image name
TAG=fuel/rpmbuild_env
# packages
SANDBOX_PACKAGES="bash ruby rpm-build tar python-setuptools python-pbr"
# path where we create our chroot and build docker
dir=

TMPDIR=/var/tmp/docker_root

mkdir "${TMPDIR}"

sudo mount -n -t tmpfs -o size=768M docker_chroot "${TMPDIR}"

# creating chroot env
if [ -z "${dir}" ]; then
  dir="$(mktemp -d ${TMPDIR:-/var/tmp}/docker-mkimage.XXXXXXXXXX)"
fi

rootfsDir="${dir}/rootfs"
sudo mkdir -p "${rootfsDir}"

# prepare base files
sudo mkdir -p "${rootfsDir}/etc/yum.repos.d"
sudo cp ./files/yum.conf "${rootfsDir}/etc/yum.conf"
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | sudo tee "${rootfsDir}/etc/resolv.conf"


# download centos-release
yumdownloader --resolve --archlist=x86_64 \
-c "${rootfsDir}/etc/yum.conf" \
--destdir=/tmp centos-release
sudo rpm -i --root "${rootfsDir}" $(find /tmp/ -maxdepth 1 -name "centos-release*rpm" | head -1) || \
echo "centos-release already installed"
sudo rm -f "${rootfsDir}"/etc/yum.repos.d/Cent*
echo 'Rebuilding RPM DB'
sudo rpm --root="${rootfsDir}" --rebuilddb
echo 'Installing packages for Sandbox'
sudo /bin/sh -c "export TMPDIR=${rootfsDir}/tmp/yum TMP=${rootfsDir}/tmp/yum ; yum -c ${rootfsDir}/etc/yum.conf --installroot=${rootfsDir} -y --nogpgcheck install ${SANDBOX_PACKAGES}"

# Docker mounts tmpfs at /dev and procfs at /proc so we can remove them
sudo rm -rf "$rootfsDir/dev" "$rootfsDir/proc"
sudo mkdir -p "$rootfsDir/dev" "$rootfsDir/proc"

#let's pack rootfs
tarFile="${dir}/rootfs.tar.xz"
sudo touch "${tarFile}"

sudo tar --numeric-owner -caf "${tarFile}" -C "${rootfsDir}" --transform='s,^./,,' .

# prepare for building docker
cat > "${dir}/Dockerfile" <<'EOF'
FROM scratch
ADD rootfs.tar.xz /
EOF

# cleaning rootfs
sudo rm -rf "$rootfsDir"

# creating docker image
docker build -t "${TAG}" "${dir}"

# cleaning all
rm -rf "${dir}"
sudo umount "${TMPDIR}"

# saving image
#docker save "${TAG}" | pxz > /var/tmp/fuel-rpmbuild_env.tar.xz

# clearing docker env
#docker rmi scratch
#docker rmi "${TAG}"
