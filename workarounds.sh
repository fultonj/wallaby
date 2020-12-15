#!/bin/bash

source ~/stackrc
STACK=$1
if [[ -z $STACK ]]; then
    echo "Usage: $0 <STACK_NAME>"
    exit 1
else
    DEPLOYED_METAL="deployed-metal-${STACK}.yaml"
fi

if [[ ! -e metalsmith/$DEPLOYED_METAL ]]; then
    echo "metalsmith/$DEPLOYED_METAL does not exist, deploying metal for $STACK"
    pushd metalsmith
    bash provision.sh $STACK
    popd
else
    echo "metal for $STACK seems to have already been deployed"
    metalsmith list
fi

cp metalsmith/$DEPLOYED_METAL external/deployed-metal-openstack-only.yaml

pushd external
echo "Applying puppet workaround"
bash puppet_tripleo.sh
echo "Applying pacemaker workaround"
bash pcs.sh

echo "removing 'openstack' inventory"
rm deployed-metal-openstack-only.yaml inventory_openstack.yaml
popd

