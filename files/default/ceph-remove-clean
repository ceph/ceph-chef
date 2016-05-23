#!/bin/bash

# Work-in-process so informational only for now...
# NOT installed - just in repo for now!

# Removes Ceph and makes sure all ceph residuals are cleaned up

set +e

# Remove ceph-create-keys if it exists first
echo "== Stop ceph-create-keys"
procs=($(ps aux | grep [c]eph-create-keys | awk '{print $2}'))
for proc in ${procs[@]}; do
  sudo kill $proc
done

echo "== Stop ceph services"
for s in \
  ceph-all \
  ceph-mds-all \
  ceph-mon-all \
  ceph-osd-all \
  radosgw-all \
  rbdmap \
  ceph-create-keys \
  ceph-radosgw \
  ceph \
  ; do \
  sudo service $s stop
done

mounts=($(df | grep '/var/lib/ceph/' | awk '{print $1}'))

# Unmount and clean all ceph devices
echo "== Unmount & clean deph devices"
for mnt in ${mounts[@]}; do
  sudo umount $mnt
  new_mnt=$(echo $mnt | sed 's/[0-9]*//g')
  sudo sgdisk --zap-all $new_mnt
done

# Uninstall ceph and related software
# This might be buggy if you have multiple package manager binaries present.
echo "== Uninstall ceph"
if sudo which yum >/dev/null 2>&1 ; then
  sudo yum remove -y ceph-radosgw
  sudo yum remove -y ceph
elif sudo which apt-get >/dev/null 2>&1 ; then
  dpkg --list | awk '{print $2}' | grep \
    -e ceph \
    -e ceph-base \
    -e ceph-common \
    -e ceph-common-dbg \
    -e ceph-fs-common \
    -e ceph-fs-common-dbg \
    -e ceph-fuse \
    -e ceph-fuse-dbg \
    -e ceph-mds \
    -e ceph-mds-dbg \
    -e ceph-mon \
    -e ceph-mon-dbg \
    -e ceph-osd \
    -e ceph-osd-dbg \
    -e ceph-resource-agents \
    -e ceph-test \
    -e ceph-test-dbg \
    -e libcephfs1 \
    -e libcephfs1-dbg \
    -e libcephfs-dev \
    -e libcephfs-java \
    -e libcephfs-jni \
    -e librados2 \
    -e librados2-dbg \
    -e librados2-dev \
    -e libradosstriper1 \
    -e libradosstriper1-dbg \
    -e libradosstriper1-dev \
    -e librbd1 \
    -e librbd1-dbg \
    -e librbd-dev \
    -e librgw2 \
    -e librgw2-dbg \
    -e librgw-dev \
    -e python-ceph \
    -e python-cephfs \
    -e python-rados \
    -e python-rbd \
    -e radosgw \
    -e radosgw-dbg \
    -e rbd-fuse \
    -e rbd-fuse-dbg \
    -e rbd-mirror \
    -e rbd-mirror-dbg \
    -e rbd-nbd \
    -e rbd-nbd-dbg  \
    | xargs sudo apt-get purge -y
elif false ; then # add other distro here
  :
fi

echo "== Killing old Ceph processes"
# Make sure all ceph related processes are gone too
procs=($(ps aux | grep [c]eph | awk '{print $2}' |grep -v -e $$ ))
for proc in ${procs[@]}; do
  sudo kill $proc
done

# Remove any devices that were unounted but still used by ceph
echo "== Wiping unmounted Ceph disks"
devs=($(sudo lsblk -nlo NAME,LABEL,PARTLABEL | grep ceph | awk '{print $1}' | sed 's/[0-9]*//g' | uniq))
for dev in ${devs[@]}; do
  sudo sgdisk --zap-all /dev/$dev
done

# Remove directories
echo "== Removing Ceph directories"
sudo rm -rf /var/log/ceph
sudo rm -rf /var/log/radosgw
sudo rm -rf /var/run/ceph /run/ceph/
sudo rm -rf /var/lib/ceph
sudo rm -rf /run/ceph
sudo rm -rf /etc/ceph

# Reset the partition table
echo "== Reset partition table"
sudo partprobe

# Ceph will use a temporary mount in /var/lib/ceph/tmp to verify install before unmounting and remounting to
# /var/lib/ceph/ceph-XX so as to not have a partial install. This is important to know in the event something
# happens and ceph has not unmounted the tmp mounts. These have to be umount before removing the /var/lib/ceph
# directory.

# 1. umount any mounted OSDs or tmp mounted in /var/lib/ceph/tmp
# 2. Zap all OSD devices including journal if on separate device. This can be done via 'ceph-disk zap <device>' or 'sgdisk --zap-all <device>' if ceph-disk is not installed
# 3. rm -rf /etc/ceph
# 4. rm -rf /var/log/ceph
# 5. rm -rf /var/log/radosgw (if radosgw is on the given node)
# 6. rm -rf /var/run/ceph
# 7. rm -rf /var/lib/ceph
# 8. yum (or apt-get) remove -y ceph && yum (or apt-get) remove -y ceph-radosgw (apt - radosgw) if the node has radosgw installed
# Clean
