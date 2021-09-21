#!/bin/bash

{ # This ensures the entire script is downloaded

  mysql_main() {
    debug "Install mysql $DISTRO $RELEASE"
    super -v+ $PACKAGE install mysql-server mysql-client
  }

  mysql_main "${@}"

} # This ensures the entire script is downloaded