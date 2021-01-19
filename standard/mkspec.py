#!/usr/bin/env python3

import argparse
import yaml
import sys

def parse_opts(argv):
    parser = argparse.ArgumentParser(
            description='Create cephadm spec file')
    parser.add_argument('-m', '--deployed-metal-file', metavar='METAL',
                        help=("Relative path to a file like 'deployed-metal.yaml' "
                              "which is genereated by running a command like "
                              "'openstack overcloud node provision ... "
                              "--output deployed-metal.yaml' "
                              ),
                        required=True)
    opts = parser.parse_args(argv[1:])

    return opts

def parse_metal(ironic_data_file):
    port_map = {}
    with open(ironic_data_file, 'r') as stream:
        try:
            metal = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
        try:
            port_map = metal['parameter_defaults']['DeployedServerPortMap']
        except Exception:
            raise RuntimeError(
                'The DeployedServerPortMap is not defined in '
                'data file: {ironic_data_file}'.format(
                ironic_data_file=ironic_data_file))
    return port_map

if __name__ == "__main__":
    OPTS = parse_opts(sys.argv)
    port_map = parse_metal(OPTS.deployed_metal_file)
    host_list = ['oc0-controller-1', 'oc0-controller-2',
                 'oc0-ceph-0', 'oc0-ceph-1', 'oc0-ceph-2']
    hosts = {}
    for host, host_map in port_map.items():
        try:
            ip = host_map['fixed_ips'][0]['ip_address']
        except Exception:
            raise RuntimeError(
                'The DeployedServerPortMap is missing the first '
                'fixed_ip in the data file: {ironic_data_file}'.format(
                    ironic_data_file=OPTS.deployed_metal_file))
        hosts[host.replace('-ctlplane','')] = ip

    for host in host_list:
            print('---')
            print('service_type: host')
            print('addr: %s' % hosts[host])
            print('hostname: %s' % host)
    print("""---
service_type: mon
placement:
  hosts:
    - oc0-controller-0
    - oc0-controller-1
    - oc0-controller-2
---
service_type: osd
service_id: default_drive_group
placement:
  hosts:
    - oc0-ceph-0
    - oc0-ceph-1
    - oc0-ceph-2
data_devices:
  all: true"""
)
