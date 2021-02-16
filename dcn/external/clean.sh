#!/bin/bash

# clean up control-plane-e and dcn0e but not external ceph clusters

rm -f \
   control-plane-e-export.yaml \
   ceph-export-control-plane.yaml \
   ceph-export-dcn0.yaml \
   dcn0e/dcn_roles.yaml \
   dcn0e/tempest-deployer-input.conf \
   control-plane-e/control_plane_roles.yaml \
   control-plane-e/tempest-deployer-input.conf \
   control-plane-e/overrides.yaml \
   control-plane-e/deploy-update.sh

for STACK in $(openstack stack list -f value -c "Stack Name"); do
    openstack overcloud delete $STACK --yes
    pushd ../../metalsmith
    bash unprovision.sh $STACK
    popd
done

