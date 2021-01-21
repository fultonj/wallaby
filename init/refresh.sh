#!/bin/bash

declare -A REPO_MAP=(
         [767294]='tripleo-heat-templates' \
         [771034]='tripleo-ansible' \
        );

for K in "${!REPO_MAP[@]}"; do
    pushd ~/${REPO_MAP[$K]}
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    git reset --hard
    git checkout master
    git branch -D $BRANCH
    git review -d $K
    git branch
    popd
done
