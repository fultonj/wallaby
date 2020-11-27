#!/bin/bash

# ansible 758039
# tht 763542
# puppet 763545

declare -a REPOS=(
         'tripleo-heat-templates' \
         'tripleo-ansible' \
         'puppet-tripleo' \
        );

for REPO in "${REPOS[@]}"; do
    pushd ~/$REPO
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    NUMBER=$(basename $BRANCH)
    git reset --hard
    git checkout master
    git branch -D $BRANCH
    git review -d $NUMBER
    git branch
    popd
done
