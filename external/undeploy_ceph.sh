#!/bin/bash

METAL=0
CLEAN=0
STACK=ceph

if [[ $METAL -eq 1 ]]; then
    pushd ../metalsmith
    bash unprovision.sh $STACK
    rm -f deployed-metal-$STACK.yaml
    popd
fi

if [[ $CLEAN -eq 1 ]]; then
    for I in $(seq 0 2); do
        bash ../metalsmith/clean-disks.sh oc0-ceph-$I
    done
fi
