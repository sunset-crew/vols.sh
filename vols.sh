#!/bin/bash
#
# Docker External Volume Manager (DEVM)
#

set -Eeuo pipefail

# cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1

trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: $(basename "$0") [-h] {up down} [-f] -v <addition> -v <volumes> ...

This is a simple docker volume management script

    up   - Creates the directories and docker volumes
    down - Removes the docker volumes
           with the -f can also delete the folders

Available options:

-h, --help      Print this help and exit
-f, --force     This is for the down option

EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOCOLOR='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOCOLOR='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

check_args() {
    if [ "${#@}" -lt 1 ];
        then
        usage
    fi
}

check_args $@

vol_names=()

action=""

force=0

append_vol_names(){
    vol_names+=("$1")
    echo $1
}

parse_params(){
    action=${1}
    shift
    while getopts "v:hf" opt; do
        case $opt in
            h) usage;;
            v) append_vol_names "$OPTARG";;
            f) force=1;;
            :) echo "$OPTARG";;
            *) break;;
        esac
    done
    shift $((OPTIND -1))
}


parse_params "$@"
setup_colors


file_volume_load(){
    filepath="$(pwd)/vol.conf"
    if [ -f "$filepath" ];
    then 
        echo "found config file, $filepath"
        while read line;
        do
            vol_names+=("$line")
        done < "$filepath"
    fi
}

file_volume_load

create_vol() {
    directory="$(pwd)/$1"
    docker volume create --driver local \
        --opt type=none \
        --opt device=${directory} \
        --opt o=bind $1
}

up() {
    for name in ${vol_names[@]}; 
    do  
        local_dir="$(pwd)/$name"
        if [ ! -d "$local_dir" ]; then 
            mkdir $local_dir 
        fi
        echo "creating $name"
        create_vol $name
    done
}

down(){
    for name in ${vol_names[@]}; 
    do  
        echo "removing $name" 
        local_dir="$(pwd)/$name"
        if [ -d "$local_dir" ] && [[ $force -eq 1 ]]; then 
            echo "removing $local_dir"
            sudo rm -rf $local_dir
        fi
        docker volume rm $name || echo "Doesn't Exist"
    done
}

main() {
    possible_actions=("up" "down")
    main_index="-1"
    
    for i in "${!possible_actions[@]}";
    do
        p_index="$i"
        if [ "${possible_actions[${i}]}" == "$action" ];
        then
            main_index=$(echo $action);break
        fi
    done
    #~  
    if [ $main_index == "$action" ];
    then
        ${action}  
    else
        msg "${RED}${action} doesnt exist${NOCOLOR}"
        usage
    fi
}

main
