#!/bin/bash

{ # This ensures the entire script is downloaded

  php_main() {
    debug "Install php $DISTRO $RELEASE"
    super -v+ $PACKAGE $PACKAGE_INSTALL php8 php8-dev php8-mbstring php8-common php8-curl php8-cli php8-gd php8-json php8-xml libapache2-mod-php8 zip unzip php8-zip php8-mysql php8-bcmath php-pear build-essential #build-dep
    super -v+ a2enmod rewrite
    super -v+ service apache2 restart
  }

  php_main "${@}"

} # This ensures the entire script is downloaded
