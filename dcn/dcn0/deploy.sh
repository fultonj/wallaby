#!/bin/bash

HEAT=1
DOWN=0

STACK=dcn0
DIR=~/config-download

source ~/stackrc
# -------------------------------------------------------
if [[ $(($HEAT + $DOWN)) -gt 1 ]]; then
    echo "HEAT ($HEAT) and DOWN ($DOWN) cannot both be 1."
    echo "HEAT will run config-download the first time."
    echo "Only use DOWN for subsequent config-download runs."
    exit 1
fi
# -------------------------------------------------------
METAL="../../metalsmith/deployed-metal-${STACK}.yaml"
if [[ ! -e $METAL ]]; then
    echo "$METAL is missing. Deploying nodes with metalsmith"
    pushd ../../metalsmith
    bash provision.sh $STACK
    popd
fi
if [[ ! -e $METAL ]]; then
    echo "$METAL is still missing. Aborting."
    exit 1
fi
# -------------------------------------------------------
if [[ ! -e dcn_roles.yaml ]]; then
    if [[ $STACK == "dcn1" ]]; then
        openstack overcloud roles generate DistributedCompute CephAll -o dcn_roles.yaml --roles-path ~/templates/roles
    else
        openstack overcloud roles generate DistributedComputeHCI DistributedComputeHCIScaleOut -o dcn_roles.yaml --roles-path ~/templates/roles
    fi
fi
# -------------------------------------------------------
# `openstack overcloud -v` should be passed along as
# `ansible-playbook -vv` for any usage of Ansible (the
# OpenStack client defaults to no -v being 1 verbosity
# and --quiet being 0)
# -------------------------------------------------------
if [[ $HEAT -eq 1 ]]; then
    if [[ ! -d ~/templates ]]; then
        ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
    fi
    time openstack overcloud -v deploy \
         --disable-validations \
         --deployed-server \
         --stack $STACK \
         --config-download-timeout 240 \
         --templates ~/templates/ \
         -r dcn_roles.yaml \
         -e ~/templates/environments/deployed-server-environment.yaml \
         -e ~/templates/environments/disable-telemetry.yaml \
         -e ~/templates/environments/low-memory-usage.yaml \
         -e ~/templates/environments/enable-swap.yaml \
         -e ~/templates/environments/docker-ha.yaml \
         -e ~/templates/environments/podman.yaml \
         -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
         -e ~/templates/environments/dcn-hci.yaml \
         -e ~/containers-prepare-parameter.yaml \
         -e ~/generated-container-prepare.yaml \
         -e ~/oc0-domain.yaml \
         -e $METAL \
         -e ../control-plane-export.yaml \
         -e ../ceph-export-control-plane.yaml \
         -e ceph.yaml \
         -e glance.yaml \
         -e overrides.yaml \
         --libvirt-type qemu

    # network isol
         # -n ../../network-data.yaml \
         # -e ~/templates/environments/deployed-server-environment.yaml \
         # -e ~/templates/environments/network-isolation.yaml \
         # -e ~/templates/environments/network-environment.yaml \
fi
# -------------------------------------------------------
if [[ $DOWN -eq 1 ]]; then
    if [[ ! -d $DIR/$STACK ]]; then
        echo "$DIR/$STACK does not exist, Create it by setting HEAT=1"
        exit 1
    fi
    pushd $DIR/$STACK
    # run it all
    bash ansible-playbook-command.sh

    # Just re-run ceph
    # bash ansible-playbook-command.sh --tags external_deploy_steps --skip-tags step4,step5,post_deploy_steps

    # Just re-run ceph prepration without running ceph
    # bash ansible-playbook-command.sh --tags external_deploy_steps --skip-tags step4,step5,post_deploy_steps,ceph
    
    # Pick up after good ceph install (need to test this)
    # bash ansible-playbook-command.sh --tags facts,step2,step3,step4,step5,post_deploy_steps,external --skip-tags ceph

    exit $?
    popd
fi

