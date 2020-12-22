#!/bin/bash

METAL=1
NET=1
PKG=1
CEPH=0
STACK=ceph
EXPORT=0
INV=inventory.yaml

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

if [[ ! -e $INV ]]; then
    echo "Creating inventory"
    # https://review.opendev.org/#/c/723108/39/specs/wallaby/tripleo-ceph.rst@460
    python3 inventory.py -m deployed-metal-ceph.yaml -i $INV
    sleep 180
    ansible -i $INV -m ping all
    if [[ $? -gt 0 ]]; then
        echo "ERROR: unable to ansible ping all hosts with ansible inventory"
        exit 1
    fi
fi

if [[ $NET -eq 1 ]]; then
    # connect ceph nodes to Internet with hack for now
    ansible-playbook-3 -i $INV ceph_nethack.yaml
    ansible -i $INV all -m shell -a "ping -c 1 redhat.com"
    if [[ $? -gt 0 ]]; then
        echo "ERROR: hosts unable to ping Internet"
        exit 1
    fi
fi

if [[ $PKG -eq 1 ]]; then
    ansible-playbook-3 -i $INV packages.yaml -v
fi

if [[ $CEPH -eq 1 ]]; then
    echo "Use manual_ceph.md for now"
    exit 0
fi

if [[ $EXPORT -eq 1 ]]; then
    for F in ~/ceph_client.yaml ceph-external.yaml; do
        if [[ -e $F ]]; then
            rm -f $F
        fi
    done
    for F in ceph.conf ceph.client.openstack.keyring; do
        if [[ ! -e $F ]]; then
            ansible mons[0] -i $INV -m fetch -a "flat=yes src=/etc/ceph/$F dest=$F"
        fi
        if [[ ! -e $F ]]; then
            echo "Error: cannot find file $F"
            exit 1
        fi
    done
    python3 export.py \
            -t old \
            -k ceph.client.openstack.keyring \
            -c ceph.conf \
            -o ceph-external.yaml
fi
