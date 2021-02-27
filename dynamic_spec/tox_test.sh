#!/bin/bash

pushd /home/stack/tripleo-ansible
tox -e py36 -- tripleo_ansible.tests.modules.test_ceph_spec_bootstrap.*
popd

