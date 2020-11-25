#!/bin/bash

METAL=1
PUPPET=1
HEAT=1
DOWN=0
STACK=openstack-only
DIR=~/config-download
NODE_COUNT=8

source ~/stackrc
# -------------------------------------------------------
if [[ $(($HEAT + $DOWN)) -gt 1 ]]; then
    echo "HEAT ($HEAT) and DOWN ($DOWN) cannot both be 1."
    echo "HEAT will run config-download the first time."
    echo "Only use DOWN for subsequent config-download runs."
    exit 1
fi
# -------------------------------------------------------

if [[ ! -e ceph-external.yaml ]]; then
    echo "Error: ceph-external.yaml is missing (try deploying ceph first)"
    exit 1
fi

if [[ $METAL -eq 1 ]]; then
    pushd ../metalsmith
    bash provision.sh $STACK
    popd
    cp ../metalsmith/deployed-metal-$STACK.yaml .
    echo "working around https://bugs.launchpad.net/tripleo/+bug/1903775"
    sed -i -e s/novacompute/compute/g -e s/cephstorage/ceph/g deployed-metal-$STACK.yaml
fi

if [[ ! -e deployed-metal-$STACK.yaml ]]; then
    echo "ERROR: deployed-metal-$STACK.yaml is missing"
    exit 1
fi

# -------------------------------------------------------
if [[ $PUPPET -eq 1 ]]; then
    bash puppet_tripleo.sh
fi
# -------------------------------------------------------
if [[ $HEAT -eq 1 ]]; then
    # tripleo-client will use ansible to run heat and config-download
    if [[ ! -d ~/templates ]]; then
        ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
        ## Assuming for now that ~/templates should be built by cloning THT and then...
        # git review -d 760915  # ceph_client
        # cp deployment/ceph-ansible/ceph-base.yaml /tmp/ceph-base.yaml
        # git review -d 763542  # etc_ceph_dep
        # cp /tmp/ceph-base.yaml deployment/ceph-ansible/ceph-base.yaml
    fi
    if [[ ! -e roles.yaml ]]; then
        openstack overcloud roles generate Controller Compute -o roles.yaml
    fi
    if [[ $NODE_COUNT -gt 0 ]]; then
        FOUND_COUNT=$(metalsmith -f value -c "Hostname" list | wc -l)
        if [[ $NODE_COUNT != $FOUND_COUNT ]]; then
            echo "Expecting $NODE_COUNT nodes but $FOUND_COUNT nodes have been deployed"
            exit 1
        fi
    fi

    time openstack overcloud \-v deploy \
          --disable-validations \
          --deployed-server \
          --libvirt-type qemu \
          --stack $STACK \
          --templates ~/templates \
          -r roles.yaml \
          -e ~/templates/environments/disable-telemetry.yaml \
          -e ~/templates/environments/low-memory-usage.yaml \
          -e ~/templates/environments/enable-swap.yaml \
          -e ~/templates/environments/ceph-ansible/ceph-ansible-external.yaml \
          -e ~/templates/environments/docker-ha.yaml \
          -e ~/templates/environments/podman.yaml \
          -e ~/containers-prepare-parameter.yaml \
          -e ~/generated-container-prepare.yaml \
          -e ~/oc0-domain.yaml \
          -e deployed-metal-$STACK.yaml \
          -e overrides.yaml \
          -e ceph-external.yaml
fi
# -------------------------------------------------------
if [[ $DOWN -eq 1 ]]; then
    INV=tripleo-ansible-inventory.yaml
    if [[ ! -d $DIR/$STACK ]]; then
        echo "$DIR/$STACK does not exist, Create it by setting HEAT=1"
        exit 1
    fi
    pushd $DIR/$STACK
    
    time bash ansible-playbook-command.sh -v --skip-tags run_ceph_ansible,run_uuid_ansible
    
    popd
fi
