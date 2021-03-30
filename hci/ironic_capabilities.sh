#!/bin/bash

ADD=1
REMOVE=0

# https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/13/html-single/hyperconverged_infrastructure_guide/index#prepare-overcloud-role

source ~/stackrc

declare -A MAP
MAP[oc0-ceph-0]="computeHCI"       # ComputeHCI
MAP[oc0-ceph-1]="computeHCI"       # ComputeHCI
MAP[oc0-ceph-2]="computeHCI2"      # ComputeHCI2

for K in "${!MAP[@]}"; do
    echo "$K ---> ${MAP[$K]}";
    CAP=$(openstack baremetal node show $K -f value \
              | grep cap | grep -v kernel | sed s/\'/\"/g \
              | jq .capabilities | sed s/\"//g)
    if [[ $ADD -eq 1 ]]; then
        if [[ $(echo $CAP | grep profile | wc -l) -eq 0 ]]; then
            NEW_CAP="${CAP},profile:${MAP[$K]}"
        fi
    fi
    if [[ $REMOVE -eq 1 ]]; then
        NEW_CAP=$(echo ${CAP} | sed s/,profile:${MAP[$K]}//g)
    fi
    if [[ ${#NEW_CAP} -gt 0 ]]; then
        echo "Setting $NEW_CAP"
        openstack baremetal node set $K \
                  --property capabilities="$NEW_CAP"
    else
        echo "$K is already in desired state."
    fi
    openstack baremetal node show $K -f value | grep cap | grep -v kernel
done

