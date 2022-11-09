#!/bin/bash
#
# Debian Package Manager
#

set -Eeuo pipefail

trap cleanup SIGINT SIGTERM ERR EXIT

cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null

. .version

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h]

This is the entrypoint to the rpm build 

Available options:

-h, --help      Print this help and exit

EOF
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=${1}
  local code=${2-1} # default exit status 1
  msg "$msg"
  usage
  exit "$code"
}


parse_params() {
  # default values of variables set from params
  # enableproxy=0


  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    # -p | --proxy) enableproxy=1 ;;
    -?*) die "Unknown option: $1" 1 ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  # [[ ${#args[@]} -ne 4 ]] && die "Missing script arguments" 7
  return 0
}

parse_params $@


built_name=${APPNAME}_${VERSION}-1_amd64

mkdir -p dist/${built_name}
mkdir -p dist/${built_name}/usr/local/bin
cp vols.sh dist/${built_name}/usr/local/bin
mkdir dist/${built_name}/DEBIAN
touch dist/${built_name}/DEBIAN/control
cat <<EOT > dist/${built_name}/DEBIAN/control
Package: ${APPNAME}
Version: ${VERSION}
Architecture: amd64
Maintainer: Joe Siwiak <joe@unherd.info>
Description: A program that helps you out with Docker External Volumes.
 It creates vos.conf files, 
EOT
cd dist
dpkg-deb --build --root-owner-group ${built_name}
rm -rf ${built_name}
# dpkg-deb --build helloworld 
