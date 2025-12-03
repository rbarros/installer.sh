#!/bin/bash

{ # This ensures the entire script is downloaded

  php_main() {
    debug "Install php $DISTRO $RELEASE"
    super -v+ $PACKAGE $PACKAGE_INSTALL php8.3 php8.3-dev php8.3-mbstring php8.3-common php8.3-curl php8.3-cli php8.3-gd php8.3-json php8.3-xml libapache2-mod-php8.3 zip unzip php8-zip php8.3-mysql php8.3-bcmath php-pear build-essential #build-dep
    super -v+ a2enmod rewrite
    super -v+ service apache2 restart
  }

  php_main "${@}"

} # This ensures the entire script is downloaded
