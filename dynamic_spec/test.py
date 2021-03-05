METAL=False
STANDALONE=False

import ceph_spec_bootstrap
import pprint
import yaml

pp = pprint.PrettyPrinter(indent=4)
ceph_service_types = ['mon', 'mgr', 'osd']

if STANDALONE:
    inventory_file = "standalone_inventory.yml"
    tripleo_roles = "/usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml"
else:
    inventory_file = "multinode_inventory.yml"
    tripleo_roles = "/usr/share/openstack-tripleo-heat-templates/roles_data.yaml"

roles_to_svcs = ceph_spec_bootstrap.get_ceph_services(tripleo_roles)

if METAL:
    deployed_metalsmith = "/home/stack/tripleo-ansible/roles/tripleo_cephadm/molecule/default/mock_deployed_metal.yaml"
    hosts_to_ips = ceph_spec_bootstrap.get_deployed_hosts_to_ips(deployed_metalsmith)
    roles_to_hosts = ceph_spec_bootstrap.get_deployed_roles_to_hosts(deployed_metalsmith,
                                                                     roles_to_svcs.keys())
else:
    pre="/home/stack/wallaby/dynamic_spec/inv/"
    with open(pre + inventory_file, 'r') as stream:
        inventory = yaml.safe_load(stream)
    hosts_to_ips = ceph_spec_bootstrap.get_inventory_hosts_to_ips(inventory,
                                                                  roles_to_svcs.keys())
    roles_to_hosts = ceph_spec_bootstrap.get_inventory_roles_to_hosts(inventory,
                                                                      roles_to_svcs.keys())

label_map = ceph_spec_bootstrap.get_label_map(hosts_to_ips, roles_to_svcs,
                                                  roles_to_hosts, ceph_service_types)
das_yaml = '''
data_devices:
  all: true
    '''
osd_spec = yaml.safe_load(das_yaml)
specs = ceph_spec_bootstrap.get_specs(hosts_to_ips, label_map,
                                          ceph_service_types, osd_spec)

pp.pprint(specs)
