#!/bin/bash

IRONIC=1
PUSH=0
HEAT=1
DOWN=0
RMCEPH=0

STACK=overcloud
DIR=~/config-download
NODE_COUNT=6

source ~/stackrc
# -------------------------------------------------------
if [[ $(($HEAT + $DOWN)) -gt 1 ]]; then
    echo "HEAT ($HEAT) and DOWN ($DOWN) cannot both be 1."
    echo "HEAT will run config-download the first time."
    echo "Only use DOWN for subsequent config-download runs."
    exit 1
fi
# -------------------------------------------------------
METAL="../metalsmith/deployed-metal-${STACK}.yaml"
if [[ $IRONIC -eq 1 ]]; then
    if [[ ! -e $METAL ]]; then
        echo "$METAL is missing. Deploying nodes with metalsmith."
        pushd ../metalsmith
        bash provision.sh $STACK
        popd
    fi
    if [[ ! -e $METAL ]]; then
        echo "$METAL is missing after deployment attempt. Going to retry once."
        pushd ../metalsmith
        bash undeploy_failures.sh
        bash provision.sh $STACK
        popd
        if [[ ! -e $METAL ]]; then
            echo "$METAL is still missing. Aborting."
            exit 1
        fi
    fi
fi
if [[ ! -e deployed-metal-$STACK.yaml ]]; then
    cp $METAL deployed-metal-$STACK.yaml
fi
# -------------------------------------------------------
if [[ $PUSH -eq 1 ]]; then
    TGT="/usr/share/ansible/tripleo-playbooks/cli-derive-parameters.yaml"
    SRC="/home/stack/tripleo-ansible/tripleo_ansible/playbooks/cli-derive-parameters.yaml"
    sudo cp -v $SRC $TGT

    TGT="/usr/share/ansible/plugins/modules/tripleo_derive_hci_parameters.py"
    SRC="/home/stack/tripleo-ansible/tripleo_ansible/ansible_plugins/modules/tripleo_derive_hci_parameters.py"
    sudo cp -v $SRC $TGT
fi
# -------------------------------------------------------
if [[ $HEAT -eq 1 ]]; then
    if [[ ! -d ~/templates ]]; then
        ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
    fi
    if [[ $NODE_COUNT -gt 0 ]]; then
        FOUND_COUNT=$(metalsmith -f value -c "Hostname" list | wc -l)
        if [[ $NODE_COUNT != $FOUND_COUNT ]]; then
            echo "Expecting $NODE_COUNT nodes but $FOUND_COUNT nodes have been deployed"
            exit 1
        fi
    fi

    time openstack overcloud -v deploy \
          --deployed-server \
          --libvirt-type qemu \
          --stack $STACK \
          --templates ~/templates \
          -r hci_roles.yaml \
          -p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml \
          -n ../network-data.yaml \
          -e ~/templates/environments/deployed-server-environment.yaml \
          -e ~/templates/environments/network-isolation.yaml \
          -e ~/templates/environments/network-environment.yaml \
          -e ~/templates/environments/disable-telemetry.yaml \
          -e ~/templates/environments/low-memory-usage.yaml \
          -e ~/templates/environments/docker-ha.yaml \
          -e ~/templates/environments/podman.yaml \
          -e ~/containers-prepare-parameter.yaml \
          -e ~/re-generated-container-prepare.yaml \
          -e ~/oc0-domain.yaml \
          -e deployed-metal-$STACK.yaml \
          -e overrides.yaml \
          -e ~/templates/environments/cephadm/cephadm.yaml \
          -e cephadm-overrides.yaml

    # parking this here for now (re-insert between -r and -n)
    #   -p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml \
    # parking this here for now (cephadm)
          # -e ~/templates/environments/cephadm/cephadm.yaml \
          # -e cephadm-overrides.yaml
    # (ceph-ansible)
          # -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
          # -e ceph-ansible-overrides.yaml
    # --disable-validations \
fi
# -------------------------------------------------------
if [[ $DOWN -eq 1 ]]; then
    pushd ~/config-download/hci/
    bash ansible-playbook-command.sh
    popd
fi
# -------------------------------------------------------
if [[ $RMCEPH -eq 1 ]]; then
    INV=~/overcloud-deploy/$STACK/config-download/$STACK/tripleo-ansible-inventory.yaml
    ansible-playbook -i $INV ../external/utilities/rm_ceph.yaml
fi
