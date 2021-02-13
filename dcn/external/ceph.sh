#!/bin/bash

# deploy two nodes in one stack

for STACK in ceph2 ceph3; do
    pushd ../../external/
    echo $STACK;
    rm inventory.yaml
    bash deploy_ceph.sh $STACK
    if [[ $? -gt 0 ]]; then
        echo "deploy_ceph.sh $STACK encountered an error"
        exit 1
    fi
    popd
    cp ../../external/ceph-external.yaml ceph-external-$STACK.yaml
done

