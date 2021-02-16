# Deploy DCN with External Storage

## Deployment Topology

Deploy two independent Ceph clusters to be used as external Ceph
clusters by TripleO. Then deploy a central site which uses one of the
external Ceph clusters and a DCN site which uses the other external
Ceph cluster. Then use ask the control-plane Glance to upload an
image to multiple DCN sites so they can be COW fast-booted on that
site and by using external Ceph.

The virtual hardware will be deployed in the following stacks and
roles.

```
+------------------+
| ceph2            |
+------------------+
| oc0-ceph-2       |    Ceph Mon/Mgr/OSD
+------------------+

+------------------+
| ceph3            |
+------------------+
| oc0-ceph-3       |    Ceph Mon/Mgr/OSD
+------------------+

+------------------+
| control-plane-e  |    CephClusterName: central
+------------------+
| oc0-controller-0 |    Controller (Glance + Cinder)
| oc0-controller-1 |    Controller (Glance + Cinder)
| oc0-controller-2 |    Controller (Glance + Cinder)
| oc0-ceph-0       |    Compute (Nova)
+------------------+

+------------------+
| dcn0e            |    CephClusterName: dcn0
+------------------+
| oc0-ceph-1       |    DistributedCompute (Glance + Nova + Cinder)
+------------------+
```

## How to deploy it with TripleO

- Use [master.sh](master.sh) to:
  - Deploy ceph2 for control-plane-e and ceph3 for dcn0e
  - Deploy control-plane-e with [control-plane-e/deploy.sh](control-plane-e/deploy.sh)
  - Create `control-plane-export.yaml` (`openstack overcloud export -f --stack control-plane`)
  - Create `ceph-export-control-plane.yaml` with [export_ceph.py](export_ceph.py).
  - Deploy dcn0e with [dcn0e/deploy.sh](dcn0e/deploy.sh)
  - Create `ceph-export-dcn0.yaml` with [export_ceph.py --stack ceph3](export_ceph.py).
  - Update control-plane-e/deploy.sh to use `ceph-export-dcn0e.yaml`
  - Update control-plane-e/deploy.sh to use [control-plane-e/glance_update.yaml](control-plane-e/glance_update.yaml)
  - Re-run control-plane-e/deploy.sh

Each deploy script will use [metalsmith](../../metalsmith)
to [provision](../../provision.sh) the nodes for each stack
and the [kill](../../kill.sh) script will unprovision the nodes.

## Validations

Use the same validations as seen [Non-external DCN](../README.md).
