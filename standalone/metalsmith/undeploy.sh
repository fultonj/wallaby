#!/bin/bash

METAL=1
CLEAN=1
STACK=standalone
INV=inventory.yaml

if [[ $METAL -eq 1 ]]; then
    pushd ../metalsmith
    bash unprovision.sh $STACK
    rm -f deployed-metal-$STACK.yaml
    popd
    sleep 10
fi

if [[ $CLEAN -eq 1 ]]; then
    bash ../metalsmith/clean-disks.sh oc0-ceph-5
fi

for F in inventory.yaml deployed-metal-standalone.yaml; do
    if [[ -e $F ]]; then
        rm -f $F
    fi
done
