
## Bootstrap oc0-ceph-0

From oc0-ceph-0:
```
IP=192.168.24.19
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm
chmod +x cephadm

mkdir -p /etc/ceph
./cephadm bootstrap --mon-ip $IP

./cephadm shell -- ceph -s
```

## Distribute Ceph's SSH key

From undercloud:
```
IP=192.168.24.19
scp heat-admin@$IP:/etc/ceph/ceph.pub .
URL=$(cat ceph.pub | curl -F 'sprunge=<-' http://sprunge.us)
ansible -i inventory.yaml allovercloud -b -m authorized_key -a "user=root key=$URL"
```

## Add other hosts

From oc0-ceph-0

Verify SSH works:
```
./cephadm shell -- ceph cephadm get-ssh-config > ssh_config
./cephadm shell -- ceph config-key get mgr/cephadm/ssh_identity_key > key
chmod 600 key

ssh -F ssh_config -i key root@oc0-ceph-1 
ssh -F ssh_config -i key root@oc0-ceph-2
```

Add hosts
```
./cephadm shell -- ceph orch host add oc0-ceph-1
./cephadm shell -- ceph orch host add oc0-ceph-2
```

Use their disks as OSDs
```
./cephadm shell -- ceph orch device ls
./cephadm shell -- ceph orch apply osd --all-available-devices
```

## Create key/pools for openstack

Create pools/key
```
./cephadm shell
for P in vms volumes images; do ceph osd pool create $P; done
for P in vms volumes images; do ceph osd pool application enable $P rbd; done

ceph auth add client.openstack mgr 'allow *' mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=vms, allow rwx pool=volumes, allow rwx pool=images'
```

Test it
```
./cephadm shell 
ceph auth get client.openstack > /etc/ceph/ceph.client.openstack.keyring

rbd -n client.openstack --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.openstack.keyring ls images

rbd -n client.openstack --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.openstack.keyring create --size 1024 images/foo

rbd -n client.openstack --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.openstack.keyring rm images/foo
```

Export files useful for clients
```
./cephadm shell -- ceph auth get client.openstack > /etc/ceph/ceph.client.openstack.keyring
./cephadm shell -- ceph config generate-minimal-conf > /etc/ceph/ceph.conf
```

