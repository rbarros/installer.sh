#!/bin/bash

{ # This ensures the entire script is downloaded

  php_main() {
    debug "Install php $DISTRO $RELEASE"
    super -v+ $PACKAGE $PACKAGE_INSTALL php8.1 php8.1-dev php8.1-mbstring php8.1-common php8.1-curl php8.1-cli php8.1-gd php8.1-json php8.1-xml libapache2-mod-php8.1 zip unzip php8-zip php8.1-mysql php8.1-bcmath php-pear build-essential #build-dep
    super -v+ a2enmod rewrite
    super -v+ service apache2 restart
  }

  php_main "${@}"

} # This ensures the entire script is downloaded
