#!/bin/bash
# patch puppet-tripleo on predeployed nodes
# 
# currently using to apply changes from:
# https://review.opendev.org/c/openstack/puppet-tripleo/+/763545
# assumes SRC contains result of 'git review -d 763545'

SRC=/home/stack/puppet-tripleo
TAR=manifests.tar.gz
DST=/usr/share/openstack-puppet/modules/tripleo
INV=inventory_openstack.yaml
METAL=deployed-metal-openstack-only.yaml

if [[ ! -e $METAL ]]; then
    echo "Error: $METAL missing"
    exit 1
fi
if [[ ! -e $INV ]]; then
    python3 inventory.py -m $METAL -i $INV
    if [[ ! -e $INV ]]; then
        echo "Error: $INV missing"
        exit 1
    fi
fi
ansible -i $INV allovercloud -m ping 
if [[ $? -gt 0 ]]; then
    echo "ERROR: unable to ansible ping all hosts with ansible inventory"
    exit 1
fi

echo "Creating fresh copy of $TAR"
if [[ -e $TAR ]]; then
    rm -f $TAR
fi
pushd $SRC
tar cfz $TAR manifests
popd
mv $SRC/$TAR .

echo "Backing up $DST/manifests to $DST/manifests.old on all nodes"
ansible -i $INV allovercloud -b -m shell -a "mv $DST/manifests $DST/manifests.old"

echo "Pusing $TAR to $DST on all nodes"
ansible -i $INV allovercloud -b -m copy -a "src=$TAR dest=$DST"

echo "Untarring $TAR to $DST/manifests on all nodes"
ansible -i $INV allovercloud -b -m shell -a "pushd $DST; tar xf $TAR"

echo "Listing contents of $DST on all nodes"
ansible -i $INV allovercloud -b -m shell -a "ls -l $DST"

rm $TAR
