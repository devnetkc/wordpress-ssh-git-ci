#!/bin/bash

# WordPress SSH Git CI Script
# v1.2.1

# Set argument parameters on start
BRANCH=live
DEVBRANCH=dev
STAGEBRANCH=stage
PROJDIR=wordpress
ERRORMESSAGES=""
TRACKEDONLY="false"
COMMIT="true"
SOFTERROR="false"
FETCH="false"
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
            if [[ $2 == "no" ||  $2 == "n" ]] ; then
                COMMIT="false"
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
        -fe|--fetch) #optional
            FETCH="true"
            shift
            ;;
        -fo|--fullorigin) #optional
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
        -pd|--projectdir) #optional
            if [[ $2 ]]; then
                PROJDIR=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-p | --projectdir' requires a non-empty option argument."
            fi
            ;;
        -sb|--stagebranch) #optional
            if [[ $2 ]]; then
                STAGEBRANCH=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-s | --stagebranch' requires a non-empty option argument."
            fi
            ;;
        -se|--softerror) #optional
            SOFTERROR="true"
            shift
            ;;
        -to|--token) #semi-optional -- if empty ORIGIN string is required
            if [[ $2 ]]; then
                TOKEN=$2
                shift
            else
                ERRORMESSAGES="ERROR: '-t | --token' requires a non-empty option argument."
            fi
            ;;
        -tr|--tracked) #optional
            TRACKEDONLY="true"
            shift
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
    git remote add devops "$ORIGIN"
    git remote update devops 2>&1
    print_status_msg "Remote devops addded"
}

rm_devops_remote() {
    git remote rm devops
    print_status_msg "Remote devops removed"
}

add_or_remove_devops() {
    output=$(git remote )
    case $output in
        *devops*)
            print_warning_msg "Remote DevOps found"
            remoteAdded="true"
            ;;
        *)
            print_warning_msg "Remote DevOps not found"
            remoteAdded="false"
            ;;
    esac
    case $1 in
        add)
            if [[ $remoteAdded == "false" ]] ; then
                add_devops_remote
            fi
            ;;
        rm) 
             if [[ $remoteAdded == "true" ]] ; then
                rm_devops_remote
            fi
            ;;
    esac
}

# Handling changes on WordPress server

## Branches

checkout_branch() {
    if [[ "$3" ]] ; then
        git checkout -B "$DEVBRANCH" "devops/$DEVBRANCH" 2>&1
        return
    fi
    if [[ -z "$2" ]] ; then
        git checkout "$1" 2>&1
    else
        git checkout devops "$2" 2>&1
    fi
}

rm_branch() {
    git branch -D "$1" 2>&1
}

go_live() {
    git checkout -B "$BRANCH" 2>&1
    if [[ $1 ]] ; then
        rm_branch "$1"
    fi
}
## Stashes

is_stashes() {
    output=$(git stash list )
    case $1 in
        check) stashes="false";;
    esac
    case $output in
        *"stash"*)
            stashes="true";;
    esac
}

git_stash() {
    is_stashes "check"
    if [[ $stashes == "true" ]] ; then
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
    if [[ $COMMIT == "true" ]] ; then
        checkout_branch "devops" "$DEVBRANCH" "true"
        git add -A . 2>&1
        git commit -a -m "$MESSAGE"
        print_status_msg "Commited on $DEVBRANCH with message:
        $MESSAGE"
    else 
        print_status_msg "$BRANCH changes were not commited"
    fi
}

## Pull branch from remote

pull_branch() {
    msg="Pull branch "
    if [[ $2 ]] ; then
        output=$(git pull "$1/$2")
        msg=$msg$2
    else
        git pull devops "$1" 2>&1
        msg=$msg$1
    fi
    print_status_msg "$msg is complete."
}

## Push branch to remote


push_branch() {
    msg="Push branch "
    if [[ -z "$2" ]] ; then
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
    if [[ ${#ERRORMESSAGES} -gt 0 ]] ; then
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
    if [[ -z $ORIGIN ]] ; then
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
    if [[ $TRACKEDONLY == "true" ]] ; then
        output=$(git status --untracked-files=no --porcelain)
    else
        output=$(git status --porcelain)
    fi
        
    if [[ -z $output ]] ; then
        DIRTYBRANCH="false"
    else
        if [[ $ONCHANGE = "Stop" || $ONCHANGE = "stop" ]] ; then
            error3
        else
            if [[ -n $ONCHANGE ]] && [[ $ONCHANGE != "commit" && $ONCHANGE != "Commit" ]]; then
                print_error_msg '-o or --onchange has an incorrect value.  Please use commit or stop for your selection.  If you leave it blank, commit is the default.'
                error3
            else
                ONCHANGE="commit"
                DIRTYBRANCH="true"
            fi
        fi
    fi
}

# Method models

dev_branch_push() {
    output=$(git symbolic-ref --short HEAD )
    case $output in
        *"dev"*)
            push_branch "devops" "$DEVBRANCH";;
    esac
}

get_new_release() {
    # Make sure it's not missing a push back
    dev_branch_push
    
    if [[ $FETCH == "true" ]]; then
        return;
    fi
    print_status_msg "Getting latest release now"

    # Check if branch is on dev branch
    # If so, exit 
    # Checkout staging release branch
    checkout_branch "$STAGEBRANCH"

    # Pull new release changes
    pull_branch "$STAGEBRANCH"

    # Checkout a live branch, based on the staging release branch
    go_live
}

clean_repository() {
    # Stash changes
    print_status_msg "Stashing changes"
    git_stash "clear"
    git_stash "u"

    # Get latest release from Azure DevOps
    get_new_release
    
    # Add changes back
    print_status_msg "Finished updating, adding changes back"

    # Switching to dev branch to add changes
    checkout_branch "devops" "$DEVBRANCH" "true"
    pull_branch "$STAGEBRANCH"
    # Pop changes back in
    git_stash "pop"

    # If soft error isn't enabled, add files and commit them
    if [[ $SOFTERROR == "false" ]] ; then
        commit_git
        # Push changes back to dev branch
        push_branch "devops" "$DEVBRANCH"
    else
        print_error_msg "Changes on server, soft error selected. Release is pulled, changes are popped back, branch is waiting user intervention."
        error3
    fi

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

if [[ $DIRTYBRANCH == "false" ]] ; then
    # Working directory clean
    print_status_msg "Working directory clean"
    get_new_release
else 
    print_warning_msg "Uncommitted changes! Starting to clean..."
    clean_repository
fi

add_or_remove_devops "rm"