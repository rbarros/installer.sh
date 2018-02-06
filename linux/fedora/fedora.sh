#!/bin/bash

{ # This ensures the entire script is downloaded

  PACKAGE="yum"
  PACKAGE_YES="yum -y"
  PACKAGE_INSTALL="install"

  fedora_main() {
    update_plataform
    check_gcc
    check_grep
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
    p="ok"
    # check_git_installation
    # check_git_config
    # check_composer_installation
    # create_project
    # alter_composer
    # alter_env
    # path_permissions
    # config
    while true $p != "ok"
    do
       step_done
       debug "Menu"
       debug ""
       debug "1 - Install LAMP"
       debug "2 - Oracle Instant"
       debug "3 - Install Oci8"
       debug "4 - Install PDO Oci8"
       debug "5 - Install git"
       debug "6 - Install composer"
       debug "7 - Create Project"
       debug "8 - Permissions"
       debug "9 - Alter .env"
       debug "10 - Sair"
       debug ""
       debug "Enter the desired option:"
       read p
       case $p in
       10) break;;
       9) alter_env ;;
       8) path_permissions ;;
       7) create_project ;;
       6) check_composer_installation ;;
       5) check_git_installation ;;
       4) install_pdo_oci8 ;;
       3) install_oci8 ;;
       2) oracle_instant ;;
       1) install_lamp ;;
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
    step "Install webserver fedora"
    step_done
    super -v+ $PACKAGE install httpd
    super -v+ systemctl start httpd.service
    super -v+ systemctl enable httpd.service
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
    step "Install php fedora"
    super -v+ $PACKAGE install php70u mod_php70u php70u-common php70u-cli php70u-mysqlnd php70u-mcrypt php70u-pear php70u-devel php70u-json php70u-mbstring
    super bash -c 'echo -e "<IfModule mod_rewrite.c>\n\tLoadModule rewrite_module modules/mod_rewrite.so\n</IfModule>" >> /etc/httpd/conf.modules.d/10-php.conf'
    super systemctl restart httpd.service
    step_done
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
    super -v+ $PACKAGE install mariadb-server mariadb-client
    super -v+ systemctl start mariadb
    super -v+ systemctl enable mariadb.service
  }

  oracle_instant() {
    step "Install oracle instant"
    step_done
    curl_or_wget "https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm" "/tmp/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm"
    curl_or_wget "https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm" "/tmp/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm"
    super -v+ $PACKAGE -y localinstall /tmp/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
    super -v+ $PACKAGE -y localinstall /tmp/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
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
    if [ -d "/etc/php/7.0/mods-available/" ]; then
      super bash -c 'echo -e "; Enable oci8 extension module\nextension=oci8.so" > /etc/php/7.0/mods-available/oci8.ini'
      super ln -s /etc/php/7.0/mods-available/oci8.ini /etc/php/7.0/apache2/conf.d/20-oci8.ini
      super ln -s /etc/php/7.0/mods-available/oci8.ini /etc/php/7.0/cli/conf.d/20-oci8.ini
    else
      super bash -c 'echo -e "; Enable oci8 extension module\nextension=oci8.so" > /etc/php.d/20-oci8.ini'
    fi
  }

  install_pear() {
    step "Install php"
    step_done
    super -v+ $PACKAGE install php70u-pear php70u-devel
    super systemctl restart httpd.service
  }

  install_pdo_oci8() {
    # https://secure.php.net/releases/
    step "Install pdo oci8"
    step_done
    PHP_VERSION=$(php -v | cut -d' ' -f 2 | head -n 1 | awk -F - '{ print $1 }')
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
    if [ -d "/etc/php/7.0/mods-available/" ]; then
      super bash -c 'echo -e "; Enable pdo_oci extension module\nextension=pdo_oci.so" > /etc/php/7.0/mods-available/pdo_oci.ini'
      super ln -s /etc/php/7.0/mods-available/pdo_oci.ini /etc/php/7.0/apache2/conf.d/20-pdo_oci.ini
      super ln -s /etc/php/7.0/mods-available/pdo_oci.ini /etc/php/7.0/cli/conf.d/20-pdo_oci.ini
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
    super -v+ $PACKAGE install php70u-mbstring
    super systemctl restart httpd.service
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
    super -v+ $PACKAGE install php70u-zip
    super systemctl restart httpd.service
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
    install_sed
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

  fedora_main "${@}"

} # This ensures the entire script is downloaded
