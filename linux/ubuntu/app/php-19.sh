#!/bin/bash

{ # This ensures the entire script is downloaded

  php_main() {
    debug "Install php $DISTRO $RELEASE"
    super -v+ $PACKAGE $PACKAGE_INSTALL php7.3 php7.3-dev php7.3-mbstring php7.3-common php7.3-curl php7.3-cli php7.3-gd php7.3-json php7.3-xml libapache2-mod-php7.3 zip unzip php7.3-zip php7.3-mysql php7.3-bcmath php-pear build-essential #build-dep
    super -v+ a2enmod rewrite
    super -v+ service apache2 restart
  }

  php_main "${@}"

} # This ensures the entire script is downloaded
