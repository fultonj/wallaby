#!/usr/bin/env bash

export INTERFACE=eth0
export IP=192.168.24.2
export VIP=192.168.24.3
export NETMASK=24
export DNS_SERVERS=192.168.122.1
export NTP_SERVERS=pool.ntp.org

cat <<EOF > $HOME/standalone_parameters.yaml
parameter_defaults:
  CloudName: $IP
  ControlPlaneStaticRoutes: []
  Debug: true
  DeploymentUser: $USER
  DnsServers: $DNS_SERVERS
  NtpServer: $NTP_SERVERS
  # needed for vip & pacemaker
  KernelIpNonLocalBind: 1
  DockerInsecureRegistryAddress:
  - $IP:8787
  NeutronPublicInterface: $INTERFACE
  # domain name used by the host
  NeutronDnsDomain: localdomain
  # re-use ctlplane bridge for public net
  NeutronBridgeMappings: datacentre:br-ctlplane
  NeutronPhysicalBridge: br-ctlplane
  # enable to force metadata for public net
  #NeutronEnableForceMetadata: true
  StandaloneEnableRoutedNetworks: false
  StandaloneHomeDir: $HOME
  InterfaceLocalMtu: 1500
  # Needed if running in a VM
  NovaComputeLibvirtType: qemu
EOF

if [ ! -f $HOME/ceph_parameters.yaml ]; then
  cat <<EOF > $HOME/ceph_parameters.yaml
parameter_defaults:
  CephAnsibleDisksConfig:
    osd_scenario: lvm
    osd_objectstore: bluestore
    lvm_volumes:
      - data: data-lv2
        data_vg: vg2
        db: db-lv2
        db_vg: vg2
  CephAnsibleExtraConfig:
    cluster_network: 192.168.24.0/24
    public_network: 192.168.24.0/24
  CephPoolDefaultPgNum: 32
  CephPoolDefaultSize: 1
EOF
fi

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

# sudo pkill -9 heat-all # Remove any previously running heat processes
sudo openstack tripleo deploy \
  --templates ~/templates \
  --local-ip=$IP/$NETMASK \
  --control-virtual-ip $VIP \
  -e ~/templates/environments/standalone/standalone-tripleo.yaml \
  -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
  -r ~/templates/roles/Standalone.yaml \
  -e ~/containers-prepare-parameters.yaml \
  -e ~/standalone_parameters.yaml \
  -e ~/ceph_parameters.yaml \
  --output-dir $HOME \
  --standalone $@


#  --keep-running \
