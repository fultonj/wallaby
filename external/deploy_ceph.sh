#!/bin/bash

METAL=1
PRE=1
NET=1 # only runs if PRE=1
PKG=1 # only runs if PRE=1
POD=1 # only runs if PRE=1
USR=1 # only runs if PRE=1
CEPH=1
EXPORT=1

if [[ $# -eq 1 ]]; then
    STACK=$1
else
    STACK=ceph6
fi
echo "stack=$STACK"

INV=inventory.yaml
INVS=deployed-metal-${STACK}.yaml

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
    python3 inventory.py -m $INVS -i $INV
    sleep 180
    ansible -i $INV -m ping all
    if [[ $? -gt 0 ]]; then
        echo "ERROR: unable to ansible ping all hosts with ansible inventory"
        exit 1
    fi
fi

if [[ $PRE -eq 1 ]]; then
    if [[ $NET -eq 1 ]]; then
        # connect ceph nodes to Internet with hack
        ansible-playbook-3 -i $INV ceph_nethack.yaml
        sleep 10
        ansible -i $INV all -m shell -a "ping -c 1 google.com"
        if [[ $? -gt 0 ]]; then
            echo "ERROR: hosts unable to ping Internet"
            exit 1
        fi
    fi
    if [[ $PKG -eq 1 ]]; then
        ansible-playbook-3 -i $INV -v packages.yaml
        if [[ $? -gt 0 ]]; then
            echo "ERROR: problem with installing packages"
            exit 1
        fi
    fi
    if [[ $POD -eq 1 ]]; then
        ansible-playbook-3 -i $INV -v podman.yaml
        if [[ $? -gt 0 ]]; then
            echo "ERROR: problem with configuring podman"
            exit 1
        fi
    fi
    if [[ $USR -eq 1 ]]; then
        bash user.sh
    fi
fi

if [[ $CEPH -eq 1 ]]; then
    if [[ $STACK == "ceph" ]]; then
        ansible-playbook-3 -i $INV -v cephadm.yaml \
                           -e @cephadm-extra-vars-heat.yml \
                           -e @cephadm-extra-vars-ansible.yml
    else
        ansible-playbook-3 -i $INV -v cephadm.yaml \
                           -e @ceph-dcn.yml \
                           -e @ceph-dcn-$STACK.yml
    fi
fi

if [[ $EXPORT -eq 1 ]]; then
    # obsoleted by tripleo_cephadm/tasks/export.yaml
    for F in ~/ceph_client.yaml ceph-external.yaml; do
        if [[ -e $F ]]; then
            rm -f $F
        fi
    done
    for F in ceph.conf ceph.client.openstack.keyring; do
        rm -f $F
        if [[ ! -e $F ]]; then
            ansible -b mons[0] -i $INV -m fetch -a "flat=yes src=/etc/ceph/$F dest=$F"
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
