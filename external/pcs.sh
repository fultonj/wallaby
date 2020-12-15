#!/bin/bash

DNF=0
RPM=1

INV=inventory.yaml
if [[ ! -e $INV ]]; then
    echo "Fail: No inventory"
    exit 1
fi

if [[ $DNF -eq 1 ]]; then
    ansible-playbook -i $INV pcs-dnf.yml
fi

if [[ $RPM -eq 1 ]]; then
    if [[ ! -d ~/rpms ]]; then
        mkdir ~/rpms
        URL1=https://vault.centos.org/8.2.2004/HighAvailability/x86_64/os/Packages/
        A=pacemaker-2.0.3-5.el8_2.1.x86_64.rpm
        B=pacemaker-cli-2.0.3-5.el8_2.1.x86_64.rpm
        C=pacemaker-remote-2.0.3-5.el8_2.1.x86_64.rpm

        URL2=https://vault.centos.org/8.2.2004/AppStream/x86_64/os/Packages/
        D=pacemaker-cluster-libs-2.0.3-5.el8_2.1.x86_64.rpm
        E=pacemaker-libs-2.0.3-5.el8_2.1.x86_64.rpm
        F=pacemaker-schemas-2.0.3-5.el8_2.1.noarch.rpm
        G=sbd-1.4.1-3.el8.x86_64.rpm

        for P in $A $B $C; do
            curl -f $URL1/$P -o ~/rpms/$P
        done
        for P in $D $E $F $G; do
            curl -f $URL2/$P -o ~/rpms/$P
        done
    fi
    ansible-playbook -i $INV pcs-rpm.yml
fi
