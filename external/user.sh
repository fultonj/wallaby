#!/bin/bash

DELETE=1
CREATE=1
CHECK=1

INV=inventory.yaml
if [[ ! -e $INV ]]; then
    echo "ERROR: no ansible inventory $INV"
    exit 1
fi

if [[ $DELETE -eq 1 ]]; then
    ansible -i $INV ceph_mon,ceph_osd -b -m shell -a \
            "rm -f /home/ceph-admin/.ssh/*"
    rm -f ~/.ssh/ceph-admin-id_rsa*
fi

if [[ $CREATE -eq 1 ]]; then
    echo "Enabling public and private keys for mons"
    ansible-playbook-3 -i $INV -v \
            /usr/share/ansible/tripleo-playbooks/ceph-admin-user-playbook.yml \
            -e tripleo_admin_user=ceph-admin \
            -e distribute_private_key=true \
            --limit undercloud,ceph_mon,ceph_mgr

    echo "Enabling only public and private keys for all other ceph nodes"
    ansible-playbook-3 -i $INV -v \
            /usr/share/ansible/tripleo-playbooks/ceph-admin-user-playbook.yml \
            -e tripleo_admin_user=ceph-admin \
            -e distribute_private_key=false \
            --limit undercloud,ceph_osd,ceph_rgw,ceph_mds,ceph_nfs,ceph_rbdmirror
fi

if [[ $CHECK -eq 1 ]]; then
    echo "Local"
    ls -l ~/.ssh/ceph-admin-id_rsa*
    echo "Mons"
    ansible -i $INV ceph_mon -b -m shell -a \
            "ls -l /home/ceph-admin/.ssh/*"
    echo "OSDs"
    ansible -i $INV ceph_osd -b -m shell -a \
            "ls -l /home/ceph-admin/.ssh/*"
fi
