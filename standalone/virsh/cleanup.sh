#!/usr/bin/env bash

echo "Tearing down Ceph environment"

# stop and disable ceph containers
for N in mgr mon osd rgw; do
    if [[ -e /etc/systemd/system/ceph-${N}@.service ]]; then
        sudo systemctl stop ceph-${N}@*
        sudo systemctl disable ceph-${N}@
        sudo rm -f /etc/systemd/system/ceph-${N}@.service
    fi
done

# remove ceph container image
for IMG in $(sudo podman images \
                  --format "{{.ID}} {{.Repository}}" \
                 | grep ceph | awk {'print $1'} ); do
    sudo podman rmi $IMG;
done

# remove ceph directories
sudo rm -rf \
     /var/log/ceph \
     /var/run/ceph \
     /var/lib/ceph \
     /run/ceph \
     /etc/ceph/*

# remove the secret key of the openstack client from libvirt
for pkg in libvirt-client; do
    rpm -q $pkg > /dev/null
    if [[ $? -ne 0 ]]; then
        sudo dnf install -y libvirt-client
    fi
done
for S in $(sudo virsh -q secret-list | awk {'print $1'}); do
    sudo virsh secret-undefine $S
done
sudo find / -name secret.xml -exec rm -f {} \; 2> /dev/null


echo "Tearing down TripleO environment"
if type pcs &> /dev/null; then
    sudo pcs cluster destroy
fi
if type podman &> /dev/null; then
    echo "Removing podman containers and images (takes times...)"
    sudo podman rm -af
    sudo podman rmi -af
fi
sudo rm -rf \
    /var/lib/tripleo-config \
    /var/lib/config-data /var/lib/container-config-scripts \
    /var/lib/container-puppet \
    /var/lib/heat-config \
    /var/lib/image-serve \
    /var/lib/containers \
    /etc/systemd/system/tripleo* \
    /var/lib/mysql/*
sudo systemctl daemon-reload


echo "Removing the disk used by Ceph"

sudo lvremove --force /dev/vg2/db-lv2
sudo lvremove --force --force /dev/vg2/data-lv2
sudo vgremove --force --force vg2
sudo pvremove --force --force /dev/loop3
sudo losetup -d /dev/loop3
sudo rm -f /var/lib/ceph-osd.img
sudo partprobe
