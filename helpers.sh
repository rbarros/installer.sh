#!/bin/bash

{ # This ensures the entire script is downloaded

  download() {
    echo -e "|   Downloading installer-$1.sh to /tmp/installer-$1.sh\n|\n|   + $(curl_or_wget $URL/$2.sh /tmp/installer-$1.sh)"
  }

  version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

  verlte() {
      [  "$1" = "`echo -e "$1\n$2" | sort -n | head -n1`" ]
  }

  verlt() {
      [ "$1" = "$2" ] && return 1 || verlte $1 $2
  }

  counter() {
    for i in {0..10}; do
      echo -ne "$i"'\r';
      sleep 1;
      if [ "$STOP" = 1 ]; then
        break
      fi
    done; echo
  }

  comfirm() {
      text="$1 [y/N]"
      read -r -p "$text " response
      case $response in
          [yY][eE][sS]|[yY])
              true
              ;;
          *)
              false
              ;;
      esac
  }

  curl_or_wget() {
    CURL_BIN="curl"; WGET_BIN="wget"
    if command_exists ${CURL_BIN}; then
      $CURL_BIN -SL "$1" > "$2"
    elif command_exists ${WGET_BIN}; then
      $WGET_BIN -v -O- -t 2 -T 10 "$1" > "$2"
    fi
  }

  command_exists() {
    command -v "${@}" > /dev/null 2>&1
  }

  run_super() {
    if [ $(id -ru) != $ROOT_UID ]; then
      sudo "${@}"
    else
      "${@}"
    fi
  }

  super() {
    if [ "$1" = "-v" ]; then
      shift
      debug "${@}"
      run_super "${@}" > /dev/null
    elif echo "$1" | grep -P "\-v+"; then
      shift
      debug "${@}"
      run_super "${@}"
    else
      debug "${@}"
      run_super "${@}" > /dev/null 2>&1
    fi
  }

  atput() {
    [ -z "$TERM" ] && return 0
    eval "tput $@"
  }

  escape() {
    echo "$@" | sed "
      s/%{red}/$(atput setaf 1)/g;
      s/%{green}/$(atput setaf 2)/g;
      s/%{yellow}/$(atput setaf 3)/g;
      s/%{blue}/$(atput setaf 4)/g;
      s/%{magenta}/$(atput setaf 5)/g;
      s/%{cyan}/$(atput setaf 6)/g;
      s/%{white}/$(atput setaf 7)/g;
      s/%{reset}/$(atput sgr0)/g;
      s/%{[a-z]*}//g;
    "
  }

  log() {
    level="$1"; shift
    color=; stderr=; indentation=; tag=; opts=

    case "${level}" in
    debug)
      color="%{blue}"
      stderr=true
      indentation="  "
      ;;
    info)
      color="%{green}"
      ;;
    warn)
      color="%{yellow}"
      tag=" [WARN] "
      stderr=true
      ;;
    err)
      color="%{red}"
      tag=" [ERROR]"
    esac

    if [ "$1" = "-n" ]; then
      opts="-n"
      shift
    fi

    if [ "$1" = "-e" ]; then
      opts="$opts -e"
      shift
    fi

    if [ -z ${stderr} ]; then
      echo $opts "$(escape "${color}[installer]${tag}%{reset} ${indentation}$@")"
    else
      echo $opts "$(escape "${color}[installer]${tag}%{reset} ${indentation}$@")" 1>&2
    fi
  }

  step() {
    printf "$( log info $@ | sed -e :a -e 's/^.\{1,72\}$/&./;ta' )"
  }

  step_wait() {
    if [ ! -z "$@" ]; then
      STEP_WAIT="${@}"
      step "${STEP_WAIT}"
    fi
    echo "$(escape "%{blue}[ WAIT ]%{reset}")"
  }

  check_wait() {
    if [ ! -z "${STEP_WAIT}" ]; then
      step "${STEP_WAIT}"
      STEP_WAIT=
    fi
  }

  step_done() { check_wait && echo "$(escape "%{green}[ DONE ]%{reset}")"; }

  step_warn() { check_wait && echo "$(escape "%{yellow}[ FAIL ]%{reset}")"; }

  step_fail() { check_wait && echo "$(escape "%{red}[ FAIL ]%{reset}")"; }

  debug() { log debug $@; }

  info() { log info $@; }

  warn() { log warn $@; }

  err() { log err $@; }

  add_report() {
    if [ -z "$report" ]; then
      report="${@}"
    else
      report="${report}${ARRAY_SEPARATOR}${@}"
    fi
  }

  fail() {
    echo ""
    IFS="${ARRAY_SEPARATOR}"
    add_report "Failed to install installer."
    for report_message in $report; do
      err "$report_message"
    done
    exit 1
  }

  success() {
    echo ""
    IFS="${ARRAY_SEPARATOR}"
    if [ "${UPDATE}" = "true" ]; then
      add_report "installer has been successfully updated."
    else
      add_report "installer has been successfully installed."
    fi
    add_report '------------------------------------------------------------------'
    for report_message in $report; do
      info "$report_message"
    done
    exit 0
  }

} # This ensures the entire script is downloaded
