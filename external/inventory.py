#!/usr/bin/env python3

# POC of
# https://review.opendev.org/#/c/723108/39/specs/wallaby/tripleo-ceph.rst@460

import argparse
import yaml
import sys

def parse_opts(argv):
    parser = argparse.ArgumentParser(
            description='Create ansible inventory file for tripleo ceph')
    parser.add_argument('-m', '--deployed-metal-file', metavar='METAL',
                        help=("Relative path to a file like 'deployed-metal.yaml' "
                              "which is genereated by running a command like "
                              "'openstack overcloud node provision ... "
                              "--output deployed-metal.yaml' "
                              ),
                        required=True)
    parser.add_argument('-i', '--inventory-file', metavar='INVENTORY_FILE',
                        help="Path to ansible inventory file this command outputs"
                        " (default: inventory.ini)", default='inventory.yaml')
    parser.add_argument('-r', '--roles-file', metavar='ROLES',
                        help=("The TripleO roles file (default: "
                              "/usr/share/openstack-tripleo-heat-templates/roles_data.yaml)"
                              ),
                        default='/usr/share/openstack-tripleo-heat-templates/roles_data.yaml')
    parser.add_argument('-u', '--ssh-user', metavar='USER', 
                        help=("The username of an account with SSH access "
                              "on all servers (default: 'heat-admin')"),
                        default='heat-admin')
    opts = parser.parse_args(argv[1:])

    return opts


def get_undercloud_inv():
    # cheating here
    return {'Undercloud': {'hosts': {'undercloud': {}}, 'vars': {'ansible_connection': 'local', 'ansible_host': 'localhost', 'ansible_python_interpreter': '/usr/libexec/platform-python'}}}


def get_roles():
    # in a real implementation we'd cross check what's in
    # ironic_data_file against roles_file
    return ['mons','mgrs','osds', 'allovercloud']


def get_vars(user):
    return {'ansible_ssh_user': user,
            'ansible_python_interpreter': '/usr/libexec/platform-python'}


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


def write_to_file(inv):
    if OPTS.inventory_file:
        file_name = OPTS.inventory_file
    else:
        file_name = 'inventory.yaml'
    with open(file_name, 'w') as outfile:
        yaml.dump(inv, outfile, indent=2)


if __name__ == "__main__":
    OPTS = parse_opts(sys.argv)
    port_map = parse_metal(OPTS.deployed_metal_file)
    inv = get_undercloud_inv()
    for role in get_roles():
        hosts = {}
        for host, host_map in port_map.items():
            try:
                ip = host_map['fixed_ips'][0]['ip_address']
            except Exception:
                raise RuntimeError(
                    'The DeployedServerPortMap is missing the first '
                    'fixed_ip in the data file: {ironic_data_file}'.format(
                        ironic_data_file=OPTS.deployed_metal_file))
            hosts[host] = {'ansible_host': ip}

        inv[role] = {'hosts': hosts,
                     'vars': get_vars(OPTS.ssh_user)}

    write_to_file(inv)
