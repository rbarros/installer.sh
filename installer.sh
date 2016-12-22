#!/bin/bash

{ # This ensures the entire script is downloaded

VERSION="0.1.0"
LOCAL_RAW=http://localhost/installer.sh
REMOTE_RAW=https://raw.github.com/rbarros/installer.sh/dev/
ROOT_UID=0
ARRAY_SEPARATOR="#"
OS=""
OS_VERSION=""
PLATFORM=""
ARCH=""
PROJECT=""
PACKAGE=""
UPDATE="false"
HTTPD_ROOT=""
SERVER=""

if [ "${1}" = "--local" ]; then
  URL=$LOCAL_RAW
else
  URL=$REMOTE_RAW
fi

main() {
  welcome
  download_utils
  check_plataform
  check_gcc
  check_grep
  check_webserver
  menu
  success
}

welcome() {
  GREEN="$(tput setaf 2)"
  printf '%s' "$GREEN"
  printf '%s\n' '.__                 __         .__  .__                          .__     '
  printf '%s\n' '|__| ____   _______/  |______  |  | |  |   ___________      _____|  |__  '
  printf '%s\n' '|  |/    \ /  ___/\   __\__  \ |  | |  | _/ __ \_  __ \    /  ___/  |  \ '
  printf '%s\n' '|  |   |  \\___ \  |  |  / __ \|  |_|  |_\  ___/|  | \/    \___ \|   Y  \'
  printf '%s\n' '|__|___|  /____  > |__| (____  /____/____/\___  >__|    /\/____  >___|  /'
  printf '%s\n' '        \/     \/            \/               \/        \/     \/     \/ '
  #printf '%s\n' 'Please look over the ~/.installerrc file to select plugins and options.'
  printf '%s\n'
  printf '%s\n' 'p.s. Follow us at http://github.com/rbarros/installer.sh'
  printf '%s\n' '------------------------------------------------------------------'
}

check_plataform() {
  step "Checking platform"

  # Detecting PLATFORM and ARCH
  UNAME="$(uname -a)"
  case "$UNAME" in
    Linux\ *)   PLATFORM=linux ;;
    Darwin\ *)  PLATFORM=darwin ;;
    SunOS\ *)   PLATFORM=sunos ;;
    FreeBSD\ *) PLATFORM=freebsd ;;
  esac
  case "$UNAME" in
    *x86_64*) ARCH=x64 ;;
    *i*86*)   ARCH=x86 ;;
    *armv6l*) ARCH=arm-pi ;;
  esac

  if [ -z $PLATFORM ] || [ -z $ARCH ]; then
    step_fail
    add_report "Cannot detect the current platform."
    fail
  fi

  step_done
  debug "Detected platform: $PLATFORM, $ARCH"

  if [ "$PLATFORM" = "linux" ]; then
    download_linux
  else
    warn "Sorry, we're working..."
  fi
}

download_utils() {
  echo -e "|   Downloading installer-utils.sh to /tmp/installer-utils.sh\n|\n|   + $(wget -nv -o /dev/stdout -O /tmp/installer-utils.sh --no-check-certificate $URL/utils.sh)"

  if [ -f /tmp/installer-utils.sh ]; then
      . /tmp/installer-utils.sh
  else
      # Show error
      echo -e "|\n|   Error: The utils.sh could not be downloaded\n|"
  fi
}

download_linux() {
  echo -e "|   Downloading installer-linux-run.sh to /tmp/installer-linux-run.sh\n|\n|   + $(wget -nv -o /dev/stdout -O /tmp/installer-linux-run.sh --no-check-certificate $URL/linux/run.sh)"

  if [ -f /tmp/installer-linux-run.sh ]; then
      . /tmp/installer-linux-run.sh
      check_distro
  else
      # Show error
      echo -e "|\n|   Error: The script could not be downloaded\n|"
  fi
}

main "${@}"

} # This ensures the entire script is downloaded
