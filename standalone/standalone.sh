#!/bin/bash

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

CONTAINER_FILE=/home/stack/containers-prepare-parameters.yaml
if [[ ! -e $CONTAINER_FILE ]]; then
    # need sudo to write to /var/lib/image-serve
    sudo openstack tripleo container image prepare default \
         --local-push-destination \
         --output-env-file $CONTAINER_FILE
    sudo chown stack:stack $CONTAINER_FILE
fi

sudo openstack tripleo deploy \
  --templates ~/templates \
  --local-ip=192.168.23.1/24 \
  -e ~/templates/environments/standalone/standalone-tripleo.yaml \
  -r ~/templates/roles/Standalone.yaml \
  -e $CONTAINER_FILE \
  -e ~/standalone_parameters.yaml \
  --output-dir $HOME \
  --standalone $@
