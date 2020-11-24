#!/bin/bash

STACK=openstack-only

openstack overcloud delete $STACK --yes

pushd ../metalsmith
bash unprovision.sh $STACK
rm -f deployed-metal-$STACK.yaml
popd

