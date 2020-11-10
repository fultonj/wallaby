#!/usr/bin/env bash
# Clones the repos that I am interested in.
# -------------------------------------------------------
if [[ $1 == 'poc' ]]; then
    pushd ~
    git clone git@github.com:fmount/tripleo-ceph.git
    popd
fi
# -------------------------------------------------------
if [[ $1 == 'alias' ]]; then
    if [[ -e /home/stack/stackrc ]]; then
        echo 'source /home/stack/stackrc' >> ~/.bashrc
    fi
    echo 'alias os=openstack' >> ~/.bashrc
    echo 'alias ms=metalsmith' >> ~/.bashrc
    echo 'alias "ll=ls -lhtr"' >> ~/.bashrc
    echo 'alias ans="cd /home/stack/tripleo-ceph"' >> ~/.bashrc
    echo 'alias poc="cd /home/stack/victoria/poc"' >> ~/.bashrc
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
    echo "installing git-review from upstream"
    dir=/tmp/$(date | md5sum | awk {'print $1'})
    mkdir $dir
    pushd $dir
    if [[ $(grep 7 /etc/redhat-release | wc -l) == 1 ]]; then
        curl http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/g/git-review-1.24-5.el7.noarch.rpm > git-review-1.24-5.el7.noarch.rpm
        sudo yum localinstall git-review-1.24-5.el7.noarch.rpm -y
    fi
    if [[ $(grep 8 /etc/redhat-release | wc -l) == 1 ]]; then
        if [[ ! -e /usr/bin/python3 ]]; then
            sudo dnf install python3 -y
        fi
        curl http://people.redhat.com/~iwienand/1564233/git-review-1.26.0-1.fc28.noarch.rpm > git-review-1.26.0-1.fc28.noarch.rpm
        sudo dnf install -y git-review-1.26.0-1.fc28.noarch.rpm
    fi
    popd 
    rm -rf $dir
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
if [[ $1 == 'tht' ]]; then
    if [[ ! -e ~/templates ]]; then
        ln -v -s ~/tripleo-heat-templates ~/templates
    fi
    if [[ -d ~/tripleo-ansible ]]; then
        TARGET=/home/stack/tripleo-ansible/tripleo_ansible/roles/
        # swap out tripleo-ansible/roles/tripleo_ceph_* roles
        pushd /usr/share/ansible/roles/
        for D in tripleo_ceph_{common,run_ansible,uuid,work_dir}; do
            sudo mv -v $D $D.dist
            sudo ln -v -s $TARGET/$D $D
        done
        popd
    fi
fi
# -------------------------------------------------------
