#!/bin/sh

# WordPress SSH Git CI Script
# v1.0.1

# Set argument parameters on start

TOKENUSER="NONE"
TOKEN="NONE"

while getopts b:d:g:p:r:t:u: option; do
    case "${option}" in
        b) BRANCH=${OPTARG};;
        d) DEVBRANCH=${OPTARG};;
        g) GITREPO=${OPTARG};;
        p) GITPATH=${OPTARG};;
        r) RUNTYPE=${OPTARG};;
        t) TOKEN=${OPTARG};;
        u) TOKENUSER=${OPTARG};;
        *) RUNTYPE="push";;
    esac
done

# Remote connection methods

add_devops_remote() {
    git remote add devops "https://${TOKENUSER}:${TOKEN}@${GITREPO}" 2>&1
    print_status_msg "Remote devops addded"
    git remote -v 2>&1
}

rm_devops_remote() {
    git remote rm devops 2>&1
    print_status_msg "Remote devops removed"
    git remote -v 2>&1
}

add_or_remove_devops() {
    output=$(git remote )
    case $output in
        *+devops*)
            remoteAdded=1;;
        *)
            remoteAdded=0;;
    esac
    case $1 in
        add)
            if [ $remoteAdded -eq 0 ] ; then
                add_devops_remote
            fi;;
        rm) 
             if [ $remoteAdded -eq 0 ] ; then
                rm_devops_remote
            fi;;
    esac
}

# Handling changes on WordPress server

## Stashing changes

is_stashes() {
    output=$(git stash list )
    case $1 in
        check) stashes=0;;
    esac
    case $output in
        *+"stash"*)
            stashes=1;;
    esac
}

git_stash() {
    is_stashes "check"
    if [ "$stashes" -eq 1 ] ; then
        case $1 in
            clear)
                git stash clear 2>&1;;
            pop)
                git stash pop 2>&1;;
            u)
                git stash -u 2>&1;;
            *)
                git stash 2>&1;;
        esac
    fi
    return
}

## Commit changes

commit_git() {
    git add -A . 2>&1
    git commit -m "Server Side Commit

This was commited from SiteGround during release push" 2>&1
}

## Merge changes

merge_from_devops() {
    git merge "${DEVBRANCH}"  2>&1
    git branch -D "${DEVBRANCH}" 2>&1
}

# Pull from repository methods

pull_from_devops() {
    add_or_remove_devops "add"
    git_stash "clear"
    git_stash "u"
    git remote update 2>&1
    git checkout "${DEVBRANCH}" 2>&1
    git pull devops "${DEVBRANCH}" 2>&1
    git checkout "${BRANCH}" 2>&1
    git pull devops "${BRANCH}" 2>&1
    merge_from_devops
    git_stash "pop"
    commit_git
    add_or_remove_devops "rm"
    print_status_msg "pull_from_dev function was executed successfully."
}

# Push to repository methods

push_to_devops() {
    pull_from_devops
    add_or_remove_devops "add"
    git push devops "$BRANCH" 2>&1
    print_status_msg "push_to_dev function was executed successfully."
    add_or_remove_devops "rm"
}

# Utilities

set_defaults() {
    if [ -z "$GITPATH" ]; then
        print_error_msg "-p is empty. Please provide a path to git directory for repository & try again."
        exit 2
    fi
    if [ -z "$RUNTYPE" ]; then
        RUNTYPE='push'
    fi
}

clean_repository() {
    # code
    if [ -n "$TOKEN" ] || [ "$TOKEN" != "NONE" ] || [ -n "$TOKENUSER" ] || [ "$TOKENUSER" != "NONE" ]; then
        push_to_devops
        commit_git
        push_to_devops
        print_status_msg "clean_rep function was executed successfully."
    else
        print_error_msg "You need to provide a token using -t and a username for it using -u"
        exit 2
    fi
}

## Print messages in colored text

### Greeen status message usually signifying success
print_status_msg() {
    printf "\033[32m%s\n" "$1"
}

### Yellow message usually signifying a warning message of some kind
print_warning_msg() {
    printf "\033[33m%s\n" "$1"
}

### Red message idicate that there was an error an action should be taken
print_error_msg() {
    printf "\033[31m%s\n" "$1"
}

# Methods and properties set, now start script logic models

set_defaults

cd "${GITPATH}" || exit 1

if output=$(git status --untracked-files=no --porcelain) && [ -z "$output" ] && [ "$RUNTYPE" != "Clean" ] && [ "$RUNTYPE" != "clean" ] ; then
  # Working directory clean
  print_status_msg "Working directory clean"
  push_to_devops
else 
    print_warning_msg "Uncommitted changes! Starting to clean..."
    clean_repository
fi
export DEFAULT
