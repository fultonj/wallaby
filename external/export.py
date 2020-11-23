#!/usr/bin/env python3

# POC of
# https://review.opendev.org/#/c/723108/39/specs/wallaby/tripleo-ceph.rst@460

import argparse
import configparser
import yaml
import sys

def parse_opts(argv):
    parser = argparse.ArgumentParser(
            description='Create paramters for new ceph client role')
    parser.add_argument('-t', '--type', metavar='TYPE',
                        help=("What type of file to create. E.g. "
                              "'old' creates a file like ceph-ansible-external.yaml "
                              "'new' creates a file like /home/stack/ceph_client.yaml"),
                        default='old', choices=['old', 'new'])
    parser.add_argument('-k', '--cephx-key-file', metavar='CEPHX_FILE',
                        help="Path to cephx keyring file"
                        " (default: ceph.client.openstack.keyring)",
                        default='ceph.client.openstack.keyring')
    parser.add_argument('-c', '--ceph-conf-file', metavar='CONF',
                        help=("Path to ceph.conf file "
                              "(default ceph.conf)"),
                        default='ceph.conf')
    parser.add_argument('-o', '--output-file', metavar='OUT_FILE', 
                        help=("Path to the output file"
                              "(default: 'ceph-external.yaml')"),
                        default='ceph-external.yaml')
    opts = parser.parse_args(argv[1:])

    return opts


def write_to_file(inv):
    if OPTS.output_file:
        file_name = OPTS.output_file
    else:
        file_name = 'inventory.yaml'
    with open(file_name, 'w') as outfile:
        yaml.dump(inv, outfile, indent=2)

def get_cephx_key(keyring):
    config = configparser.ConfigParser()
    config.read(keyring)
    return config['client.openstack']['key']

def get_cephx_yaml(keyring):
    config = configparser.ConfigParser()
    config.read(keyring)
    caps = {}
    caps['mgr'] = config['client.openstack']['caps mgr'].replace('"',"")
    caps['mon'] = config['client.openstack']['caps mon'].replace('"',"")
    caps['osd'] = config['client.openstack']['caps osd'].replace('"',"")
    ret = {}
    ret['name'] = 'client.openstack'
    ret['key'] = config['client.openstack']['key']
    ret['caps'] = caps
    return [ret]

def get_fsid_mons(conf):
    config = configparser.ConfigParser()
    config.read(conf)
    return config['global']['fsid'], config['global']['mon_host']

if __name__ == "__main__":
    OPTS = parse_opts(sys.argv)
    fsid, mons = get_fsid_mons(OPTS.ceph_conf_file)
    out = {}
    if OPTS.type == 'new':
        out['fsid'] = fsid
        out['external_cluster_mon_ips'] = mons
        out['keys'] = get_cephx_yaml(OPTS.cephx_key_file)
    elif OPTS.type == 'old':
        three_params = {}
        three_params['CephClusterFSID'] = fsid
        three_params['CephExternalMonHost'] = mons
        three_params['CephClientKey'] = get_cephx_key(OPTS.cephx_key_file)
        out['paramteter_defaults'] = three_params
    write_to_file(out)
