# Use tripleo-lab to create an undercloud

I run the following on
[my hypervisor](http://blog.johnlikesopenstack.com/2018/08/pc-for-tripleo-quickstart.html)
which is running centos8.

## Prepare tripleo-lab

```
 sudo /usr/local/bin/lab-destroy

 git clone git@github.com:cjeanner/tripleo-lab.git

 cd tripleo-lab

 cat inventory.yaml.example | sed s/IP_ADDRESS/127.0.0.1/g > inventory.yaml

 cp ~/wallaby/tripleo-lab/overrides.yml environments/overrides.yml
 cp ~/wallaby/tripleo-lab/topology-* environments/

 diff -u builder.yaml ~/wallaby/tripleo-lab/builder.yaml
 cp ~/wallaby/tripleo-lab/builder.yaml builder.yaml

 ansible -i inventory.yaml -m ping builder

 ansible-playbook -i inventory.yaml config-host.yaml
```

## Deploy undercloud configured with Metalsmith

```
 ansible-playbook -i inventory.yaml builder.yaml -e @environments/overrides.yml -e @environments/metalsmith.yaml -e @environments/topology-standard.yml
```

The tasks referenced by the tags `-t domains -t baremetal -t vbmc`
(which are inclusive in the above example) will provision the virtual
baremetal servers. See [metalsmith](../metalsmith/).

