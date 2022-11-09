#!/usr/bin/bash
#
#  Entrypoint.sh
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

cp ${APPNAME}.spec ~/rpmbuild/SPECS
echo "copy spec"
sed -i "s/0.0.0/${VERSION}/g" ~/rpmbuild/SPECS/${APPNAME}.spec
echo "config spec"
make dist-gzip
echo "dist gzip"
cp dist/${APPNAME}-${VERSION}.tar.gz ~/rpmbuild/SOURCES
echo "cp sources"
rpmbuild -bb ~/rpmbuild/SPECS/${APPNAME}.spec
echo "rpmbuild"
cp -v ~/rpmbuild/RPMS/x86_64/${APPNAME}-${VERSION}-1.el9.x86_64.rpm dist/
echo "copy rpm to mount"
rm -rf dist/${APPNAME}-${VERSION}
echo "removing folder"
