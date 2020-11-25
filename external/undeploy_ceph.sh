#!/bin/bash

METAL=1
CLEAN=1
STACK=ceph
INV=tripleo-ceph/inventory.yaml

if [[ -e $INV ]]; then
    rm -f $INV
fi

if [[ $METAL -eq 1 ]]; then
    pushd ../metalsmith
    bash unprovision.sh $STACK
    rm -f deployed-metal-$STACK.yaml
    popd
fi

if [[ $CLEAN -eq 1 ]]; then
    for I in $(seq 0 2); do
        bash ../metalsmith/clean-disks.sh oc0-ceph-$I
    done
fi

for F in inventory.yaml ceph.pub ceph.conf ceph.client.openstack.keyring ceph-external.yaml; do
    if [[ -e $F ]]; then
        rm -f $F
    fi
done
