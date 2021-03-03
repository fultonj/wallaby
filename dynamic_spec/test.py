import ceph_spec_bootstrap

metal = "/home/stack/tripleo-ansible/roles/tripleo_cephadm/molecule/default/mock_deployed_metal.yaml"
hosts = ceph_spec_bootstrap.get_deployed_servers(metal)
print(hosts)

