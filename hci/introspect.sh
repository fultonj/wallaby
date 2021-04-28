#!/bin/bash

STRICT=1
IPMI_INFO=~/baremetal.json

source ~/stackrc
INTROSPECTED_COUNT=$(openstack baremetal introspection list -f value | wc -l)
echo "$INTROSPECTED_COUNT nodes have been introspected"

if [[ $STRICT -eq 1 && $INTROSPECTED_COUNT -ne 0 ]]; then
    echo "Strict mode is on and there are already introspected nodes. Exiting."
    exit 1
fi

if [[ ! -e $IPMI_INFO ]]; then
    echo "Unable to find '$IPMI_INFO'. Exiting."
    exit 1
fi
echo "Setting nodes to manageable"

for NODE in $(openstack baremetal node list -f value -c UUID); do
    openstack baremetal node manage $NODE
done

echo "Introspecting nodes in $IPMI_INFO ..."
openstack overcloud node import --introspect --provide $IPMI_INFO
openstack baremetal introspection list
