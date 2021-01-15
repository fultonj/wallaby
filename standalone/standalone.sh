#!/bin/bash

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

sudo openstack tripleo deploy \
  --templates ~/templates \
  --local-ip=192.168.23.1/24 \
  -e ~/templates/environments/standalone/standalone-tripleo.yaml \
  -r ~/templates/roles/Standalone.yaml \
  -e ~/generated-container-prepare.yaml \
  -e ~/standalone_parameters.yaml \
  --output-dir $HOME \
  --standalone $@
