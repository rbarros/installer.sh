#!/bin/bash

{ # This ensures the entire script is downloaded

  php_main() {
    debug "Install php $DISTRO $RELEASE"
    super -v+ $PACKAGE $PACKAGE_INSTALL php5 php5-dev php5-mcrypt php5-common php5-curl php5-cli php5-gd php5-json php5-xml libapache2-mod-php5 php5-zip php5-mysql php-pear build-essential
    super -v+ a2enmod rewrite
    super -v+ service apache2 restart
  }

  php_main "${@}"

} # This ensures the entire script is downloaded
