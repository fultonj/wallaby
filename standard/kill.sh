#!/bin/bash

CLEAN=1
if [[ $CLEAN -eq 1 ]]; then
    metalsmith -f value -c "Node Name" list | grep ceph > /tmp/ironic_names_to_clean
fi

openstack overcloud delete oc0 --yes
openstack overcloud node unprovision --yes --all --stack oc0 metal-big.yaml

if [[ $CLEAN -eq 1 ]]; then
    for S in $(cat /tmp/ironic_names_to_clean); do
        bash ../metalsmith/clean-disks.sh $S
    done
fi
