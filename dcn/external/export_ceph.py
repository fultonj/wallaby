#!/usr/bin/python3

import argparse
import sys
import yaml

parser = argparse.ArgumentParser()
parser.add_argument('--stack', type=str, default='ceph2',
                    help='name of the stack (default: ceph2)')
args = parser.parse_args()

# -------------------------------------------------------

def write_to_file(data):
    file_name = 'export_' + args.stack + '.yaml'
    with open(file_name, 'w') as outfile:
        yaml.dump(data, outfile, indent=2)

# -------------------------------------------------------

def read_from_file(the_file):
    with open(the_file, 'r') as stream:
        try:
            ceph = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
        try:
            key = ceph['parameter_defaults']['CephClientKey']
            fsid = ceph['parameter_defaults']['CephClusterFSID']
            mon = ceph['parameter_defaults']['CephExternalMonHost']
            return key, fsid, mon
        except Exception:
            print('cannot extract expected values from ' + the_file)
    return 0,0,0

# -------------------------------------------------------

if args.stack == 'ceph2':
    the_file='control-plane-e/ceph-external-ceph2.yaml'
    cluster='central'
elif args.stack == 'ceph3':
    the_file='dcn0e/ceph-external-ceph3.yaml'
    cluster='dcn0'
else:
    sys.exit('invalid stack')
    
key, fsid, mon = read_from_file(the_file)

expected = {
    'external_cluster_mon_ips': mon,
    'keys': [
        {
            'name': 'client.openstack',
            'key': key,
            'mode': "0600",
            'caps': {
                'mgr': "allow *",
                'mon': "profile rbd",
                'osd': "profile rbd pool=volumes, profile rbd pool=vms, profile rbd pool=images"
            }
        }
    ],
    'ceph_conf_overrides': {
        'client': {
            'keyring': '/etc/ceph/' + cluster + '.client.openstack.keyring'
        }
    },
    'cluster': cluster,
    'fsid': fsid,
    'dashboard_enabled': False
}
data = {}
data['parameter_defaults'] = {}
data['parameter_defaults']['CephExternalMultiConfig'] = [expected]

write_to_file(data)
