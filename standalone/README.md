# Standalone on Metalsmith

[tripleo-lab supports standalone](https://github.com/cjeanner/tripleo-lab/blob/master/environments/standalone.yaml) by
deploying one VM which is the undercloud.

I prefer to keep my undercloud running for a few weeks before I
rebuild it and use metalsmith to provision disposable VMs for me to
reprovision daily. Thus, this directory contains a few scripts I use
to provision one VM with metalsmith which I then run the standalone
tools.









