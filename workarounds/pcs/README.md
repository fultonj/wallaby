# PCS workarounds

In mid Jan 2021 and mid Mar 2021 I ran into pcs package version
mismatches while working on the quickly changing TripleO main branch. 
This is my directory of workarounds.

## Problem presentation

Deployment fails with the following.
```
2021-01-15 20:21:57.019757 | 244200fb-93c8-11b5-7f74-000000001c8a |       TASK | Check containers status
 [ERROR]: Container(s) which failed to be created by podman_container module:
['mysql_wait_bundle']
 [ERROR]: Container(s) which did not finish after 300 minutes:
['mysql_wait_bundle']                                                   
2021-01-15 20:27:01.192326 | 244200fb-93c8-11b5-7f74-000000001c8a |      FATAL | Check containers status | standalone | error={"changed": false, "msg": "Failed container(s): ['mysql_wait_bundle'], check logs in /var/log/containers/stdouts/"} 
```

## Root cause

The packemaker RPMs on the container host have to be the same as the
pacemaker RPMs in the container.

## Workaround

Upgrade or downgrade the container host to have the same version as
the continer.

## Determine the pacemaker version in the container

The undercloud mysql container will have the pacemaker package so you
can see what it's using. 

```
[CentOS-8 - root@undercloud ~]#  sudo podman exec -ti mysql  rpm -q pacemaker
pacemaker-2.0.5-9.el8.x86_64
[CentOS-8 - root@undercloud ~]# 
```

You can also check on the failed mysql_wait_bundle container:

```
[stack@standalone ~]$ sudo podman exec -ti mysql_wait_bundle rpm -q pacemaker
pacemaker-2.0.4-6.el8.x86_64
[stack@standalone ~]$ 
```

## Option 1: get a newer image

The container host is based on the overcloud-full.tar image. TripleO
lab pulls it from:

 https://images.rdoproject.org/centos8/master/rdo_trunk/current-tripleo/

tripleo-lab [downloads and modifies](https://github.com/cjeanner/tripleo-lab/blob/e1a9947ad30f1afe8c28c3383f5172be848ed187/roles/overcloud/tasks/manage-oc-images.yaml#L77)
the overcloud-full.tar image. 

This process
can [fail](http://paste.openstack.org/show/803585) if the overcloud
image repos are not able to get the newer versions of the packages.

Idenitfy if a newer build of the image is available and take note of
its hash directory from:

 https://images.rdoproject.org/centos8/master/rdo_trunk/

Remove the current images and update tripleo lab to pull form that
hash instead of "current-tripleo".

```
rm -f /home/stack/overcloud_imgs/*
vim /home/fultonj/tripleo-lab/roles/overcloud/tasks/centos-overcloud.yaml 
```

Replace 'current-tripleo' with the hash of a newer directory in the
[fetch images for centos task](https://github.com/cjeanner/tripleo-lab/blob/e1a9947ad30f1afe8c28c3383f5172be848ed187/roles/overcloud/tasks/centos-overcloud.yaml#L8).

Re-run tripleo-lab ansible.

## Option 2: upgrade/downgrade the hosts before overcloud deployment

After the [metalsmith](../metalsmith) script runs you have a set of
CentOS systems for which you can easily [build](../external/inventory.py)
an Ansible inventory. You can then use [pcs.sh](pcs.sh) to use Ansible
to install very specific package versions on those centos nodes before
you run 'openstack overcloud deploy'.

## Other

In theory you could also modify the overcloud image directly by
combining options 1 and 2 though I don't have scripts for that.
