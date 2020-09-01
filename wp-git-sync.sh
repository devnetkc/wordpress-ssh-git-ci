#!/bin/bash

# WordPress SSH Git CI Script
# v1.1.0

# Set argument parameters on start
BRANCH=live
DEVBRANCH=dev
STAGEBRANCH=stage
PROJDIR=wordpress
SOFTERROR=0
ERRORMESSAGES=""
while :; do
    case "$1" in

        -b|--branch) #optional
            if [[ $2 ]]; then
                BRANCH=$2 
                shift
            else
                ERRORMESSAGES="${ERRORMESSAGES} ERROR: '-b | --branch' requires a non-empty option argument."
            fi
            ;;
        -c|--commit) #optional -- default value is true
            if [[ $2 ]] && [[ $2 = "no" ||  $2 = "n" ]] ; then
                COMMIT=0
                shift
            else
                COMMIT=1
                shift
            fi
            ;;            
        -d|--devbranch) #optional
            if [[ $2 ]]; then
                DEVBRANCH=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-d | --devbranch' requires a non-empty option argument."
            fi
            ;;
        -f|--fullorigin) #optional
            if [[ $2 ]]; then
                ORIGIN=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-f | --fullorigin' requires a non-empty option argument."
            fi
            ;;
        -g|--gitrepo) #semi-optional -- if empty ORIGIN string is required
            if [[ $2 ]]; then
                GITREPO=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-g | --gitrepo' requires a non-empty option argument."
            fi
            ;;
        -m|--message) #optional
            if [[ $2 ]]; then
                MESSAGE=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-m | --message' requires a non-empty option argument."
            fi
            ;;
        -o|--onchange) #optional
            if [[ $2 ]]; then
                ONCHANGE=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-o | --onchange' requires a non-empty option argument."
            fi
            ;;
        -p|--projectdir) #optional
            if [[ $2 ]]; then
                PROJDIR=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-p | --projectdir' requires a non-empty option argument."
            fi
            ;;
        -s|--stagebranch) #optional
            if [[ $2 ]]; then
                STAGEBRANCH=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-s | --stagebranch' requires a non-empty option argument."
            fi
            ;;
        -se|--softerror) #optional
            SOFTERROR=1
            shift
            ;;
        -t|--token) #semi-optional -- if empty ORIGIN string is required
            if [[ $2 ]]; then
                TOKEN=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-t | --token' requires a non-empty option argument."
            fi
            ;;
        -u|--tokenuser) #semi-optional -- if empty ORIGIN string is required
            if [[ $2 ]]; then
                TOKENUSER=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-u | --tokenuser' requires a non-empty option argument."
            fi
            ;;
        --)
            shift
            break
            ;;
        *)
        break
    esac
    shift
done

# Remote connection methods

add_devops_remote() {
    git remote add devops "$ORIGIN" 2>&1
    git remote update 2>&1
    git remote -v 2>&1
    print_status_msg "Remote devops addded"
}

rm_devops_remote() {
    git remote rm devops 2>&1
    git remote -v 2>&1
    print_status_msg "Remote devops removed"
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

## Branches

checkout_branch() {
    if [ -z "$2" ] ; then
        git checkout "$1" 2>&1
    else
        git checkout devops "$2" 2>&1
    fi
}

rm_branch() {
    git branch -D "$1"
}

## Stashes

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
    if [[ $stashes -eq 1 ]] ; then
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

## Committing changes

commit_git() {
    if [[ $COMMIT -eq 1 ]] ; then
        git add -A . 2>&1
        git commit -m "$MESSAGE" 2>&1
        print_status_msg "Commited on $BRANCH with message:
        $MESSAGE"
    else 
        print_status_msg "$BRANCH changes were not commited"
    fi
}

## Pull branch from remote

pull_branch() {
    msg="Pull branch "
    if [ -z "$2" ] ; then
        git pull "$1" 2>&1
        msg=$msg$1
    else
        git pull devops "$2" 2>&1
        msg=$msg$2
    fi
    print_status_msg "$msg is complete."
}

## Push branch to remote


push_branch() {
    msg="Push branch "
    if [ -z "$2" ] ; then
        git push "$1" 2>&1
        msg=$msg$1
    else
        git push devops "$2" 2>&1
        msg=$msg$2
    fi
    print_status_msg "$msg is complete."
}

# Utilities

error3() {
    add_or_remove_devops "rm"
    exit 3
}

throw_errors() {
    if [ ${#ERRORMESSAGES} -gt 0 ] ; then
        for ERRORMSG in ${ERRORMESSAGES}; do
            print_error_msg "${ERRORMSG}"
        done
        error3
    fi
}

set_defaults() {
    # If error messages from defaults, list them and exit out
    throw_errors

    # Set origin url to use
    if [ -z "$ORIGIN" ] ; then
        # if origin isn't set and the other arguments needed to make an origin aren't set, throw an error!
        if [[ -z $TOKENUSER || -z $TOKEN || -z $GITREPO ]] ; then
            error3
        fi
        ORIGIN="https://${TOKENUSER}:${TOKEN}@${GITREPO}"
    fi

    # Set the default commit message
    if [[ -z $MESSAGE ]]; then
        MESSAGE="Server Side Commit
        
        This was commited from the WordPress server"
    fi

    # Set if branch has changes; and if so, how to handle those changes
    if output=$(git status --untracked-files=no --porcelain) && [ -z "$output" ] ; then
        DIRTYBRANCH=0
    else
        if [[ $ONCHANGE = "Stop" || $ONCHANGE = "stop" ]] ; then
            error3
        else
            if [[ -n $ONCHANGE ]] && [[ $ONCHANGE != "commit" && $ONCHANGE != "Commit" ]]; then
                print_error_msg '-o or --onchange has an incorrect value.  Please use commit or stop for your selection.  If you leave it blank, commit is the default.'
                error3
            else
                ONCHANGE="commit"
                DIRTYBRANCH=1
            fi
        fi
    fi
}

# Method models

get_new_release() {
    # Checkout staging release branch
    checkout_branch "$STAGEBRANCH"

    # Pull new release changes
    pull_branch "devops" "$STAGEBRANCH"

    # Remove the previous live branch
    rm_branch "$BRANCH"

    # Re-create and checkout a live branch, based on the staging release branch
    git branch "$BRANCH" 2>&1
    checkout_branch "$BRANCH"

}


clean_repository() {
    # Stash changes
    git_stash "clear"
    git_stash "u"

    # Get latest release from Azure DevOps
    get_new_release

    # Add changes back
    git_stash "pop"

    # If soft error isn't enabled, add files and commit them
    if [ $SOFTERROR -eq 0 ] ; then
        commit_git
    else
        print_error_msg "Changes on server, soft error selected. Release is pulled, changes are popped back, branch is waiting user intervention."
        error3
    fi

    # Push changes back to dev branch
    push_branch "devops" "$DEVBRANCH"

    print_status_msg "Changes on the WordPress site have been commited, and were pushed to $DEVBRANCH branch"
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

cd "$PROJDIR" || exit 1
set_defaults

add_or_remove_devops "add"

# Option selected to just query for changes

if [ $DIRTYBRANCH -eq 0 ] ; then
  # Working directory clean
  print_status_msg "Working directory clean"
  get_new_release
else 
    print_warning_msg "Uncommitted changes! Starting to clean..."
    clean_repository
fi

add_or_remove_devops "rm"