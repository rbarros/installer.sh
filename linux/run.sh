#!/bin/bash

{ # This ensures the entire script is downloaded

  ##
  # A main method installer plataform
  ##
  run() {
    check_distro
  }

  ##
  # Check a distro
  ##
  check_distro() {
    step "Checking distro platform"

    if [[ -e /etc/os-release ]]; then
      # Detecting DISTRO and RELEASE
      . /etc/os-release
      DISTRO=$ID
      RELEASE=$VERSION_ID
    fi

    # Docker containers
    if [[ -e /etc/lsb-release ]]; then
      # Detecting DISTRO and RELEASE
      . /etc/lsb-release
      DISTRO=$( echo $DISTRIB_ID | awk '{print tolower($0)}')
      RELEASE=$DISTRIB_RELEASE
    fi

    if [[ -e /etc/redhat-release ]]; then
      RELEASE_RPM=$(rpm -qf /etc/redhat-release)
      RELEASE=$(rpm -q --qf '%{VERSION}' ${RELEASE_RPM})
      case ${RELEASE_RPM} in
        centos*)
          DISTRO="centos"
          ;;
        redhat*)
          DISTRO="redhat"
          ;;
        *)
          echo "unknown EL clone"
          exit 1
          ;;
      esac
    fi

    step_done
    debug "Detected distribution: $DISTRO, $RELEASE"

    # Download script a distro
    if [ ! -f /tmp/installer-$DISTRO.sh ]; then
      download "$DISTRO" "$PLATFORM/$DISTRO/$DISTRO"
    fi

    if [ -f /tmp/installer-$DISTRO.sh ]; then
        . /tmp/installer-$DISTRO.sh
        $DISTRO_main
    else
        # Show error
        echo -e "|\n|   Error: The script $DISTRO could not be downloaded\n|"
    fi
  }

  check_gcc() {
    step "Verifying that gcc is installed"
    step_done
    if command_exists gcc; then
      debug "gcc is installed, skipping gcc installation."
      debug $(gcc --version)
    else
      install_gcc
    fi
  }

  install_gcc() {
    debug "Installing gcc"
    super -v+ ${PACKAGE_YES} ${PACKAGE_INSTALL} gcc
  }

  check_grep() {
    step "Verifying that grep is installed"
    step_done
    if command_exists grep; then
      debug "grep is installed, skipping grep installation."
      debug $(grep --version)
    else
      install_grep
    fi
  }

  install_grep() {
    debug "Installing grep"
    super -v+ ${PACKAGE_YES} ${PACKAGE_INSTALL} grep
  }

  install_jq() {
    step "Verifying that jq is installed"
    step_done
    if command_exists jq; then
      debug "jq is installed, skipping jq installation."
      debug $(jq --version)
    else
      debug "Installing jq"
      super -v+ ${PACKAGE_YES} ${PACKAGE_INSTALL} jq
    fi
  }

  check_sed() {
    step "Verifying that sed is installed"
    step_done
    if command_exists sed; then
      debug "sed already installed"
    else
      install_sed
    fi
  }

  install_sed() {
    debug "Installing sed"
    super ${PACKAGE_YES} ${PACKAGE_INSTALL} sed
  }

} # This ensures the entire script is downloaded
