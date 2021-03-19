#!/bin/bash

# Pick the desired version of podman you want to run
DESIRED=2
#DESIRED=3

# Because podman 3 fails like this: 
#   "Failed to create bus connection: No such file or directory"
# When using molecule as descrbed in [1].
# Workaround by downgrading to podman 2, but I can easily go back to 3.
# This script helps me bounce between the two on my undercloud.
# [1] http://blog.johnlikesopenstack.com/2020/06/running-tripleo-ansible-molecule.html

CURRENT_FULL=$(podman --version | awk {'print $3'})
if [[ $CURRENT_FULL =~ "3" ]]; then
    CURRENT="3"
fi
if [[ $CURRENT_FULL =~ "2" ]]; then
    CURRENT="2"
fi
echo "Current Version is $CURRENT ($CURRENT_FULL)"
if [[ $CURRENT == $DESIRED ]]; then
    echo "You already have the desired version ($DESIRED)"
    exit 0
fi
echo "Changing podman version from $CURRENT to $DESIRED"

echo "Please implement me I'm not working yet"
