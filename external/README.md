# External Deployment

Use two stacks to test an external ceph deployment with new tools.

## What you get

Stack 1:
- 3 ceph-all nodes

Stack 2:
- 3 controller
- 2 compute

## How to do it

- Use [deploy_ceph.sh](deploy_ceph.sh) to:
  - deploy hardware to host Ceph (NET=METAL=1)
  - install ceph w/ tripleo_cephadm role (CEPH=1) (automates [manual_ceph.md](manual_ceph.md))
  - create ceph-external.yaml Ceph (EXPORT=1)
- Use [deploy_openstack.sh](deploy_openstack.sh) to have TripleO use
  ceph-external.yaml to deploy OpenStack and use the external ceph
  cluster.
