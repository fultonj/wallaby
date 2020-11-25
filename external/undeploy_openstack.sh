#!/bin/bash

STACK=openstack-only

openstack overcloud delete $STACK --yes

pushd ../metalsmith
bash unprovision.sh $STACK
rm -f deployed-metal-$STACK.yaml
popd

for F in cirros-0.4.0-x86_64-disk.{raw,img} tempest-deployer-input.conf; do
    if [[ -e $F ]]; then
        rm -f $F
    fi
done
