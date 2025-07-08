#!/bin/bash

# 1. Crontab example as:
#   0 0 * * * /home/user/<this_script>

# 2. It needs a "daily" branch

# 3. When in doubt, use $HOME/

# 4. There is a return section, if you need to fork it. But managing the argument is as far as it goes

# 5. I am quoting a lot of varialbes unnecessary due to trauma. Some non-booleans was just me using highlighting IDE when sleepy.


INPUT=$1
OUTPUT=""
RETURN_ME="no" #because if i ever pipe the return of that I do not want to deal with this part

SUCCESS=false
has_out=false

CURRENT_DATE=$(date +"%Y-%m-%d")

MY_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$MY_PATH")"

LOG_FILE="$SCRIPT_DIR/.PERIODIC_GIT.log"


log() {
    echo -e "$1" >> "$LOG_FILE"
}

back_home(){    #cd back to script file, if you need
    # CAREFUL with the CDs back home. it doesn't matter for the Rsync but for all th rest it might.
    cd "$SCRIPT_DIR"
}

check(){ #check if the paths exist.
    #echo "CHECKING $1"
    if [[ ! -d $1 ]]; then
        back_home
        is_out="$2"
        if [[ ! -z "$is_out" ]]; then
            log "$CURRENT_DATE: OUTPUT $is_out does not exist \n\n"
        else
            log "$CURRENT_DATE:  $1 does not exist \n\n"
        fi

        exit
    fi
}

check_branch(){
    if git branch --list "daily"; then
        return 0
    else
        log "$CURRENT_DATE:  Branch does not exist \n\n"
    fi
}

git_it(){
    git add .
    git commit -m "Daily commit: $CURRENT_DATE"
    git checkout -

    # We're not pushing it on this script, but here it is if you need it:
    # git push origin daily
}

# Optional argument check ===============================

if [[ $# -ge 2 ]]; then
    OUTPUT="$2"
    check "$OUTPUT" "output"
    has_out=true #prevents problems
fi
if [[ $# -ge 3 ]]; then
    if [[ $3 == "-y" || $3 == "--yes" ]]; then
        RETURN_ME="yes"
    fi
fi


# Input and git check ===============================

check "$INPUT"
cd "$INPUT"
echo $LOG_FILE

check_branch

git checkout daily

STATUS=$(git status -s)

if [[ -n $STATUS ]]; then
    git_it
    log "\n =============$CURRENT_DATE============= \n"
    log "\n [[FILES]] \n"   #if I ever am stupid enough to decide to automate reading that
    log "$STATUS \n"
    log "$CURRENT_DATE: [[FILES_END]] \n\n"
    log "\n ==================================== \n"
    SUCCESS=true
else
    log "$CURRENT_DATE: No changes today"
fi

# R-SYNC ===============================

if [[ $has_out && $SUCCESS ]]; then
    rsync --times --recursive --perms --exclude="node_modules" "$INPUT" "$OUTPUT"
fi

# Return Options ===============================
# Not doing any, just don't want to deal with it later

if [[ $RETURN_ME = "yes" ]]; then #if you need returns deal with them here.
    echo "1"
fi
#echo $LOG_FILE
