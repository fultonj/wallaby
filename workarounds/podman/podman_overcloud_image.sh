#!/bin/bash

echo "This takes about 20 minutes to run"

time sudo LIBGUESTFS_BACKEND="direct" virt-customize -a /home/stack/overcloud_imgs/overcloud-full.qcow2 --upload /home/stack/wallaby/podman/upgrade_or_downgrade.sh:/root/upgrade_or_downgrade.sh --run-command "/usr/bin/bash /root/upgrade_or_downgrade.sh" --selinux-relabel   --network -v -x

source /home/stack/stackrc
openstack overcloud image upload --update-existing --image-path /home/stack/overcloud_imgs
