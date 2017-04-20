#!/bin/bash

{ # This ensures the entire script is downloaded

  PACKAGE="pacman"
  PACKAGE_YES="pacman -S"
  PACKAGE_INSTALL=""

  arch_main() {
    update_plataform
    check_gcc
    check_grep
    menu
  }

  update_plataform() {
    STOP=0
    trap abort_update INT

    debug "Will be update within 10 seconds."
    debug "To prevent its update, just press CTRL+C now."
    counter

    if [ "$STOP" = 0 ]; then
      step_wait "Update $DISTRO, $RELEASE ..."
      if update_distro; then
        step_done
      fi
    fi

    trap - INT
  }

  abort_update() {
    STOP=1
    echo ""
    warn "installer needs to be update."
  }

  update_distro() {
    super -v+ ${PACKAGE} -Syu
  }

  menu() {
    warn "Sorry, we're working..."
  }

  arch_main "${@}"

} # This ensures the entire script is downloaded
