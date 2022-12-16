#!/bin/bash
#
# Docker External Volume Manager (DEVM)
#

set -Eeuo pipefail


declare -A mntpoints
# cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1

trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: $(basename "$0") [-h] {up new down} [-f] -v <addition> -v <volumes> ...

This is a simple docker volume management script

    up     - Creates the directories and docker volumes
    new    - Creates Demo vols.conf file
    down   - Removes the docker volumes
             'f' can also deletes the folders

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
curr=$(pwd)
vol_file="${curr}/vols.conf"
action=""

force=0

append_mntpoints(){
    mntpoints[$1]=$2
    echo "$1 $2"
}

getopts-extra () {
    declare i=1
    # if the next argument is not an option, then append it to array OPTARG
    while [[ ${OPTIND} -le $# && ${!OPTIND:0:1} != '-' ]]; do
        OPTARG[i]=${!OPTIND}
        let i++ OPTIND++
    done
}

parse_params(){
    action=${1}
    shift
    while getopts "v:i:hf" opt; do
        case $opt in
            h) usage;;
            v) getopts-extra $@
               args=("${OPTARG[@]}")
               mntpoint=""
               name=${args[0]}
               if [[ ${#args[@]} == 1 ]]; then
                   mntpoint="$name"
               else
                   mntpoint="${args[1]}"
               fi
               echo "$name $mntpoint"
               append_mntpoints $name $mntpoint
            ;;
            i) vol_file="$OPTARG"
                echo "$vol_file"
            ;;
            f) force=1;;
            :) echo "$OPTARG";;
            *) break;;
        esac
    done
    shift $((OPTIND -1))
}

parse_params "$@"
setup_colors

file_volume_load() {
    if [ -f "$vol_file" ];
    then 
        echo "found config file, $vol_file"
        while read -r name mntpoint
        do
          grep -q "^[^#;]" <<<$name || continue
          mntpoint=$(echo "$mntpoint" | sed 's|\(.*\)\# .*$|\1|' | cut -d' ' -f1)
          if [ -z "$mntpoint" ]; then
            mntpoint=$(pwd)/$name
          fi
          mntpoints[$name]=$mntpoint
          echo "name: $name  mountpoint: $mntpoint"

        done < "$vol_file"
    else
        echo "$vol_file does not exist"
    fi
}

file_volume_load

create_vol() {
    if [ ! -d "$2" ]; then
        die "system side of the mount point\n directory\mdoes not exists"
    fi
    docker volume create --driver local \
        --opt type=none \
        --opt device=$2 \
        --opt o=bind $1
}

up() {
    for key in ${!mntpoints[@]};
    do  
        mntpoint=${mntpoints[$key]}
        if [ ! -d "$mntpoint" ]; then
            mkdir $mntpoint
            echo "mkdir $mntpoint"
        fi
        echo "creating $key $mntpoint"
        create_vol $key $mntpoint
    done
}

new() {
    [ -f "$vol_file" ] && die "vols.conf already exists"
    echo "adding example vols.conf"
    cat <<EOT >  $vol_file
# nameofmount /the/mount/location
EOT
}

down() {
    for key in ${!mntpoints[@]};
    do
        mntpoint=${mntpoints[$key]}
        if [ -d "$mntpoint" ] && [[ $force -eq 1 ]]; then
            echo "sudo rm -rf $mntpoint"
            sudo rm -rf $mntpoint
        else
            echo "force not selected, leaving real mount point alone"
        fi
        echo "creating $key $mntpoint"
        docker volume rm $key || echo "Doesn't Exist"
    done
}

main() {
    possible_actions=("up" "down" "new")
    main_index="-1"    
    for i in "${!possible_actions[@]}";
    do
        p_index="$i"
        if [ "${possible_actions[${i}]}" == "$action" ];
        then
            main_index=$(echo $action);break
        fi
    done
    if [ $main_index == "$action" ];
    then
        ${action}  
    else
        msg "${RED}${action} doesnt exist${NOCOLOR}"
        usage
    fi
}

main
