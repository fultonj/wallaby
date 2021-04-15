#!/bin/bash

POD=1
REPO=1
CEPH=1
INSTALL=1
CONTAINERS=1
CEPH_PREP=1
HOSTNAME=1
EXTRAS=1
TMATE=1

if [[ $POD -eq 1 ]]; then
    sudo dnf module enable -y container-tools:3.0
    sudo dnf install -y podman 
fi

if [[ $REPO -eq 1 ]]; then
    if [[ ! -d ~/rpms ]]; then mkdir ~/rpms; fi
    url=https://trunk.rdoproject.org/centos8/component/tripleo/current/
    rpm_name=$(curl $url | grep python3-tripleo-repos | sed -e 's/<[^>]*>//g' | awk 'BEGIN { FS = ".rpm" } ; { print $1 }')
    rpm=$rpm_name.rpm
    curl -f $url/$rpm -o ~/rpms/$rpm
    if [[ -f ~/rpms/$rpm ]]; then
	sudo yum install -y ~/rpms/$rpm
	sudo -E tripleo-repos current-tripleo-dev ceph --stream
	sudo yum repolist
	sudo yum update -y
    else
	echo "$rpm is missing. Aborting."
	exit 1
    fi
fi

if [[ $CEPH -eq 1 ]]; then
    sudo dnf install -y cephadm ceph-ansible util-linux lvm2
    CEPHADMSRC=1
    if [[ $CEPHADMSRC -eq 1 ]]; then
        CEPHADM_PATH=/usr/sbin/cephadm
        CEPHADM_SRC=https://raw.githubusercontent.com/ceph/ceph/pacific/src/cephadm/cephadm
        md5sum $CEPHADM_PATH
        curl --remote-name --location --insecure $CEPHADM_SRC -o cephadm
        sudo mv cephadm $CEPHADM_PATH
        md5sum $CEPHADM_PATH
    fi
fi

if [[ $INSTALL -eq 1 ]]; then
    sudo yum install -y python3-tripleoclient
fi

if [[ $CONTAINERS -eq 1 ]]; then
    openstack tripleo container image prepare default \
      --output-env-file $HOME/containers-prepare-parameters.yaml
fi

if [[ $CEPH_PREP -eq 1 ]]; then
    for pkg in util-linux lvm2; do
        rpm -q $pkg > /dev/null
        if [[ $? -ne 0 ]]; then
            echo "failure: please yum install $pkg"
            exit 1
        fi
    done
    i=0
    for LV in /dev/vg2/db-lv2 /dev/vg2/data-lv2; do
        if [[ -e $LV ]]; then
            i=$(($i+1 ))
        fi
    done
    if [[ $i -eq 2 ]]; then
        echo "It looks like you already have the Ceph disks you need."
    fi
    if [[ $i -eq 0 ]]; then
        sudo dd if=/dev/zero of=/var/lib/ceph-osd.img bs=1 count=0 seek=7G
        sudo losetup /dev/loop3 /var/lib/ceph-osd.img
        sudo lsblk
        sudo pvcreate /dev/loop3
        sudo vgcreate vg2 /dev/loop3
        sudo lvcreate -n data-lv2 -l 1194 vg2
        sudo lvcreate -n db-lv2 -l 597 vg2
        sudo lvs
    else
        echo "The disks are not configured as expected."
        echo "Try running cleanup.sh and then re-run $0"
    fi
    cat <<EOF > /tmp/ceph-osd-losetup.service
[Unit]
Description=Ceph OSD losetup
After=syslog.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/sbin/losetup /dev/loop3 || \
/sbin/losetup /dev/loop3 /var/lib/ceph-osd.img ; partprobe /dev/loop3'
ExecStop=/sbin/losetup -d /dev/loop3
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    sudo mv /tmp/ceph-osd-losetup.service /etc/systemd/system/
    sudo systemctl enable ceph-osd-losetup.service
fi

if [[ $HOSTNAME -eq 1 ]]; then
    sudo setenforce 0
    sudo hostnamectl set-hostname standalone.localdomain
    sudo hostnamectl set-hostname standalone.localdomain --transient
    sudo setenforce 1
fi

if [[ $EXTRAS -eq 1 ]]; then
    sudo dnf install -y tmux emacs-nox vim
fi

if [[ $TMATE -eq 1 ]]; then
    TMATE_RELEASE=2.4.0
    curl -OL https://github.com/tmate-io/tmate/releases/download/$TMATE_RELEASE/tmate-$TMATE_RELEASE-static-linux-amd64.tar.xz
    sudo mv tmate-$TMATE_RELEASE-static-linux-amd64.tar.xz /usr/src/
    pushd /usr/src/
    sudo tar xf tmate-$TMATE_RELEASE-static-linux-amd64.tar.xz
    sudo mv /usr/src/tmate-$TMATE_RELEASE-static-linux-amd64/tmate /usr/local/bin/tmate
    sudo chmod 755 /usr/local/bin/tmate
    popd
fi
