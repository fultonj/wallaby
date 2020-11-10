# Standard Deployment

## What do you get

An overcloud deployed with network isolation containing:

- 3 controller
- 2 compute
- 3 ceph-storage

## How to do it

Set flags in [deploy.sh](deploy.sh) to: 

- provision the baremetal ([metal.yaml](metal.yaml) or [metal-big.yaml](metal-big.yaml))
- create a heat stack
- download the configuration as ansible playbooks
- use ansible to configure the overcloud

Use [validate.sh](validate.sh) to run the following tests on the
deployed overcloud:

- Report on Ceph status
- Create a Cinder volume (and show it in ceph volumes pool)
- Create a Glance image (and show it in ceph images pool)
- Create a private Neutron network
- Create a Nova instance
