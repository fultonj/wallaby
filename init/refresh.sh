#!/bin/bash

# tht 763542
# ansible 758039
# puppet 763545

declare -A REPO_MAP=(
         [763542]='tripleo-heat-templates' \
         [758039]='tripleo-ansible' \
         [763545]='puppet-tripleo' \
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
