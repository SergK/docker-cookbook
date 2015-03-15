#!/bin/bash -x

# This script will create docker image, that can be used
# for building rpm packages

# Some part of the code was adopted from
# https://github.com/docker/docker/blob/master/contrib/mkimage.sh

# docker image name
TAG=fuel/rpmbuild_env
# packages
SANDBOX_PACKAGES="bash ruby rpm-build tar python-setuptools python-pbr shadow-utils"
# path where we create our chroot and build docker
TMPDIR=/var/tmp/docker_root

# we need to add user who is going to build packages, usually jenkins
GID=$(id -g)
nGID=$(id -gn)
nUID=$(id -un)

mkdir -p "${TMPDIR}"

# let's make all stuff on tmpfs
sudo mount -n -t tmpfs -o size=768M docker_chroot "${TMPDIR}"

# creating chroot env
dir="$(mktemp -d ${TMPDIR:-/var/tmp}/docker-image.XXXXXXXXXX)"

rootfsDir="${dir}/rootfs"
sudo mkdir -p "${rootfsDir}"

# prepare base files
sudo mkdir -p "${rootfsDir}/etc/yum.repos.d"

sudo bash -c "cat > ${rootfsDir}/etc/yum.conf" << EOF
[main]
cachedir=/var/cache/yum
keepcache=0
debuglevel=6
logfile=/var/log/yum.log
exclude=*.i686.rpm
exactarch=1
obsoletes=1
gpgcheck=0
plugins=1
pluginpath=/etc/yum-plugins
pluginconfpath=/etc/yum/pluginconf.d
reposdir=/etc/yum.repos.d

[mirror]
name=Mirantis mirror
baseurl=http://osci-mirror-kha.kha.mirantis.net/fwm/6.1/centos/os/x86_64/
gpgcheck=0
enabled=1

EOF
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | sudo tee "${rootfsDir}/etc/resolv.conf"


# download centos-release
yumdownloader --resolve --archlist=x86_64 \
-c "${rootfsDir}/etc/yum.conf" \
--destdir=${dir} centos-release
sudo rpm -i --root "${rootfsDir}" $(find ${dir} -maxdepth 1 -name "centos-release*rpm" | head -1) || \
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
cat > "${dir}/Dockerfile" <<EOF
FROM scratch
ADD rootfs.tar.xz /

RUN groupadd --gid ${GID} ${nGID} && \
    useradd --system --uid ${UID} --gid ${GID} --home /opt/sandbox --shell /bin/bash ${nUID} && \
    mkdir /opt/sandbox && \
    chown -R ${UID}:${GID} /opt/sandbox
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
docker save "${TAG}" | xz > /var/tmp/fuel-rpmbuild_env.tar.xz

# clearing docker env
#docker rmi scratch
#docker rmi "${TAG}"
