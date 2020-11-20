#!/bin/bash

METAL=0
NET=0
CEPH=1
STACK=ceph
INV=tripleo-ceph/inventory.yaml

if [[ $METAL -eq 1 ]]; then
    pushd ../metalsmith
    bash provision.sh $STACK
    popd
    cp ../metalsmith/deployed-metal-$STACK.yaml .
fi

if [[ ! -e deployed-metal-$STACK.yaml ]]; then
    echo "ERROR: deployed-metal-$STACK.yaml is missing"
    exit 1
fi

if [[ ! -d tripleo-ceph ]]; then
    git clone git@github.com:fultonj/tripleo-ceph.git
    if [[ ! -d tripleo-ceph ]]; then
        echo "ERROR: tripleo-ceph is missing"
        exit 1
    fi
fi

if [[ ! -e $INV ]]; then
    echo "Creating inventory"
    # https://review.opendev.org/#/c/723108/39/specs/wallaby/tripleo-ceph.rst@460
    python3 inventory.py -m deployed-metal-ceph.yaml -i $INV
    ansible -i $INV -m ping all
fi

if [[ $NET -eq 1 ]]; then
    # connect ceph nodes to Internet with hack for now
    ansible-playbook-3 -i $INV ceph_nethack.yaml
    ansible -i $INV all -m shell -a "ping -c 1 redhat.com"
fi

if [[ $CEPH -eq 1 ]]; then
    pushd tripleo-ceph
    ansible-playbook-3 -i $INV site.yaml -v
    popd
fi
