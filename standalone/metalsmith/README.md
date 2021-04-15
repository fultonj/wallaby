# Standalone on Metalsmith

[tripleo-lab supports standalone](https://github.com/cjeanner/tripleo-lab/blob/master/environments/standalone.yaml) by
deploying one VM which is the undercloud.

I prefer to keep my undercloud running for a few weeks before I
rebuild it and use metalsmith to provision disposable VMs for me to
reprovision daily. Thus, this directory contains a few scripts I use
to provision one VM with metalsmith on which I then run the standalone
tools.

## How to do it

- Use [deploy.sh](deploy.sh) to:
  - deploy the virtual hardware
  - prepare it to host the standlone with [standalone.yaml](standalone.yaml)
- Then SSH into the deployed node where you will find the following to run:
  - [standalone.sh](standalone.sh) with [standalone_parameters.yaml](standalone_parameters.yaml)
