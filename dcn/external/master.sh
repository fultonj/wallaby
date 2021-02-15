#!/usr/bin/env bash

CEPH=0
CONTROL=1
EXPORT=0
DCN0=0
CONTROLUP=0

source ~/stackrc
# -------------------------------------------------------
if [[ $CEPH -eq 1 ]]; then
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
    mv ceph-external-ceph2.yaml control-plane-e/
    mv ceph-external-ceph3.yaml dcn0e/
fi
# -------------------------------------------------------
if [[ $CONTROL -eq 1 ]]; then
    echo "Standing up control-plane deployment"
    pushd control-plane-e
    bash deploy.sh
    popd

    echo "Verify control-plane is working"
    RC=/home/stack/control-plane-erc
    if [[ -e $RC ]]; then
        source $RC
        echo "Attempting to issue token from control-plane"
        openstack token issue -f value -c id
        if [[ $? -gt 0 ]]; then
            echo "Unable to issue token. Aborting."
            exit 1
        fi
        # Use undercloud by default
        source ~/stackrc
    else
        echo "$RC is missing. abort."
        exit 1
    fi
fi
# -------------------------------------------------------
if [[ $EXPORT -eq 1 ]]; then
    openstack overcloud export -f --stack control-plane-e

    echo "Need to export ceph-2 cluster in CephExternalMultiConfig format"
    exit 1

    # if [[ ! -e control-plane-e-export.yaml ]]; then
    #     echo "Unable to create control-plane-export.yaml. Aborting."
    #     exit 1
    # fi
    # if [[ ! -e ceph-export-control-plane.yaml ]]; then
    #     echo "Failure: openstack overcloud export ceph --stack control-plane"
    #     exit 1
    # fi
fi
# -------------------------------------------------------
echo "DCN portion not yet implemented"
exit 1
# -------------------------------------------------------
if [[ $DCN0 -eq 1 ]]; then
    echo "Standing up dcn0 deployment"
    pushd dcn0e
    bash deploy.sh
    if [[ $? -gt 0 ]]; then
        echo "DCN deployment failed. Aborting."
        exit 1
    fi
    source ~/control-plane-erc
    openstack aggregate show dcn0e
    if [[ $? -gt 0 ]]; then
        echo "openstack aggregate dcn0 was not created. Aborting."
        exit 1
    fi
    source ~/stackrc
    popd
fi
# -------------------------------------------------------
if [[ $CONTROLUP -eq 1 ]]; then
    echo "Create control-plane/ceph_keys_update.yaml with ceph_keys.sh 3"
    openstack overcloud export ceph -f --stack dcn0e
    if [[ ! -e ceph-export-2-stacks.yaml ]]; then
        echo "Failure: openstack overcloud export ceph --stack dcn0"
        exit 1
    fi

    pushd control-plane-e
    if [[ -e deploy-update.sh ]]; then
        rm -f deploy-update.sh
    fi
    cp deploy.sh deploy-update.sh
    sed -i s/qemu/qemu\ \\\\/g deploy-update.sh
    sed -i s/#\ ONE/\\-e\ glance_update.yaml\ \\\\/g deploy-update.sh
    sed -i s/#\ TWO/\\-e\ \\.\\.\\/ceph-export-2-stacks.yaml/g deploy-update.sh
    bash deploy-update.sh
    popd
    echo "You may now test the deployment with ../validations/use-multistore-glance.sh"
fi
