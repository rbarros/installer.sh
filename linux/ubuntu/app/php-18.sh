#!/bin/bash

{ # This ensures the entire script is downloaded

  php_main() {
    debug "Install php $DISTRO $RELEASE"
    super -v+ $PACKAGE $PACKAGE_INSTALL php7.2 php7.2-dev php7.2-mbstring php7.2-common php7.2-curl php7.2-cli php7.2-gd php7.2-json php7.2-xml libapache2-mod-php7.2 zip unzip php7.2-zip php7.2-mysql php7.2-bcmath php-pear build-essential #build-dep
    super -v+ a2enmod rewrite
    super -v+ service apache2 restart
  }

  php_main "${@}"

} # This ensures the entire script is downloaded
