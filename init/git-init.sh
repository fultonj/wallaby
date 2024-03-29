#!/usr/bin/env bash
# Clones the repos that I am interested in.
# -------------------------------------------------------
if [[ $1 == 'alias' ]]; then
    if [[ -e /home/stack/stackrc ]]; then
        echo 'source /home/stack/stackrc' >> ~/.bashrc
    fi
    echo 'alias os=openstack' >> ~/.bashrc
    echo 'alias ms=metalsmith' >> ~/.bashrc
    echo 'alias "ll=ls -lhtr"' >> ~/.bashrc
fi
# -------------------------------------------------------
if [[ $1 == 'tht' ]]; then
    declare -a repos=(
        'openstack/tripleo-heat-templates' \
        'openstack/tripleo-ansible'\
	);
fi
# -------------------------------------------------------
if [[ $# -eq 0 ]]; then
    # uncomment whatever you want
    declare -a repos=(
                      # 'openstack/tripleo-heat-templates' \
		      # 'openstack/tripleo-common'\
                      # 'openstack/tripleo-ansible' \
                      # 'openstack/tripleo-validations' \
                      # 'openstack/python-tripleoclient' \
		      # 'openstack/puppet-ceph'\
		      #'openstack/heat'\
		      # 'openstack-infra/tripleo-ci'\
		      # 'openstack/tripleo-puppet-elements'\
		      # 'openstack/tripleo-specs'\
		      # 'openstack/os-net-config'\
		      # 'openstack/tripleo-docs'\
		      # 'openstack/tripleo-quickstart'\
		      # 'openstack/tripleo-quickstart-extras'\
		      #'openstack/tripleo-repos' 
		      #'openstack/puppet-nova'\
		      #'openstack/puppet-tripleo'\
		      # add the next repo here
    );
fi
# -------------------------------------------------------
gerrit_user='fultonj'
git config --global user.email "fulton@redhat.com"
git config --global user.name "John Fulton"
git config --global push.default simple
git config --global gitreview.username $gerrit_user

git review --version
if [ $? -gt 0 ]; then
    echo "installing git-review and tox from pip"
    if [[ $(grep 8 /etc/redhat-release | wc -l) == 1 ]]; then
        if [[ ! -e /usr/bin/python3 ]]; then
            sudo dnf install python3 -y
        fi
    fi
    pip
    if [ $? -gt 0 ]; then
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python3 get-pip.py
    fi
    pip install git-review tox
fi 
pushd ~
for repo in "${repos[@]}"; do
    dir=$(echo $repo | awk 'BEGIN { FS = "/" } ; { print $2 }')
    if [ ! -d $dir ]; then
	git clone https://git.openstack.org/$repo.git
	pushd $dir
	git remote add gerrit ssh://$gerrit_user@review.openstack.org:29418/$repo.git
	git review -s
	popd
    else
	pushd $dir
	git pull --ff-only origin master
	popd
    fi
done
popd
# -------------------------------------------------------
if [[ $1 == 'link' ]]; then
    if [[ ! -e ~/templates ]]; then
        ln -v -s ~/tripleo-heat-templates ~/templates
    fi
    if [[ -d ~/tripleo-ansible ]]; then
        TARGET=/home/stack/tripleo-ansible/tripleo_ansible/roles/
        # swap out tripleo-ansible/roles/tripleo_ceph_* roles
        pushd /usr/share/ansible/roles/
        for D in tripleo_ceph_{common,run_ansible,uuid,work_dir,client}; do
            if [[ -d $D ]]; then
                sudo mv -v $D $D.dist
                sudo ln -v -s $TARGET/$D $D
            fi
        done
        for D in tripleo_{run_cephadm,cephadm}; do
            if [[ -d $D ]]; then
                sudo mv -v $D $D.dist
                sudo ln -v -s $TARGET/$D $D
            fi
        done
        popd

        # link libraries
        pushd /usr/share/ansible/plugins/modules
        sudo ln -s /home/stack/tripleo-ansible/tripleo_ansible/ansible_plugins/modules/ceph_spec_bootstrap.py
        sudo ln -s /home/stack/tripleo-ansible/tripleo_ansible/ansible_plugins/modules/ceph_fs.py
        sudo ln -s /home/stack/tripleo-ansible/tripleo_ansible/ansible_plugins/modules/ceph_dashboard_user.py
        sudo ln -s /home/stack/tripleo-ansible/tripleo_ansible/ansible_plugins/modules/ceph_mkspec.py
        popd

        pushd /usr/share/ansible/plugins/module_utils
        sudo ln -s /home/stack/tripleo-ansible/tripleo_ansible/ansible_plugins/module_utils/ceph_spec.py
        sudo ln -s /home/stack/tripleo-ansible/tripleo_ansible/ansible_plugins/module_utils/ca_common.py
        popd

        pushd /usr/share/ansible/tripleo-playbooks/
        sudo mv cephadm.yml cephadm.yml.dist
        sudo ln -s /home/stack/tripleo-ansible/tripleo_ansible/playbooks/cephadm.yml
        if [[ -e ceph-admin-user-playbook.yml ]]; then
            mv ceph-admin-user-playbook.yml ceph-admin-user-playbook.yml.dist
        fi
        sudo ln -s /home/stack/tripleo-ansible/tripleo_ansible/playbooks/ceph-admin-user-playbook.yml
        popd
    fi
fi
# -------------------------------------------------------
