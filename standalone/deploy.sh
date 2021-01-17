#!/bin/bash

METAL=1
PRE=1
NET=1 # only runs if PRE=1
PKG=1 # only runs if PRE=1
USR=1 # only runs if PRE=1
PCS=0 # only runs if PRE=1
STD=1

STACK=standalone
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
    python3 ../external/inventory.py -m deployed-metal-$STACK.yaml -i $INV
    sleep 180
    ansible -i $INV -m ping all
    if [[ $? -gt 0 ]]; then
        echo "ERROR: unable to ansible ping all hosts with ansible inventory"
        exit 1
    fi
fi

if [[ $PRE -eq 1 ]]; then
    if [[ $NET -eq 1 ]]; then
        # connect ceph nodes to Internet with hack for now
        ansible-playbook-3 -i $INV ../external/ceph_nethack.yaml
        ansible -i $INV all -m shell -a "ping -c 1 redhat.com"
        if [[ $? -gt 0 ]]; then
            echo "ERROR: hosts unable to ping Internet"
            exit 1
        fi
    fi
    if [[ $PKG -eq 1 ]]; then
        ansible-playbook-3 -i $INV -v ../external/packages.yaml
        if [[ $? -gt 0 ]]; then
            echo "ERROR: problem with installing packages"
            exit 1
        fi
    fi
    if [[ $PCS -eq 1 ]]; then
        # pacemaker workaround
        cp $INV ../external/inventory_openstack.yaml
        pushd ../external
        bash pcs.sh
        rm -f inventory_openstack.yaml
        popd
    fi
fi

if [[ $STD -eq 1 ]]; then
    # prepare node for a standalone install
    ansible-playbook-3 -i $INV -v standalone.yaml
fi
