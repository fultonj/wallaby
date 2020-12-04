#!/usr/bin/env bash


if [[ -z "$1" ]]; then
    POOL=volumes
else
    POOL=$1
fi

rm -f ls_rbd*.txt 2> /dev/null

STACKS="control-plane,dcn0,dcn1"

export ANSIBLE_DEPRECATION_WARNINGS=0
export ANSIBLE_TRANSFORM_INVALID_GROUP_CHARS=ignore
export ANSIBLE_LOG_PATH="/dev/null"
export ANSIBLE_STDOUT_CALLBACK=null
INV=inventory.yml
rm -f $INV
source ~/stackrc
if [[ ! -e $INV ]]; then
    tripleo-ansible-inventory --static-yaml-inventory $INV --stack $STACKS
    # ansible -i inventory.yml all -m ping
fi

echo "Collecting $POOL for $STACKS"
ansible-playbook -i $INV ls_rbd.yml -e save_output=true -e pool=$POOL > /dev/null
for REPORT in $(ls ls_rbd*.txt); do
    echo "-------------------------------------------------------"
    cat $REPORT
    echo -e "\n"
    rm -f $REPORT
done
