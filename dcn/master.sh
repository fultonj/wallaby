#!/usr/bin/env bash
CONTROL=1
EXPORT=1
DCN0=1
DCN1=1
CONTROLUP=1

source ~/stackrc
# -------------------------------------------------------
if [[ $CONTROL -eq 1 ]]; then
    echo "Standing up control-plane deployment"
    pushd control-plane
    bash deploy.sh
    popd

    echo "Verify control-plane is working"
    RC=/home/stack/control-planerc
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
    openstack overcloud export -f --stack control-plane

    # hack around this bug for now
    # sudo sed -i s/'storage_ip'/'storage_cloud_0_ip'/g \
    #      /usr/lib/python3.6/site-packages/tripleoclient/export.py

    openstack overcloud export ceph -f --stack control-plane

    if [[ ! -e control-plane-export.yaml ]]; then
        echo "Unable to create control-plane-export.yaml. Aborting."
        exit 1
    fi
    if [[ ! -e ceph-export-control-plane.yaml ]]; then
        echo "Failure: openstack overcloud export ceph --stack control-plane"
        exit 1
    fi
fi
# -------------------------------------------------------
if [[ $DCN0 -eq 1 ]]; then
    echo "Standing up dcn0 deployment"
    pushd dcn0
    bash deploy.sh
    if [[ $? -gt 0 ]]; then
        echo "DCN deployment failed. Aborting."
        exit 1
    fi
    source ~/control-planerc
    openstack aggregate show dcn0
    if [[ $? -gt 0 ]]; then
        echo "openstack aggregate dcn0 was not created. Aborting."
        exit 1
    fi
    source ~/stackrc
    popd
fi
# -------------------------------------------------------
if [[ $DCN1 -eq 1 ]]; then
    echo "Standing up dcn1 deployment"
    bash dcnN.sh
fi
# -------------------------------------------------------
if [[ $CONTROLUP -eq 1 ]]; then
    echo "Create control-plane/ceph_keys_update.yaml with ceph_keys.sh 3"
    openstack overcloud export ceph -f --stack dcn0,dcn1
    if [[ ! -e ceph-export-2-stacks.yaml ]]; then
        echo "Failure: openstack overcloud export ceph --stack dcn0,dcn1"
        exit 1
    fi

    pushd control-plane
    if [[ -e deploy-update.sh ]]; then
        rm -f deploy-update.sh
    fi
    cp deploy.sh deploy-update.sh
    sed -i s/qemu/qemu\ \\\\/g deploy-update.sh
    sed -i s/#\ ONE/\\-e\ glance_update.yaml\ \\\\/g deploy-update.sh
    sed -i s/#\ TWO/\\-e\ \\.\\.\\/ceph-export-2-stacks.yaml/g deploy-update.sh
    bash deploy-update.sh
    popd
    echo "You may now test the deployment with validations/use-multistore-glance.sh"
fi
