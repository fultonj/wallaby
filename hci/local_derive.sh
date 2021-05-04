#!/bin/bash
# Does's what's described here:
# https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/derived_parameters.html

source ~/stackrc

PUSH=1
CEPHADM=1

if [[ $PUSH -eq 1 ]]; then
    TGT="/usr/share/ansible/plugins/modules/tripleo_derive_hci_parameters.py"
    SRC="/home/stack/tripleo-ansible/tripleo_ansible/ansible_plugins/modules/tripleo_derive_hci_parameters.py"
    sudo cp -v $SRC $TGT
fi

SRC=~/tripleo-ansible/tripleo_ansible/playbooks/derive-local-hci-parameters.yml
TGT="$PWD/derive-local-hci-parameters.yml"
echo "Make a new copy of playbook:"
cp -f -v $SRC $TGT

if [[ ! -e $TGT ]]; then
    echo "$TGT is missing"
    exit 1
fi

UUID=e18ba431-3c1f-4ff8-94cd-72e86ba59a4a
# UUID=$(openstack baremetal node list -f value -c Name -c UUID \
#            | grep oc0-ceph-0 | awk {'print $1'})

echo "Update ironic_node_id:"
grep ironic_node_id: $TGT
sed -i s/\\#\ provide\ your\ Ironic\ UUID\ here/$UUID/g $TGT
grep ironic_node_id: $TGT

echo "Update heat_environment_input_file:"
grep heat_environment_input_file: $TGT
if [[ $CEPHADM -eq 1 ]]; then
    sed -i s/\\/home\\/stack\\/ceph_overrides.yaml/\\/home\\/stack\\/wallaby\\/hci\\/cephadm-overrides.yaml/g $TGT
else
    sed -i s/\\/home\\/stack\\/ceph_overrides.yaml/\\/home\\/stack\\/wallaby\\/hci\\/ceph-ansible-overrides.yaml/g $TGT
fi
grep heat_environment_input_file: $TGT

if [[ -e /home/stack/hci_result.yaml ]]; then
    rm -f /home/stack/hci_result.yaml
fi
if [[ -e /home/stack/hci_report.txt ]]; then
    rm -f /home/stack/hci_report.txt
fi

echo "Run playbook"
ansible-playbook $TGT

if [[ -e /home/stack/hci_result.yaml ]]; then
    echo "---------"
    cat /home/stack/hci_result.yaml
fi
if [[ -e /home/stack/hci_report.txt ]]; then
    echo "---------"
    cat /home/stack/hci_report.txt
    echo -e "\n---------"
fi
