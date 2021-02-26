#!/bin/bash

declare -A REPO_MAP=(
                     [767294]='tripleo-heat-templates' \
                     [777586]='tripleo-ansible' \
                     [773364]='tripleo-ansible' \
                    );

for K in "${!REPO_MAP[@]}"; do
    pushd ~/${REPO_MAP[$K]}
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    git reset --hard
    git checkout master
    #git branch -D $BRANCH
    git review -d $K
    git branch
    if [[ $K == "777586" ]]; then
        OLDBRANCH=$(git branch --show-current)
        git branch -M $OLDBRANCH mkspec
    fi
    popd
done
