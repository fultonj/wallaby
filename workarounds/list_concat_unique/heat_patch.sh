#!/bin/bash

SRC=/home/stack/heat/heat/engine/hot/functions.py 
TGT=/usr/lib/python3.6/site-packages/heat/engine/hot/functions.py

if [[ ! -d /home/stack/heat/ ]]; then
    echo "Failing: heat directory missing"
    echo "Please check out a copy of heat into /home/stack and run "
    echo "git review -d 787662"
    exit 1
fi

for C in heat_api heat_api_cron heat_engine; do
    sudo podman cp $SRC $C:$TGT
done

echo "You can verify like this: "
echo "sudo podman exec -ti heat_engine /bin/bash"
echo "grep -B 10 ListConcatUnique /usr/lib/python3.6/site-packages/heat/engine/hot/functions.py"
echo ""
echo "It should look like this diff:"
echo "https://review.opendev.org/c/openstack/heat/+/787662/3/heat/engine/hot/functions.py#1656"
echo ""
