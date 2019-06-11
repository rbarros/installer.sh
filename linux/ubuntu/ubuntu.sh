#!/bin/bash

{ # This ensures the entire script is downloaded

  PACKAGE="apt-get"
  PACKAGE_YES="apt-get -y"
  PACKAGE_INSTALL="install"

  ubuntu_main() {
    update_plataform
    check_gcc
    check_grep
    check_sed
    menu
  }

  update_plataform() {
    STOP=0
    trap abort_update INT

    debug "Will be update within 10 seconds."
    debug "To prevent its update, just press CTRL+C now."
    counter

    if [ "$STOP" = 0 ]; then
      step_wait "Update $DISTRO, $RELEASE ..."
      if update_distro; then
        step_done
      fi
    fi

    trap - INT
  }

  abort_update() {
    STOP=1
    echo ""
    warn "installer needs to be update."
  }

  update_distro() {
    super -v+ ${PACKAGE} -y update
    super -v+ ${PACKAGE} -y upgrade
  }

  menu() {
    step "Select option install"
    key="ok"
    # check_git_installation
    # check_git_config
    # check_composer_installation
    # create_project
    # alter_composer
    # alter_env
    # path_permissions
    # config
    while true $key != "ok"
    do
       step_done
       debug "Menu"
       debug ""
       debug "1 - Install LAMP"
       debug "2 - Security Server"
       debug "3 - Oracle Instant"
       debug "4 - Install Oci8"
       debug "5 - Install PDO Oci8"
       debug "6 - Install git"
       debug "7 - Install composer"
       debug "8 - Install yarn"
       debug "9 - Create Project"
       debug "10 - Permissions"
       debug "11 - Alter .env"
       debug "ESC - Sair"
       debug ""
       debug "Enter the desired option:"
       read -s -n1 key
       case $key in
        1) install_lamp ;;
        2) security ;;
        3) oracle_instant ;;
        4) install_oci8 ;;
        5) install_pdo_oci8 ;;
        6) check_git_installation ;;
        7) check_composer_installation ;;
        8) check_yarn_installation ;;
        9) create_project ;;
        10) path_permissions ;;
        11) alter_env ;;
        $'\e') break ;;
       esac
    done
    success
  }

  install_lamp() {
    step "Install LAMP"
    step_done
    check_webserver
    check_php
    check_mysql
    debug "Finish install LAMP"
  }

  check_webserver() {
    step "Verifying that webserver is installed"
    step_done

    if command_exists apache2; then
      SERVER="apache2"
      if [ -d "/var/www/html" ]; then
        HTTPD_ROOT="/var/www/html"
      elif [ -d "/var/www" ]; then
        HTTPD_ROOT="/var/www"
      fi
    elif command_exists nginx; then
      SERVER="nginx"
      HTTPD_ROOT="/usr/share/nginx/html"
    else
      install_httpd
    fi
    if [ -d "$HTTPD_ROOT" ]; then
      debug $($SERVER -v)
      debug "ok [$HTTPD_ROOT]"
    fi
  }

  install_httpd() {
    step "Install webserver ubuntu"
    super -v+ $PACKAGE $PACKAGE_INSTALL apache2
    step_done
    security
  }

  restart_httpd() {
    step "Restart webserver..."
    if command_exists apache2; then
      super service apache2 restart
    elif command_exists nginx; then
      super service nginx restart
    fi
    step_done
  }

  security() {
    step "Security webserver ubuntu"
    if [ -f "/etc/apache2/conf-available/security.conf" ]; then
      debug "Backup security.conf"
      super cp /etc/apache2/conf-available/security.conf /etc/apache2/conf-available/security.conf.bkp
      super sed -i -e "s/\(^ServerTokens \).*/\1Prod/" \
                   -e "s/\(^ServerSignature \).*/\1Off/" \
                   -e "s/\(^TraceEnable \).*/\1Off/" /etc/apache2/conf-available/security.conf
      restart_httpd
    else
      echo "WebServer not installed"
    fi
    if [ -f "/etc/ssh/sshd_config" ]; then
      debug "Backup sshd_config"
      super cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bkp
      if [ $(cat /etc/ssh/sshd_config | grep Banner | wc -l) > 1 ]; then
        if [ $(cat /etc/ssh/sshd_config | grep '^Banner' | wc -l) == 1 ]; then
          super sed -i -e "s/\(^Banner \).*/\1no/" /etc/ssh/sshd_config
        fi
        if [ $(cat /etc/ssh/sshd_config | grep '^DebianBanner' | wc -l) == 0 ]; then
          super bash -c 'echo -e "DebianBanner no" >> /etc/ssh/sshd_config'
        elif [ $(cat /etc/ssh/sshd_config | grep '^DebianBanner' | wc -l) == 1 ]; then
          super sed -i -e "s/\(^DebianBanner \).*/\1no/" /etc/ssh/sshd_config
        fi
      else
        if [ $(cat /etc/ssh/sshd_config | grep '#Banner' | wc -l) == "1" ]; then
            super bash -c 'echo -e "Banner no" >> /etc/ssh/sshd_config'
            super bash -c 'echo -e "DebianBanner no" >> /etc/ssh/sshd_config'
        fi
      fi
      restart_ssh
    else
      echo "OpenSSH not installed!"
    fi
    step_done
  }

  restart_ssh() {
    step "Restart webserver..."
    super service ssh restart
    step_done
  }

  check_php() {
    step "Verifying that php is installed"
    step_done
    if command_exists php; then
      recommended_version=7.0.0
      current_version=$(php -v)
      if version_gt $recommended_version $current_version; then
        #echo "$recommended_version is greater than $current_version !"
        warn "current php version is smaller recomended!"
      else
        #echo "$recommended_version is smaller than $current_version !"
        debug "ok php version - $current_version"
      fi
    else
      install_php
    fi
  }

  install_php() {
    step "Install php"
    debug "15.10  wily       jessie / sid"
    debug "15.04  vivid      jessie / sid"
    debug "14.10  utopic     jessie / sid"
    debug "14.04  trusty     jessie / sid"
    debug "13.10  saucy      wheezy / sid"
    debug "13.04  raring     wheezy / sid"
    debug "12.10  quantal    wheezy / sid"
    debug "12.04  precise    wheezy / sid"
    debug "11.10  oneiric    wheezy / sid"
    debug "11.04  natty      squeeze / sid"
    debug "10.10  maverick   squeeze / sid"
    debug "10.04  lucid      squeeze / sid"
    debug ""
    debug "This PPA contains latest PHP 5.5 packaged for Ubuntu 14.04 LTS (Trusty)."
    debug ""
    debug "You can get more information about the packages at https://deb.sury.org"
    debug ""
    debug "If you need other PHP versions use:"
    debug "PHP 5.4: ppa:ondrej/php5-oldstable (Ubuntu 12.04 LTS)"
    debug "PHP 5.5: ppa:ondrej/php5 (Ubuntu 14.04 LTS)"
    debug "PHP 5.6: ppa:ondrej/php5-5.6 (Ubuntu 14.04 LTS - Ubuntu 16.04 LTS)"
    debug "PHP 5.6 and PHP 7.0: ppa:ondrej/php (Ubuntu 14.04 LTS - Ubuntu 16.04 LTS)"
    debug ""
    debug "BUGS&FEATURES: This PPA now has a issue tracker: https://deb.sury.org/pages/bugreporting.html"
    debug "PLEASE READ: If you like my work and want to give me a little motivation, please consider donating: https://deb.sury.org/pages/donate.html"
    debug "WARNING: add-apt-repository is broken with non-UTF-8 locales, see https://github.com/oerdnj/deb.sury.org/issues/56 for workaround:"
    debug " # apt-get install -y language-pack-en-base"
    debug " # LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php5"
    debug " $ sudo add-apt-repository ppa:ondrej/php5-5.6"
    debug " $ sudo apt-get update"
    debug " $ sudo apt-get upgrade"
    debug " $ sudo apt-get autoremove"
    debug " $ sudo apt-get install php5"
    debug ""
    V=$(echo $RELEASE|awk -F. '{ print $1 }');
    case ${RELEASE} in
      12*) download "php" "$PLATFORM/$DISTRO/app/php-$V";;
      14*) download "php" "$PLATFORM/$DISTRO/app/php-$V";;
      16*) download "php" "$PLATFORM/$DISTRO/app/php-$V";;
      17*) download "php" "$PLATFORM/$DISTRO/app/php-$V";;
      18*) download "php" "$PLATFORM/$DISTRO/app/php-$V";;
    esac
    step_done

    if [ -f /tmp/installer-php.sh ]; then
        . /tmp/installer-php.sh
        php_main
    else
        # Show error
        echo -e "|\n|   Error: The php.sh could not be downloaded\n|"
    fi
  }

  check_mysql() {
    step "Verifying that mysql is installed"
    step_done

    if command_exists mysql; then
      debug $(mysql --version)
    else
      install_mysql
      debug "After installation run mysql_secure_installation"
      debug "If you have problems with access run sudo mysql -u root -p"
      debug " "
      debug "GRANT ALL ON *.* TO \"root\"@\"localhost\" IDENTIFIED BY \"password\";"
      debug " "
    fi
  }

  install_mysql() {
    step "Install mysql"
    step_done
    V=$(echo $RELEASE|awk -F. '{ print $1 }');
    case ${RELEASE} in
      12*) download "mysql" "$PLATFORM/$DISTRO/app/mysql-$V";;
      14*) download "mysql" "$PLATFORM/$DISTRO/app/mysql-$V";;
      16*) download "mysql" "$PLATFORM/$DISTRO/app/mysql-$V";;
      17*) download "mysql" "$PLATFORM/$DISTRO/app/mysql-$V";;
      18*) download "mysql" "$PLATFORM/$DISTRO/app/mysql-$V";;
    esac

    if [ -f /tmp/installer-mysql.sh ]; then
        . /tmp/installer-mysql.sh
        mysql_main
    else
        # Show error
        echo -e "|\n|   Error: The php.sh could not be downloaded\n|"
    fi
  }

  oracle_instant() {
    step "Install oracle instant"
    step_done
    curl_or_wget "https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-basic_11.2.0.4.0-2_amd64.deb" "/tmp/oracle-instantclient11.2-basic_11.2.0.4.0-2_amd64.deb"
    curl_or_wget "https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-devel_11.2.0.4.0-2_amd64.deb" "/tmp/oracle-instantclient11.2-devel_11.2.0.4.0-2_amd64.deb"
    super -v+ dpkg -i /tmp/oracle-instantclient11.2-basic_11.2.0.4.0-2_amd64.deb
    super -v+ dpkg -i /tmp/oracle-instantclient11.2-devel_11.2.0.4.0-2_amd64.deb
    super mkdir /usr/lib/oracle/11.2/client64/network/admin -p

    # SQLSTATE[HY000]: pdo_oci_handle_factory; ORA-12546: TNS: permission denied (/home/user/php-7.0.6/ext/pdo_oci/)
    super setsebool -P httpd_can_network_connect on
  }

  install_oci8() {
    step "Install oci8"
    step_done
    debug "Use 'pecl install oci8' to install for PHP 7."
    debug "Use 'pecl install oci8-2.0.12' to install for PHP 5.2 - PHP 5.6."
    debug "Use 'pecl install oci8-1.4.10' to install for PHP 4.3.9 - PHP 5.1."
    debug "Use 'instantclient,/path/to/instant/client/lib' if you're compiling with Oracle Instant Client [autodetect] :"
    debug "copy and paste instantclient,/usr/lib/oracle/11.2/client64/lib"
    debug "http://www.oracle.com/technetwork/articles/technote-php-instant-084410.html"
    PHP_VERSION_SHORT=$(php -v | cut -d' ' -f 2 | head -n 1 | awk -F - '{ print $1 }' | awk -F . '{ print $1"."$2}')
    export ORACLE_HOME=/usr/lib/oracle/11.2/client64/
    super ln -nsf /usr/lib/oracle/11.2/client64/ /usr/lib/oracle/11.2/client
    super ln -nsf /usr/include/oracle/11.2/client64/ /usr/include/oracle/11.2/client
    super ln -s /usr/lib/oracle/11.2/client64/lib/libnnz11.so /usr/lib/libnnz11.so
    if command_exists pecl; then
      debug "pecl is installed, skipping pecl installation."
    else
      install_pear
    fi
    recommended_version=7.0.0
    current_version=$(php -v)
    if version_gt "7.0.0" $current_version; then
      warn "current php version is smaller recomended!"
      debug "Use 'pecl install oci8-2.0.12' to install for PHP 5.2 - PHP 5.6"
      echo 'instantclient,/usr/lib/oracle/11.2/client64/lib' | super -v+ pecl install oci8-2.0.12
    else
      debug "Use 'pecl install oci8' to install for PHP 7"
      echo 'instantclient,/usr/lib/oracle/11.2/client64/lib' | super -v+ pecl install oci8
    fi
    if [ -d "/etc/php/$PHP_VERSION_SHORT/mods-available/" ]; then
      super bash -c 'echo -e "; Enable oci8 extension module\nextension=oci8.so" > /etc/php/'$PHP_VERSION_SHORT'/mods-available/oci8.ini'
      super ln -s /etc/php/$PHP_VERSION_SHORT/mods-available/oci8.ini /etc/php/$PHP_VERSION_SHORT/apache2/conf.d/20-oci8.ini
      super ln -s /etc/php/$PHP_VERSION_SHORT/mods-available/oci8.ini /etc/php/$PHP_VERSION_SHORT/cli/conf.d/20-oci8.ini
    else
      super bash -c 'echo -e "; Enable oci8 extension module\nextension=oci8.so" > /etc/php.d/20-oci8.ini'
    fi
  }

  install_pear() {
    step "Install php"
    step_done
    super -v+ $PACKAGE install php-pear build-essential php7.0-dev #build-dep
    restart_httpd
  }

  install_pdo_oci8() {
    # https://secure.php.net/releases/
    step "Install pdo oci8"
    step_done
    PHP_VERSION=$(php -v | cut -d' ' -f 2 | head -n 1 | awk -F - '{ print $1 }')
    PHP_VERSION_SHORT=$(php -v | cut -d' ' -f 2 | head -n 1 | awk -F - '{ print $1 }' | awk -F . '{ print $1"."$2}')
    export ORACLE_HOME=/usr/lib/oracle/11.2/client64/

    #checking for oci.h... configure: error: I'm too dumb to figure out where the include dir is in your instant client install
    #sudo ln -s /usr/local/instantclient_12_1 /usr/local/instantclient
    #sudo ln -s /usr/local/instantclient_12_1/libclntsh.so.12.1 /usr/local/instantclient/libclntsh.so
    #sudo ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus
    #sudo ln -nsf /usr/lib/oracle/12.1/client64/ /usr/lib/oracle/12.1/client
    #sudo ln -nsf /usr/include/oracle/12.1/client64/ /usr/include/oracle/12.1/client
    #sudo ln -s /usr/lib/oracle/12.1/client64/lib/libnnz12.so /usr/lib64/libnnz12.so
    #sudo ln -s /usr/lib/oracle/12.1/client64/lib/libnnz12.so /usr/lib/libnnz12.so
    super ln -nsf /usr/lib/oracle/11.2/client64/ /usr/lib/oracle/11.2/client
    super ln -nsf /usr/include/oracle/11.2/client64/ /usr/include/oracle/11.2/client
    super ln -s /usr/lib/oracle/11.2/client64/lib/libnnz11.so /usr/lib/libnnz11.so

    cd ~
    if [ ! -f "php-$PHP_VERSION.tar.bz2" ]; then
      recommended_version=7.0.0
      if version_gt $recommended_version $PHP_VERSION; then
        curl_or_wget "http://museum.php.net/php5/php-$PHP_VERSION.tar.bz2" "php-$PHP_VERSION.tar.bz2"
        super -v+ $PACKAGE install libaio1 libaio-dev
      else
        curl_or_wget "http://br2.php.net/get/php-$PHP_VERSION.tar.bz2/from/this/mirror" "php-$PHP_VERSION.tar.bz2"
      fi
    fi
    if [ ! -d /usr/include/php ]; then
      ln -s /usr/include/php5 /usr/include/php
    fi
    tar -jxvf php-$PHP_VERSION.tar.bz2
    cd php-$PHP_VERSION/ext/pdo_oci/
    phpize
    ./configure --with-pdo-oci=instantclient,/usr,11.2
    make
    make test
    super make install
    if [ -d "/etc/php/$PHP_VERSION_SHORT/mods-available/" ]; then
      super bash -c 'echo -e "; Enable pdo_oci extension module\nextension=pdo_oci.so" > /etc/php/'$PHP_VERSION_SHORT'/mods-available/pdo_oci.ini'
      super ln -s /etc/php/$PHP_VERSION_SHORT/mods-available/pdo_oci.ini /etc/php/$PHP_VERSION_SHORT/apache2/conf.d/20-pdo_oci.ini
      super ln -s /etc/php/$PHP_VERSION_SHORT/mods-available/pdo_oci.ini /etc/php/$PHP_VERSION_SHORT/cli/conf.d/20-pdo_oci.ini
    elif [ -d "/etc/php5/conf.d/" ]; then
      super bash -c 'echo -e "; Enable pdo_oci extension module\nextension=pdo_oci.so" > /etc/php5/conf.d/pdo_oci.ini'
      super ln -s /etc/php5/conf.d/pdo_oci.ini /etc/php5/apache2/conf.d/20-pdo_oci.ini
      super ln -s /etc/php5/conf.d/pdo_oci.ini /etc/php5/cli/conf.d/20-pdo_oci.ini
    fi
    php -i | grep oci
    super bash -c 'echo -e "<?php phpinfo(); " > $HTTPD_ROOT/phpinfo.php'
    ip addr show | grep "inet 192" | awk -F/ '{print $1}' | sed -e "s/inet//g"
  }

  # php version 7.0 (recomended)
  check_php_version() {
    return verlte php -v 7.0 && echo "yes" || echo "no"
  }

  # git version 1.8.5.2 (Apple Git-48)
  check_git_version() {
    return verlte git --version 1.0 && echo "yes" || echo "no"
  }

  check_git_installation() {
    step "Checking for Git installation"
    if command_exists git; then echo "ok"; else echo "no"; fi
    if command_exists git; then
      step_done
      debug "Git detected"
      check_git
    fi
    check_git_config
  }

  check_git() {
    step "Checking version git"
    step_done
    if [ check_git_version = "yes" ]; then
      warn "version below 1.0"
      install_git
    else
      debug $(git --version)
    fi
  }

  install_git() {
    step_wait "Installing Git"
    if super ${PACKAGE} -y update git; then
      step_done
    else
      step_fail
      add_report "not installing git"
      fail
    fi
  }

  check_git_config() {
    username=$(git config --global user.name)
    if [ -z "$username" ]; then
      read -p "Informe o nome do usuário do bitbucket [$username]." username
      git config --global user.name "$username"
    else
      debug "Git user.name: $username"
    fi
    usermail=$(git config --global user.email)
    if [ -z "$usermail" ]; then
      read -p "Informe o email do usuário do bitbucket [$usermail]." useremail
      git config --global user.email $useremail
    else
      debug "Git user.mail: $useremail"
    fi
  }

  check_composer_installation() {
    step "Checking Composer installation"
    step_done

    if command_exists composer; then
      debug "Composer is installed, skipping Composer installation."
      debug "  To update Composer, run the command bellow:"
      debug "  $ composer self-update"
      update_composer
    else
      install_composer
    fi
  }

  update_composer() {
    step "Update composer"
    step_done
    super composer self-update
  }

  install_composer() {
    step "Installing composer"
    step_done
    if [ ! -f "composer.phar" ]; then
      curl_or_wget "https://getcomposer.org/composer.phar" "composer.phar"
    fi
    if comfirm "Move composer /usr/bin/composer ?"; then
        super mv composer.phar /usr/bin/composer
        super chmod +x /usr/bin/composer
    fi
  }

  check_yarn_installation() {
    step "Checking Yarn installation"
    step_done

    if command_exists yarn; then
      debug "Yarn is installed, skipping Yarn installation."
      debug "  To update Yarn, run the command bellow:"
      #debug "  $ yarn self-update" https://github.com/yarnpkg/yarn/issues/1139
      debug " apt-get install yarn"
      update_yarn
    else
      install_yarn
    fi
  }

  update_yarn() {
    step "Update Yarn"
    step_done
    super -v+ ${PACKAGE} -y install yarn
  }

  install_yarn() {
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | super -v+ apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | super -v+ tee /etc/apt/sources.list.d/yarn.list
    step "Install Yarn"
    step_done
    super -v+ ${PACKAGE} -y install yarn
  }

  create_project() {
    check_mbstring_extension
    check_zip_extension
    step "Create a project installer"
    step_done
    htdocs=""
    repo=""
    user="www-data"
    group=$(groups $USER | awk -F' ' '{ print $3 }')
    read -p "What the user apache/nginx [$user] ? " user
    if [ -z "$user" ]; then
      debug "The user apache/nginx is required."
      create_project
    fi
    read -p "What the group [$group] ? " group
    if [ -z "$group" ]; then
      debug "The group is required."
      create_project
    fi
    read -p "What the directory apache/nginx [$HTTPD_ROOT] ? " htdocs
    if [ "$htdocs" ]; then
      HTTPD_ROOT=$htdocs
    fi
    read -p "What is the project name [$PROJECT] ? " PROJECT
    if [ -z "$PROJECT" ]; then
      debug "The project name is required."
      create_project
    fi
    debug "# chown $USER:$group ~/.composer -hR"
    sudo chown $USER:$group ~/.composer -hR
    if [ ! -d "$PROJECT" ]; then
      cd $HTTPD_ROOT
      #super mkdir "$HTTPD_ROOT/$PROJECT"
      read -p "What the project repository [$repo] ? " repo
      if [ -z "$repo" ]; then
        debug "The project repository is required."
        create_project
      fi
      super -v+ git clone $repo $PROJECT
      step "Permission path project"
      step_done
      debug "# chown <user_apache>:<grupo_user> $PROJECT -hR"
      super chown $user:root $PROJECT -hR
      cd $PROJECT
      super -v+ composer install
    else
      cd $HTTPD_ROOT
      debug "The project [$PROJECT] already exists!"
      UPDATE="true"
      step "Permission path project"
      step_done
      debug "# chown <user_apache>:<grupo_user> $PROJECT -hR"
      super chown $user:root $PROJECT -hR
      cd $PROJECT
      super -v+ composer update
    fi
  }

  check_mbstring_extension() {
    step "Check mbstring extension"
    step_done
    extension=$(php -m | grep -P mbstring)
    if [ -z "$extension" ]; then
      install_mbstring
    fi
  }

  install_mbstring() {
    step "Install mbstring"
    step_done
    super -v+ $PACKAGE install php7.0-mbstring
    restart_httpd
  }

  check_zip_extension() {
    step "Check zip extension"
    step_done
    extension=$(php -m | grep -P zip)
    if [ -z "$extension" ]; then
      install_zip
    fi
  }

  install_zip() {
    step "Install zip"
    step_done
    super -v+ $PACKAGE install php7.0-zip
    restart_httpd
  }

  alter_composer() {
    step "Changing the project composer"
    step_done
    install_jq
    read -p "What is the project name [$PROJECT] ? " PROJECT
    if [ -z "$PROJECT" ]; then
      debug "The project name is required."
      alter_composer
    fi
    cd "$HTTPD_ROOT/$PROJECT"
    if [ -f "composer.json" ]; then
      if [ ! -f "composer.json.bkp" ]; then
          debug "Backup composer.json"
          cp composer.json composer.json.bkp
          debug "Adding repository Core Saga in composer.json"
          if comfirm "This computer is configured for ssh access to bitbucket ?"; then
            REPO="git@bitbucket.org:sagaprojetosweb/core.git"
          else
            REPO="https://bitbucket.org/sagaprojetosweb/core.git"
          fi
          jq --arg repo "$REPO" '. + { "repositories": [{ "type": "git", "url": $repo }] }' composer.json > composer.temp && mv composer.temp composer.json
          jq '.["require-dev"] |= .+ {"sagaprojetosweb/core": "2.*"}' composer.json > composer.temp && mv composer.temp composer.json
          jq '.' composer.json
      fi
      composer update
    else
      warn "composer.json not found"
    fi
  }

  alter_env() {
    step "Changing the .env file project"
    step_done
    read -p "What is the project name [$PROJECT] ? " PROJECT
    if [ -z "$PROJECT" ]; then
      debug "The project name is required."
      alter_env
    fi
    cd "$HTTPD_ROOT/$PROJECT"
    if [ -f ".env" ]; then
      read -p "DB_HOST [127.0.0.1]: " DB_HOST
      if [ -z "$DB_HOST" ]; then
        DB_HOST=127.0.0.1
      fi
      read -p "DB_DATABASE [homestead]: " DB_DATABASE
      if [ -z "$DB_DATABASE" ]; then
        DB_DATABASE=homestead
      fi
      read -p "DB_USERNAME [homestead]: " DB_USERNAME
      if [ -z "$DB_USERNAME" ]; then
        DB_USERNAME=homestead
      fi
      read -p "DB_PASSWORD []: " DB_PASSWORD
      #if [ -z "$DB_PASSWORD:[secret]" ]; then
        #DB_PASSWORD=secret
      #fi

      step "Create database project"
      if echo "create database $DB_DATABASE charset utf8;" | mysql -u $DB_USERNAME -p$DB_PASSWORD ; then    # allowed to fail
          step_done
          debug "Database $DB_DATABASE created"
      else
          step_done
          warn "Database $DB_DATABASE not created"
      fi

      step "Import database project"
      if mysql -u $DB_USERNAME -p$DB_PASSWORD $DB_DATABASE < migrations/dump.sql ; then    # allowed to fail
          step_done
          debug "Database $DB_DATABASE imported"
      else
          step_done
          warn "Database $DB_DATABASE not imported"
      fi

      if [ ! -f ".env.bkp" ]; then
          debug "Backup .env"
          super cp .env .env.bkp
          super sed -i -e "s/\(DB_HOST=\).*/\1$DB_HOST/" \
                       -e "s/\(DB_DATABASE=\).*/\1$DB_DATABASE/" \
                       -e "s/\(DB_USERNAME=\).*/\1$DB_USERNAME/" \
                       -e "s/\(DB_PASSWORD=\).*/\1$DB_PASSWORD/" .env
      fi
    else
      debug ".env not found"
    fi
  }

  path_permissions() {
    step "Changing permissions project"
    step_done
    read -p "What is the project name [$PROJECT] ? " PROJECT
    if [ -z "$PROJECT" ]; then
      debug "The project name is required."
      path_permissions
    fi
    if [ -d "$HTTPD_ROOT/$PROJECT" ]; then
      cd "$HTTPD_ROOT/$PROJECT"
      if [ -d "logs" ]; then
        super chmod -R 755 "logs"
      fi
      if [ -d "public/arquivos" ]; then
        super chmod -R 755 "public/arquivos"
      fi
      if [ -d "storage" ]; then
        super chmod -R 755 "storage"
      fi
    fi
  }

  config() {
    step "Project Setup"
    step_done
    read -p "What is the project name [$PROJECT] ? " PROJECT
    if [ -z "$PROJECT" ]; then
      debug "The project name is required."
      config
    fi
    if [ -d "$HTTPD_ROOT/$PROJECT" ]; then
      cd "$HTTPD_ROOT/$PROJECT"
      if [ ! -f "config/app.bkp.php" ]; then
        debug "Backup do config/app.php"
        cp config/app.php config/app.bkp.php
        sed -i -e "s@RouteServiceProvider::class@RouteServiceProvider::class,\n\t\tCartalyst\\\Sentinel\\\Laravel\\\SentinelServiceProvider::class,\n\t\tPingpong\\\Modules\\\ModulesServiceProvider::class,\n\t\tTwigBridge\\\ServiceProvider::class,\n\t\tSaga\\\Core\\\ServiceProvider::class@g" config/app.php
        php artisan vendor:publish --provider="Saga\Core\ServiceProvider"
        php artisan vendor:publish --provider="Cartalyst\Sentinel\Laravel\SentinelServiceProvider"
        if [ -f "database/migrations/2014_10_12_000000_create_users_table.php" ]; then
            rm database/migrations/2014_10_12_000000_create_users_table.php
        fi
        if [ -f  "database/migrations/2014_10_12_100000_create_password_resets_table.php" ]; then
            rm database/migrations/2014_10_12_100000_create_password_resets_table.php
        fi
        php artisan migrate
      fi
    fi
  }

  ubuntu_main "${@}"

} # This ensures the entire script is downloaded
