#!/bin/bash
# Pick the container-tools dnf module podman should come from
OLD=2.0
NEW=3.0

# WARNING removing podman to downgrade it will remove nearly all
# tripleo packages so the script re-installs python3-tripleoclient.
# 
# A new c8-stream undercloud is installed with podman from AppStream.
# It tends to be very new and ahead of what TripleO CI tests with.
# Use this script to uninstall it and install an older one from the
# appropriate version of container-tools:
# 
#   https://access.redhat.com/support/policy/updates/containertools
#
# AppStream podman "too new" because I have run into the following:
# 
# podman 3.1 fails to start iscsid on undercloud downgrade to 3.0
# 
# podman 3 fails like this: 
#   "Failed to create bus connection: No such file or directory"
# When using molecule as descrbed in [1], downgrade to podman 2.y
# [1] http://blog.johnlikesopenstack.com/2020/06/running-tripleo-ansible-molecule.html

podman --version

sudo dnf repolist
sudo dnf module list
sudo dnf module disable -y container-tools:${OLD}
sudo dnf module enable -y container-tools:${NEW}
sudo dnf clean metadata
sudo dnf clean all
sudo dnf update -y

podman --version
sudo dnf remove podman -y
sudo dnf install podman -y
podman --version

sudo -E tripleo-repos current-tripleo-dev ceph --stream
sudo dnf install -y python3-tripleoclient
