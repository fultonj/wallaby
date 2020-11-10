#!/bin/bash

CLEAN=0
if [[ $CLEAN -eq 1 ]]; then
    cat /dev/null > /tmp/ironic_names_to_clean
    openstack server list -f value -c Name -c ID | grep ceph | awk {'print $1'} > /tmp/nova_ids_to_clean
    for S in $(cat /tmp/nova_ids_to_clean); do
        openstack baremetal node list -f value -c Name -c "Instance UUID" | grep $S | awk {'print $1'} >> /tmp/ironic_names_to_clean
    done
fi

openstack overcloud delete oc0 --yes
openstack overcloud node unprovision --yes --all --stack oc0 metal-big.yaml

if [[ $CLEAN -eq 1 ]]; then
    for S in $(cat /tmp/ironic_names_to_clean); do
        bash ../metalsmith/clean-disks.sh $S
    done
fi
