#!/bin/bash

STACK=oc0
if [[ -e inventory.yaml ]]; then
    INV=../inventory.yaml
elif [[ -e ~/config-download/$STACK/cephadm/inventory.yml ]]; then
    INV=~/config-download/$STACK/cephadm/inventory.yml
else
    echo "missing inventory"
    exit 1
fi
echo $INV

ansible-playbook -i $INV rm_ceph.yaml $@
