#!/bin/bash

{ # This ensures the entire script is downloaded

  php_main() {
    debug "Install php $DISTRO $RELEASE"
    super -v+ $PACKAGE $PACKAGE_INSTALL php5.6 php5.6-dev php5.6-mcrypt php5.6-common php5.6-curl php5.6-cli php5.6-gd php5.6-json php5.6-xml libapache2-mod-php5.6 php5.6-zip php5.6-mysql php-pear build-essential
    super -v+ a2enmod rewrite
    super -v+ service apache2 restart
  }

  php_main "${@}"

} # This ensures the entire script is downloaded
