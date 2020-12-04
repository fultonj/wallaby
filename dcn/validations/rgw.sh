#!/bin/bash

source ~/stackrc
MON=$(openstack server show control-plane-controller-0 -f value -c addresses | sed s/ctlplane=//g)
function run_on_mon {
    # since it will be run on the controller
    ssh heat-admin@$MON "sudo podman exec ceph-mon-\$(hostname) $1 --cluster central" 2> /dev/null
}

RC=~/control-planerc
if [[ ! -e $RC ]]; then
    echo "$RC is missing. Aborting."
    exit 1
fi
# run_on_mon "ceph df"

source $RC
COUNT=5
echo "Creating $COUNT swift containers and observing the RGW buckets.index increment"
for I in $(seq 0 $COUNT); do 
    openstack container create mydir$I
    sleep 1
    run_on_mon "ceph df" | egrep "POOL|index"
done

echo "Deleting the $COUNT swift containers"
openstack container list
for I in $(seq 0 $COUNT); do 
    openstack container delete mydir$I
done
openstack container list
run_on_mon "ceph df" | grep index
