#!/bin/bash

METAL=1
STACK=openstack-only

if [[ ! -e ceph-external.yaml ]]; then
    echo "Error: ceph-external.yaml is missing (try deploying ceph first)"
    exit 1
fi

if [[ $METAL -eq 1 ]]; then
    pushd ../metalsmith
    bash provision.sh $STACK
    popd
    cp ../metalsmith/deployed-metal-$STACK.yaml .
    echo "working around https://bugs.launchpad.net/tripleo/+bug/1903775"
    sed -i -e s/novacompute/compute/g -e s/cephstorage/ceph/g deployed-metal-$STACK.yaml
fi

if [[ ! -e deployed-metal-$STACK.yaml ]]; then
    echo "ERROR: deployed-metal-$STACK.yaml is missing"
    exit 1
fi

