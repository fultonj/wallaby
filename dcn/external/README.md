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
| ceph-central     |    CephClusterName: central
+------------------+
| oc0-ceph-2       |    Ceph Mon/Mgr/OSD
+------------------+

+------------------+
| ceph-dcn0        |    CephClusterName: dcn0
+------------------+
| oc0-ceph-3       |    Ceph Mon/Mgr/OSD
+------------------+

+------------------+
| control-plane    |    CephClusterName: central
+------------------+
| oc0-controller-0 |    Controller (Glance + Cinder)
| oc0-controller-1 |    Controller (Glance + Cinder)
| oc0-controller-2 |    Controller (Glance + Cinder)
| oc0-ceph-0       |    Compute (Nova)
+------------------+

+------------------+
| dcn0             |    CephClusterName: dcn0
+------------------+
| oc0-ceph-1       |    DistributedCompute (Glance + Nova + Cinder)
+------------------+
```

## How to deploy it with TripleO

- Deploy ceph-central and ceph-dcn0

<!--
- Deploy control-plane with [control-plane/deploy.sh](control-plane/deploy.sh)
- Create `control-plane-export.yaml` (`openstack overcloud export -f --stack control-plane`)
- Create `ceph-export-control-plane.yaml` (`openstack overcloud export ceph -f --stack control-plane`)
- Deploy dcn0 with [dcn0/deploy.sh](dcn0/deploy.sh)
- Create `ceph-export-2-stacks.yaml` (`openstack overcloud export ceph -f --stack dcn0`)
- Update control-plane/deploy.sh to use `ceph-export-2-stacks.yaml`
- Update control-plane/deploy.sh to use [control-plane/glance_update.yaml](control-plane/glance_update.yaml)
- Re-run control-plane/deploy.sh
-->

Each deploy script will use [metalsmith](../metalsmith)
to [provision](provision.sh) the nodes for each stack
and the [kill](kill.sh) script will unprovision the nodes.

## Validations

Use the same validations as seen [Non-external DCN](../README.md).
