#!/bin/bash

{ # This ensures the entire script is downloaded

  mysql_main() {
    debug "Install mysql $DISTRO $RELEASE"
    super -v+ $PACKAGE install mysql-server-5.7 mysql-client-5.7
  }

  mysql_main "${@}"

} # This ensures the entire script is downloaded
