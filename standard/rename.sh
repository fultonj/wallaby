#!/bin/bash

# Do the actual change
SED=1

VERBOSE=0
CHECK=0

# In what directory should these changes be made?
TARGET=/home/stack/tripleo-ansible/tripleo_ansible/roles/tripleo_cephadm
#TARGET=/home/stack/tripleo-ansible/tripleo_ansible/roles/tripleo_run_cephadm

#TARGET=/home/stack/tripleo-heat-templates/deployment/cephadm/
# though THT will be updated, it's only ceph-base.yaml

if [[ $PWD != '/home/stack/tripleo-ansible' ]]; then
    echo 'ERROR: run this script from the correct directory.'
    echo 'cd /home/stack/tripleo-ansible'
    exit 1
fi

declare -A VAR_MAP=(
          # tripleo_cephadm
          [ceph_conf_overrides]='tripleo_cephadm_conf_overrides' \
          [ceph_config_home]='tripleo_cephadm_config_home' \
          [ceph_container_image]='tripleo_cephadm_container_image' \
          [ceph_container_ns]='tripleo_cephadm_container_ns' \
          [ceph_container_tag]='tripleo_cephadm_container_tag' \
          [ceph_keyring_permissions]='tripleo_cephadm_keyring_permissions' \
          [ceph_mode]='tripleo_cephadm_mode' \
          [ceph_spec_content]='tripleo_cephadm_spec_content' \
          [ceph_ssh_user]='tripleo_cephadm_ssh_user' \
          [ceph_uid]='tripleo_cephadm_uid' \
          [cephadm_bin]='tripleo_cephadm_bin' \
          [container_ceph_spec]='tripleo_cephadm_container_spec' \
          [container_cli]='tripleo_cephadm_container_cli' \
          [container_options]='tripleo_cephadm_container_options' \
          [mons_json]='tripleo_cephadm_mons_json' \
          [mons_list]='tripleo_cephadm_mons_list' \
          [predeployed]='tripleo_cephadm_predeployed' \
          [spec_on_bootstrap]='tripleo_cephadm_spec_on_bootstrap' \
          [tripleo_cephadm_dashboard_enabled]='tripleo_cephadm_dashboard_enabled' \
          [wait_for_mons]='tripleo_cephadm_wait_for_mons' \
          [wait_for_mons_delay]='tripleo_cephadm_wait_for_mons_delay' \
          [wait_for_mons_ignore_errors]='tripleo_cephadm_wait_for_mons_ignore_errors' \
          [wait_for_mons_retries]='tripleo_cephadm_wait_for_mons_retries' \
          # tripleo_run_cephadm
          [cephadm_playbook]='tripleo_run_cephadm_playbook' \
          [cephadm_command_list]='triple_run_cephadm_command_list' \
          [cephadm_log_path]='tripleo_run_cephadm_log_path' \
          [cephadm_std_out_err]='tripleo_run_cephadm_std_out_err' \
          [output]='triple_run_cephadm_output' \
          [verbose]='tripleo_cephadm_verbose' \
          [pools]='tripleo_cephadm_pools' \
          # The variables below fit the general "safe" substitution provided
          # they have extra key entries or are part of a special case substitution
          [cluster]='tripleo_cephadm_cluster' \
          [admin_keyring]='tripleo_cephadm_admin_keyring' \
          [fsid]='tripleo_cephadm_fsid' \
          [\(fsid]='(tripleo_cephadm_fsid' \
          [fsids]='tripleo_cephadm_fsid_list' \
          ['fsids\[0\]']='tripleo_cephadm_fsid_list\[0\]' \
          [ceph_spec_ansible_host]='tripleo_cephadm_spec_ansible_host' \
          [first_mon_ip]='tripleo_cephadm_first_mon_ip' \
          [\(first_mon_ip]='(tripleo_cephadm_first_mon_ip' \
          [num_mons_expected]='tripleo_cephadm_num_mons_expected' \
          [\(\(num_mons_expected]='((tripleo_cephadm_num_mons_expected' \
          # these run_cephadm variables also need extra help after "safe" substitution
          [bootstrap_host]='tripleo_cephadm_bootstrap_host' \
);

# Not changing these variables as they valid for tripleo_ceph_client
# [external_cluster_mon_ips]='tripleo_cephadm_external_cluster_mon_ips' \
# [tripleo_ceph_client_vars]='tripleo_cephadm_client_vars' \

# Not changing these variables as they valid for tripleo_ceph_work_dir
# [tripleo_enabled_services]='tripleo_run_cephadm_enabled_services' \


# -------------------------------------------------------
# Pattern for files which don't need to get changes
EXCLUDE_FILE="mock"

# Pattern for variables which don't need to be exluced if there
# is a substring which starts with _, e.g. foo_fsid for "fsid"
# Most likely these variables fall under the special cases.
# So these vars get the general safe substitution even if
# they look problematic to the _ test.
EXCLUDE_VAR="fsid|cluster|wait_for_mons"

pushd $TARGET
echo ""
for K in "${!VAR_MAP[@]}"; do
    #echo "## $K --> ${VAR_MAP[$K]}"
    for F in $(find . -type f | egrep -v $EXCLUDE_FILE); do
        if [[ !($K =~ $EXCLUDE_VAR) && $(grep _$K $F | wc -l) -gt 0 ]]; then
            if [ $VERBOSE == 1 ]; then
                echo "Warning: $K has the _ problem"
                echo "grep _$K $F"
                grep _$K $F
                echo ""
            fi
        else
            if [ $SED == 1 ]; then
                # these are "safe" substitutions for the general variables
                sed \
                    -e s/"{{ $K }}"/"{{ ${VAR_MAP[$K]} }}"/g \
                    -e s/"$K: "/"${VAR_MAP[$K]}: "/g \
                    -e s/" $K "/" ${VAR_MAP[$K]} "/g \
                    -e s/"$K\."/"${VAR_MAP[$K]}."/g \
                    -e s/"when: $K"/"when: ${VAR_MAP[$K]}"/g \
                    -e s/"when: not $K"/"when: not ${VAR_MAP[$K]}"/g \
                    -e s/"register: $K"/"register: ${VAR_MAP[$K]}"/g \
                    -e s/"var: $K"/"var: ${VAR_MAP[$K]}"/g \
                    -i $F
            fi
        fi
    done
    #echo ""
done
echo ""
popd

# -------------------------------------------------------
# SPECIAL CASES

if [[ $SED == 1 && \
      $TARGET == '/home/stack/tripleo-ansible/tripleo_ansible/roles/tripleo_cephadm' ]];
then
    ROOT=tripleo_ansible/roles/tripleo_cephadm
    # CLUSTER
    # 1. cluster is valid input to ceph_pool and ceph_keys module
    sed s/'tripleo_cephadm_cluster: "{{ tripleo_cephadm_cluster }}"'/'cluster: "{{ tripleo_cephadm_cluster }}"'/g -i $ROOT/tasks/keys.yaml
    sed s/'tripleo_cephadm_cluster: "{{ tripleo_cephadm_cluster }}"'/'cluster: "{{ tripleo_cephadm_cluster }}"'/g -i $ROOT/tasks/pools.yaml

    # FSID
    # 1. substitution should not have changed "^_fsid:"
    sed s/tripleo_ceph_client_tripleo_cephadm_fsid/tripleo_ceph_client_fsid/g -i $ROOT/templates/ceph_client.yaml.j2

    # 2. fsid escapes the "safe" substitution method in these cases
    sed s/"fsid|default('')"/"tripleo_ceph_client_fsid|default('')"/g -i $ROOT/molecule/default/verify.yml
    sed s/'fsid)'/'tripleo_cephadm_fsid)'/g -i $ROOT/molecule/default/verify.yml
    sed s/'== fsid'/'== tripleo_cephadm_fsid'/g -i $ROOT/molecule/default/verify.yml

    # CEPH_SPEC_ANSIBLE_HOST
    # "safe" substitution excludes automatic converation for $VAR-closing-paren
    sed s/'ceph_spec_ansible_host)'/'tripleo_cephadm_spec_ansible_host)'/g -i $ROOT/tasks/wait_for_expected_num_mons.yaml

    # BOOTSTRAP_FILES
    OLD="bootstrap_files"
    NEW="tripleo_cephadm_bootstrap_files"
    sed s/"$OLD"/"$NEW"/g -i $ROOT/defaults/main.yml
    sed s/"$OLD:"/"$NEW:"/g -i $ROOT/tasks/bootstrap.yaml
    sed s/"{{ $OLD"/"{{ $NEW"/g -i $ROOT/tasks/bootstrap.yaml
    sed s/stat_cephadm_bootstrap_files/tripleo_cephadm_bootstrap_files_stat/g -i $ROOT/tasks/bootstrap.yaml

    # CLIENT_KEYS
    OLD="client_keys"
    NEW="tripleo_cephadm_client_keys"
    for F in molecule/default/converge.yml templates/ceph_client.yaml.j2 tasks/export.yaml;
    do
        sed s/"$OLD"/"$NEW"/g -i $ROOT/$F
    done

    # KEYS
    for F in tasks/keys.yaml tasks/export.yaml; do
        sed s/" keys "/" tripleo_cephadm_keys "/g -i $ROOT/$F
    done

    # PRE_CEPH_CONF
    # [pre_ceph_conf]='tripleo_cephadm_bootstrap_conf'
    for F in molecule/default/verify.yml defaults/main.yml tasks/bootstrap.yaml tasks/pre.yaml; do
        sed s/"{{ pre_ceph_conf }}"/"{{ tripleo_cephadm_bootstrap_conf }}"/g -i $ROOT/$F
        sed s/'pre_ceph_conf:'/'tripleo_cephadm_bootstrap_conf:'/g -i $ROOT/$F
        sed s/pre_/bootstrap_/g -i $ROOT/$F
        sed s/stat_bootstrap_ceph_conf/tripleo_cephadm_bootstrap_conf_stat/g -i $ROOT/$F
    done

    # CEPH_CONF
    # First fix the missing space of the variable containing the substring
    # The generalized safe substitution missed this
    # [ceph_config_home]='tripleo_cephadm_config_home'
    # tasks/ceph_cli.yaml:      --volume {{ ceph_config_home}}:/etc/ceph:z
    #                                                       ^ missing space
    sed s/"ceph_config_home}}"/"tripleo_cephadm_config_home }}"/g -i $ROOT/tasks/ceph_cli.yaml

    # [ceph_conf]='tripleo_cephadm_conf'
    for F in molecule/default/verify.yml defaults/main.yml tasks/bootstrap.yaml tasks/ceph_cli.yaml; do
        sed s/ceph_conf/tripleo_cephadm_conf/g -i $ROOT/$F
    done

    # CEPH_SPEC
    # [ceph_spec]='tripleo_cephadm_spec'
    # Fix substrings and minor variations
    sed s/stat_ceph_spec_file_on_ansible_host/tripleo_cephadm_spec_stat_host/g -i $ROOT/tasks/pre.yaml
    for F in molecule/default/verify.yml tasks/apply_spec.yaml; do
        sed s/stat_ceph_spec_files/tripleo_cephadm_spec_files_stat/g -i $ROOT/$F
    done
    sed s/ceph_spec_apply_output/tripleo_cephadm_apply_spec_out/g -i $ROOT/tasks/apply_spec.yaml
    # do substitutions without renaming ceph_spec.yaml
    sed s/'ceph_spec:'/'tripleo_cephadm_spec:'/g -i $ROOT/defaults/main.yml

    # normal substitutions will now work
    for F in molecule/default/verify.yml tasks/apply_spec.yaml tasks/bootstrap.yaml tasks/ceph_cli.yaml tasks/pre.yaml; do
        sed s/ceph_spec/tripleo_cephadm_spec/g -i $ROOT/$F
    done

    # CEPH_CLI
    # [ceph_cli]='tripleo_cephadm_ceph_cli'
    sed s/"ceph_cli |"/"tripleo_cephadm_ceph_cli |"/g -i $ROOT/molecule/default/verify.yml

    for F in tasks/export.yaml tasks/apply_spec.yaml; do
        sed s/"{{ ceph_cli }}"/"{{ tripleo_cephadm_ceph_cli }}"/g -i $ROOT/$F
    done;

    for F in tasks/wait_for_expected_num_mons.yaml tasks/ceph_cli.yaml; do
        sed s/ceph_cli/tripleo_cephadm_ceph_cli/g -i $ROOT/$F
    done

    # missed safe substitution
    sed s/'admin_keyring)'/'tripleo_cephadm_admin_keyring)'/g -i $ROOT/molecule/default/verify.yml
    sed s/'(container_options)'/'(tripleo_cephadm_container_options)'/g -i $ROOT/molecule/default/verify.yml

    # doc change missed by "safe" substitution
    sed s/spec_on_bootstrap/tripleo_cephadm_spec_on_bootstrap/g -i doc/source/roles/role-tripleo_cephadm.rst
fi


if [[ $SED == 1 && \
      $TARGET == '/home/stack/tripleo-ansible/tripleo_ansible/roles/tripleo_run_cephadm' ]];
then
    ROOT=tripleo_ansible/roles/tripleo_run_cephadm

    # "safe" substitution misses this too
    sed s/'hostvars\[bootstrap_host\]\[tripleo_run_cephadm_net\]'/'hostvars[tripleo_cephadm_bootstrap_host][tripleo_run_cephadm_net]'/g -i $ROOT/tasks/prepare.yml
    sed s/'pools: {{ openstack_pools'/'tripleo_cephadm_pools: {{ openstack_pools'/g -i $ROOT/tasks/prepare.yml
    sed s/'keys: {{ keys.get'/'tripleo_cephadm_keys: {{ keys.get'/g -i $ROOT/tasks/prepare.yml
    sed s/'cephadm_playbook|default'/'tripleo_run_cephadm_playbook|default'/g -i $ROOT/tasks/main.yml

    sed s/'cephadm_command_list'/'triple_run_cephadm_command_list'/g -i $ROOT/tasks/main.yml

    # update the playbook outside of the roles
    # provided by the patch of the TARGET
    sed s/spec_on_bootstrap/tripleo_cephadm_spec_on_bootstrap/g -i /home/stack/tripleo-ansible/tripleo_ansible/playbooks/cephadm.yml
fi
# -------------------------------------------------------
# SEARCH FOR POSSIBLE MISSES

if [[ $CHECK == 1 ]]; then
    pushd $TARGET
    echo ""
    for K in "${!VAR_MAP[@]}"; do
        for F in $(find . -type f | egrep -v $EXCLUDE_FILE); do
            if [[ $(grep $K $F | wc -l) -gt 0 ]]; then
                echo "$F :: $K --> ${VAR_MAP[$K]} ";
                grep $K $F;
                echo "-----------";
            fi
        done
        echo "***********************************"
    done
    echo ""
    popd
fi
