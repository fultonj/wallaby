METAL=False
STANDALONE=False
FQDN=False

import ceph_spec_bootstrap
import pprint
import yaml

pp = pprint.PrettyPrinter(indent=4)
ceph_service_types = ['mon', 'mgr', 'osd']

if STANDALONE:
    inventory_file = "/home/stack/tripleo-ansible/roles/tripleo_cephadm/molecule/default/mock_inventory.yml"
    tripleo_roles = "/usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml"
else:
    inventory_file = "/home/stack/wallaby/dynamic_spec/inv/multinode_inventory.yml"
    tripleo_roles = "/usr/share/openstack-tripleo-heat-templates/roles_data.yaml"

if METAL:
    roles_to_svcs = ceph_spec_bootstrap.get_roles_to_svcs_from_roles(tripleo_roles)
    deployed_metalsmith = "/home/stack/tripleo-ansible/roles/tripleo_cephadm/molecule/default/mock_deployed_metal.yaml"
    hosts_to_ips = ceph_spec_bootstrap.get_deployed_hosts_to_ips(deployed_metalsmith)
    roles_to_hosts = ceph_spec_bootstrap.get_deployed_roles_to_hosts(deployed_metalsmith,
                                                                     roles_to_svcs.keys())
else:
    with open(inventory_file, 'r') as stream:
        inventory = yaml.safe_load(stream)

    roles_to_svcs = ceph_spec_bootstrap.get_roles_to_svcs_from_inventory(inventory)
    hosts_to_ips = ceph_spec_bootstrap.get_inventory_hosts_to_ips(inventory,
                                                                  roles_to_svcs.keys(),
                                                                  FQDN)
    roles_to_hosts = ceph_spec_bootstrap.get_inventory_roles_to_hosts(inventory,
                                                                      roles_to_svcs.keys(),
                                                                      FQDN)
    pp.pprint(hosts_to_ips)
    pp.pprint(roles_to_hosts)
    exit()

label_map = ceph_spec_bootstrap.get_label_map(hosts_to_ips, roles_to_svcs,
                                              roles_to_hosts, ceph_service_types)
das_yaml = '''
data_devices:
  all: true
    '''
osd_spec = yaml.safe_load(das_yaml)
specs = ceph_spec_bootstrap.get_specs(hosts_to_ips, label_map,
                                          ceph_service_types, osd_spec)

#pp.pprint(hosts_to_ips)
#pp.pprint(roles_to_hosts)
pp.pprint(specs)
