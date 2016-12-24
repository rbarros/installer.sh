#!/bin/bash

{ # This ensures the entire script is downloaded

  check_distro() {
    step "Checking distro platform"

    if [[ -e /etc/os-release ]]; then
      # Detecting DISTRO and RELEASE
      . /etc/os-release
      DISTRO=$ID
      RELEASE=$VERSION_ID
    fi

    # Docker containers
    if [[ -e /etc/lsb-release ]]; then
      # Detecting DISTRO and RELEASE
      . /etc/lsb-release
      DISTRO=$( echo $DISTRIB_ID | awk '{print tolower($0)}')
      RELEASE=$DISTRIB_RELEASE
    fi

    if [[ -e /etc/redhat-release ]]; then
      RELEASE_RPM=$(rpm -qf /etc/redhat-release)
      RELEASE=$(rpm -q --qf '%{VERSION}' ${RELEASE_RPM})
      case ${RELEASE_RPM} in
        centos*)
          DISTRO="centos"
          ;;
        redhat*)
          DISTRO="redhat"
          ;;
        *)
          echo "unknown EL clone"
          exit 1
          ;;
      esac
    fi

    step_done
    debug "Detected distribution: $DISTRO, $RELEASE"

    step "Get package distro"
    case ${DISTRO} in
      ubuntu*)
        step_done
        #debug "detected Ubuntu ${RELEASE}"
        PACKAGE="apt-get"
        ;;
      debian*)
        step_done
        #debug "detected Debian ${RELEASE}"
        PACKAGE="apt-get"
        ;;
      centos*)
        step_done
        #debug "detected CentOS ${RELEASE}"
        PACKAGE="yum"
        ;;
      redhat*)
        step_done
        #debug "detected RHEL ${RELEASE}"
        PACKAGE="yum"
        ;;
      fedora*)
        step_done
        #debug "detected Fedora ${RELEASE}"
        PACKAGE="yum"
        ;;
      *)
        step_fail
        add_report "Cannot detect the current distro."
        fail
        ;;
    esac
    update_plataform
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

  check_gcc() {
    step "Verifying that gcc is installed"
    step_done
    if command_exists gcc; then
      debug "gcc is installed, skipping gcc installation."
      debug $(gcc --version)
    else
      install_gcc
    fi
  }

  install_gcc() {
    debug "Installing gcc"
    super -v+ ${PACKAGE} -y install gcc
  }

  check_grep() {
    step "Verifying that grep is installed"
    step_done
    if command_exists grep; then
      debug "grep is installed, skipping grep installation."
      debug $(grep --version)
    else
      install_grep
    fi
  }

  install_grep() {
    debug "Installing grep"
    super -v+ ${PACKAGE} -y install grep
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
    step "Install webserver"
    case ${DISTRO} in
      ubuntu*)
        step_done
        debug "Install webserver ubuntu"
        super -v+ $PACKAGE install apache2
        ;;
      debian*)
        step_done
        debug "Install webserver debian"
        super -v+ $PACKAGE install apache2
        ;;
      centos*)
        step_done
        debug "Install webserver centos"
        super -v+ $PACKAGE install httpd
        super -v+ systemctl start httpd.service
        super -v+ systemctl enable httpd.service
        ;;
      redhat*)
        step_done
        debug "Install webserver redhat"
        super -v+ $PACKAGE install httpd
        super -v+ systemctl start httpd.service
        super -v+ systemctl enable httpd.service
        ;;
      fedora*)
        step_done
        debug "Install webserver fedora"
        super -v+ $PACKAGE install httpd
        super -v+ systemctl start httpd.service
        super -v+ systemctl enable httpd.service
        ;;
      *)
        step_fail
        add_report "Cannot detect the current distro."
        fail
        ;;
    esac
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
    case ${DISTRO} in
      ubuntu*)
        step_done
        # 15.10  wily       jessie / sid
        # 15.04  vivid      jessie / sid
        # 14.10  utopic     jessie / sid
        # 14.04  trusty     jessie / sid
        # 13.10  saucy      wheezy / sid
        # 13.04  raring     wheezy / sid
        # 12.10  quantal    wheezy / sid
        # 12.04  precise    wheezy / sid
        # 11.10  oneiric    wheezy / sid
        # 11.04  natty      squeeze / sid
        # 10.10  maverick   squeeze / sid
        # 10.04  lucid      squeeze / sid
        #
        # This PPA contains latest PHP 5.5 packaged for Ubuntu 14.04 LTS (Trusty).
        #
        # You can get more information about the packages at https://deb.sury.org
        #
        # If you need other PHP versions use:
        # PHP 5.4: ppa:ondrej/php5-oldstable (Ubuntu 12.04 LTS)
        # PHP 5.5: ppa:ondrej/php5 (Ubuntu 14.04 LTS)
        # PHP 5.6: ppa:ondrej/php5-5.6 (Ubuntu 14.04 LTS - Ubuntu 16.04 LTS)
        # PHP 5.6 and PHP 7.0: ppa:ondrej/php (Ubuntu 14.04 LTS - Ubuntu 16.04 LTS)
        #
        # BUGS&FEATURES: This PPA now has a issue tracker: https://deb.sury.org/pages/bugreporting.html
        # PLEASE READ: If you like my work and want to give me a little motivation, please consider donating: https://deb.sury.org/pages/donate.html
        # WARNING: add-apt-repository is broken with non-UTF-8 locales, see https://github.com/oerdnj/deb.sury.org/issues/56 for workaround:
        # # apt-get install -y language-pack-en-base
        # # LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php5
        # $ sudo add-apt-repository ppa:ondrej/php5-5.6
        # $ sudo apt-get update
        # $ sudo apt-get upgrade
        # $ sudo apt-get autoremove
        # $ sudo apt-get install php5
        #
        case ${RELEASE} in
          12*) echo -e "|   Downloading installer-php.sh to /tmp/installer-php.sh\n|\n|   + $(wget -nv -o /dev/stdout -O /tmp/installer-php.sh --no-check-certificate $URL/linux/ubuntu/php-12.sh)";;
          14*) echo -e "|   Downloading installer-php.sh to /tmp/installer-php.sh\n|\n|   + $(wget -nv -o /dev/stdout -O /tmp/installer-php.sh --no-check-certificate $URL/linux/ubuntu/php-14.sh)";;
          16*) echo -e "|   Downloading installer-php.sh to /tmp/installer-php.sh\n|\n|   + $(wget -nv -o /dev/stdout -O /tmp/installer-php.sh --no-check-certificate $URL/linux/ubuntu/php-16.sh)";;
        esac

        if [ -f /tmp/installer-php.sh ]; then
            . /tmp/installer-php.sh
            php_main
        else
            # Show error
            echo -e "|\n|   Error: The php.sh could not be downloaded\n|"
        fi
        ;;
      debian*)
        step_done
        case ${RELEASE} in
          6*) echo -e "|   Downloading installer-php.sh to /tmp/installer-php.sh\n|\n|   + $(wget -nv -o /dev/stdout -O /tmp/installer-php.sh --no-check-certificate $URL/linux/ubuntu/php-14.sh)";;
          7*) echo -e "|   Downloading installer-php.sh to /tmp/installer-php.sh\n|\n|   + $(wget -nv -o /dev/stdout -O /tmp/installer-php.sh --no-check-certificate $URL/linux/ubuntu/php-14.sh)";;
          8*) echo -e "|   Downloading installer-php.sh to /tmp/installer-php.sh\n|\n|   + $(wget -nv -o /dev/stdout -O /tmp/installer-php.sh --no-check-certificate $URL/linux/ubuntu/php-14.sh)";;
        esac
        ;;
      centos*)
        step_done
        centos_install_epel
        centos_install_ius
        debug "Install php centos"
        super -v+ $PACKAGE install php70u mod_php70u php70u-common php70u-cli php70u-mysqlnd php70u-mcrypt php70u-pear php70u-devel php70u-json php70u-mbstring
        super bash -c 'echo -e "<IfModule mod_rewrite.c>\n\tLoadModule rewrite_module modules/mod_rewrite.so\n</IfModule>" >> /etc/httpd/conf.modules.d/10-php.conf'
        super systemctl restart httpd.service
        ;;
      redhat*)
        step_done
        rhel_install_epel
        rhel_install_ius
        debug "Install php readhat"
        super -v+ $PACKAGE install php70u mod_php70u php70u-common php70u-cli php70u-mysqlnd php70u-mcrypt php70u-pear php70u-devel php70u-json php70u-mbstring
        super bash -c 'echo -e "<IfModule mod_rewrite.c>\n\tLoadModule rewrite_module modules/mod_rewrite.so\n</IfModule>" >> /etc/httpd/conf.modules.d/10-php.conf'
        super systemctl restart httpd.service
        ;;
      fedora*)
        debug "Install php fedora"
        step_done
        super -v+ $PACKAGE install php70u mod_php70u php70u-common php70u-cli php70u-mysqlnd php70u-mcrypt php70u-pear php70u-devel php70u-json php70u-mbstring
        super bash -c 'echo -e "<IfModule mod_rewrite.c>\n\tLoadModule rewrite_module modules/mod_rewrite.so\n</IfModule>" >> /etc/httpd/conf.modules.d/10-php.conf'
        super systemctl restart httpd.service
        ;;
      *)
        step_fail
        add_report "Cannot detect the current distro."
        fail
        ;;
    esac
  }

  centos_install_epel(){
    # CentOS has epel release in the extras repo
    super -v+ $PACKAGE -y install epel-release
    import_epel_key
  }

  rhel_install_epel(){
    case ${RELEASE} in
      5*) el5_download_install https://dl.fedoraproject.org/pub/epel/epel-release-latest-5.noarch.rpm;;
      6*) super -v+ $PACKAGE -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm;;
      7*) super -v+ $PACKAGE -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm;;
    esac
    import_epel_key
  }

  import_epel_key(){
    case ${RELEASE} in
      5*) rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL;;
      6*) rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6;;
      7*) rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7;;
    esac
  }

  centos_install_ius(){
    case ${RELEASE} in
      5*) el5_download_install https://centos5.iuscommunity.org/ius-release.rpm;;
      6*) super -v+ $PACKAGE -y install https://centos6.iuscommunity.org/ius-release.rpm;;
      7*) super -v+ $PACKAGE -y install https://centos7.iuscommunity.org/ius-release.rpm;;
    esac
    import_ius_key
  }

  rhel_install_ius(){
    case ${RELEASE} in
      5*) el5_download_install https://rhel5.iuscommunity.org/ius-release.rpm;;
      6*) super -v+ $PACKAGE -y install https://rhel6.iuscommunity.org/ius-release.rpm;;
      7*) super -v+ $PACKAGE -y install https://rhel7.iuscommunity.org/ius-release.rpm;;
    esac
    import_ius_key
  }

  el5_download_install(){
    wget -O /tmp/release.rpm ${1}
    super -v+ $PACKAGE -y localinstall /tmp/release.rpm
    rm -f /tmp/release.rpm
  }

  import_ius_key(){
    rpm --import /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY
  }

  check_mysql() {
    step "Verifying that mysql is installed"
    step_done

    if command_exists mysql; then
      debug $(mysql --version)
    else
      install_mysql
      mysql_secure_installation
    fi
  }

  install_mysql() {
    step "Install mysql"
    case ${DISTRO} in
      ubuntu*)
        step_done
        super -v+ $PACKAGE install mariadb-server mariadb-client
        ;;
      debian*)
        step_done
        super -v+ $PACKAGE install mysql-server mysql-client
        ;;
      centos*)
        step_done
        super -v+ $PACKAGE install mariadb-server mariadb
        super -v+ systemctl start mariadb
        super -v+ systemctl enable mariadb.service
        ;;
      redhat*)
        step_done
        super -v+ $PACKAGE install mariadb-server mariadb
        super -v+ systemctl start mariadb
        super -v+ systemctl enable mariadb.service
        ;;
      fedora*)
        step_done
        super -v+ $PACKAGE install mariadb-server mariadb-client
        super -v+ systemctl start mariadb
        super -v+ systemctl enable mariadb.service
        ;;
      *)
        step_fail
        add_report "Cannot detect the current distro."
        fail
        ;;
    esac
  }

  oracle_instant() {
    step "Install oracle instant"
    case ${DISTRO} in
      ubuntu*)
        step_done
        super curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-basic_11.2.0.4.0-2_amd64.deb
        super curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-devel_11.2.0.4.0-2_amd64.deb
        super -v+ dpkg -i oracle-instantclient11.2-basic_11.2.0.4.0-2_amd64.deb
        super -v+ dpkg -i oracle-instantclient11.2-devel_11.2.0.4.0-2_amd64.deb
        super mkdir /usr/lib/oracle/11.2/client64/network/admin -p

        # SQLSTATE[HY000]: pdo_oci_handle_factory; ORA-12546: TNS: permission denied (/home/user/php-7.0.6/ext/pdo_oci/)
        super setsebool -P httpd_can_network_connect on
        ;;
      debian*)
        step_done
        super curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-basic_11.2.0.4.0-2_amd64.deb
        super curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-devel_11.2.0.4.0-2_amd64.deb
        super -v+ dpkg -i oracle-instantclient11.2-basic_11.2.0.4.0-2_amd64.deb
        super -v+ dpkg -i oracle-instantclient11.2-devel_11.2.0.4.0-2_amd64.deb
        super mkdir /usr/lib/oracle/11.2/client64/network/admin -p

        # SQLSTATE[HY000]: pdo_oci_handle_factory; ORA-12546: TNS: permission denied (/home/user/php-7.0.6/ext/pdo_oci/)
        super setsebool -P httpd_can_network_connect on
        ;;
      centos*)
        step_done
        super curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
        super curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
        super -v+ $PACKAGE -y localinstall oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
        super -v+ $PACKAGE -y localinstall oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
        super mkdir /usr/lib/oracle/11.2/client64/network/admin -p

        # SQLSTATE[HY000]: pdo_oci_handle_factory; ORA-12546: TNS: permission denied (/home/user/php-7.0.6/ext/pdo_oci/)
        super setsebool -P httpd_can_network_connect on
        ;;
      redhat*)
        step_done
        super curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
        super curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
        super -v+ $PACKAGE -y localinstall oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
        super -v+ $PACKAGE -y localinstall oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
        super mkdir /usr/lib/oracle/11.2/client64/network/admin -p

        # SQLSTATE[HY000]: pdo_oci_handle_factory; ORA-12546: TNS: permission denied (/home/user/php-7.0.6/ext/pdo_oci/)
        super setsebool -P httpd_can_network_connect on
        ;;
      fedora*)
        step_done
        super curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
        super curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
        super -v+ $PACKAGE -y localinstall oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
        super -v+ $PACKAGE -y localinstall oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
        super mkdir /usr/lib/oracle/11.2/client64/network/admin -p

        # SQLSTATE[HY000]: pdo_oci_handle_factory; ORA-12546: TNS: permission denied (/home/user/php-7.0.6/ext/pdo_oci/)
        super setsebool -P httpd_can_network_connect on
        ;;
      *)
        step_fail
        add_report "Cannot detect the current distro."
        fail
        ;;
    esac
  }

  install_oci8() {
    step "Install oci8"
    step_done
    debug "Use 'pecl install oci8' to install for PHP 7."
    debug "Use 'pecl install oci8-2.0.12' to install for PHP 5.2 - PHP 5.6."
    debug "Use 'pecl install oci8-1.4.10' to install for PHP 4.3.9 - PHP 5.1."
    debug "Use 'instantclient,/path/to/instant/client/lib' if you're compiling with Oracle Instant Client [autodetect] : copy and paste instantclient,/usr/lib/oracle/11.2/client64/lib"
    debug "http://www.oracle.com/technetwork/articles/technote-php-instant-084410.html"
    export ORACLE_HOME=/usr/lib/oracle/11.2/client64/
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
      super -v+ pecl install oci8-2.0.12
    else
      debug "Use 'pecl install oci8' to install for PHP 7"
      super -v+ pecl install oci8
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
    case ${DISTRO} in
      ubuntu*)
        step_done
        super -v+ $PACKAGE install php-pear build-essential php7.0-dev #build-dep
        super service apache2 restart
        ;;
      debian*)
        step_done
        super -v+ $PACKAGE install php-pear build-essential php5-dev
        super service apache2 restart
        ;;
      centos*)
        step_done
        super -v+ $PACKAGE install php70u-pear php70u-devel
        super systemctl restart httpd.service
        ;;
      redhat*)
        step_done
        super -v+ $PACKAGE install php70u-pear php70u-devel
        super systemctl restart httpd.service
        ;;
      fedora*)
        step_done
        super -v+ $PACKAGE install php70u-pear php70u-devel
        super systemctl restart httpd.service
        ;;
      *)
        step_fail
        add_report "Cannot detect the current distro."
        fail
        ;;
    esac
  }

  install_pdo_oci8() {
    step "Install pdo oci8"
    step_done
    PHP_VERSION=$(php -v | cut -d' ' -f 2 | head -n 1 | awk -F - '{ print $1 }')
    export ORACLE_HOME=/usr/lib/oracle/11.2/client64/

    #checking for oci.h... configure: error: I'm too dumb to figure out where the include dir is in your instant client install
    #sudo ln -nsf /usr/lib/oracle/12.1/client64/ /usr/lib/oracle/12.1/client
    #sudo ln -nsf /usr/include/oracle/12.1/client64/ /usr/include/oracle/12.1/client
    #sudo ln -s /usr/lib/oracle/12.1/client64/lib/libnnz12.so /usr/lib64/libnnz12.so
    #sudo ln -s /usr/lib/oracle/12.1/client64/lib/libnnz12.so /usr/lib/libnnz12.so
    super ln -nsf /usr/lib/oracle/11.2/client64/ /usr/lib/oracle/11.2/client
    super ln -nsf /usr/include/oracle/11.2/client64/ /usr/include/oracle/11.2/client
    super ln -s /usr/lib/oracle/11.2/client64/lib/libnnz11.so /usr/lib/libnnz11.so

    cd ~
    curl -L http://br2.php.net/get/php-$PHP_VERSION.tar.bz2/from/this/mirror> php-$PHP_VERSION.tar.bz2
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
    else
      super bash -c 'echo -e "; Enable pdo_oci extension module\nextension=pdo_oci.so" > /etc/php.d/20-pdo_oci.ini'
    fi
    php -i | grep oci
    super bash -c 'echo -e "<?php phpinfo(); " > $HTTPD_ROOT/phpinfo.php'
    ip addr show | grep "inet 192" | awk -F/ '{print $1}' | sed -e "s/inet//g"
  }

  # php version 7.0 (recomended)
  check_php_version() {
      return verlte php -v 7.0 && echo "yes" || echo "no"
  }

  version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

  verlte() {
      [  "$1" = "`echo -e "$1\n$2" | sort -n | head -n1`" ]
  }

  verlt() {
      [ "$1" = "$2" ] && return 1 || verlte $1 $2
  }

  # git version 1.8.5.2 (Apple Git-48)
  check_git_version() {
      return verlte git --version 1.0 && echo "yes" || echo "no"
  }

  check_git_installation() {
    step "Checking for Git installation"
    if command_exists git; then
      step_done
      debug "Git detected"
      check_git
      check_git_installation
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
    username=$(git config user.name)
    if [ -z "$username" ]; then
      read -p "Informe o nome do usuário do bitbucket." username
      git config --global user.name "$username"
    else
      debug "Git user.name: $username"
    fi
    usermail=$(git config user.email)
    if [ -z "$usermail" ]; then
      read -p "Informe o email do usuário do bitbucket." useremail
      git config --global user.email $useremail
    else
      debug "Git user.mail: $useremail"
    fi
  }

  check_composer_installation() {
    step "Checking Composer installation"
    step_done

    fetch_cmd=$(curl_or_wget)
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
      curl -O https://getcomposer.org/composer.phar
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
    case ${DISTRO} in
      ubuntu*)
        step_done
        super -v+ $PACKAGE install php7.0-mbstring
        super service apache2 restart
        ;;
      debian*)
        step_done
        super -v+ $PACKAGE install php5-mbstring
        super service apache2 restart
        ;;
      centos*)
        step_done
        super -v+ $PACKAGE install php70u-mbstring
        super systemctl restart httpd.service
        ;;
      redhat*)
        step_done
        super -v+ $PACKAGE install php70u-mbstring
        super systemctl restart httpd.service
        ;;
      fedora*)
        step_done
        super -v+ $PACKAGE install php70u-mbstring
        super systemctl restart httpd.service
        ;;
      *)
        step_fail
        add_report "Cannot detect the current distro."
        fail
        ;;
    esac
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
    case ${DISTRO} in
      ubuntu*)
        step_done
        super -v+ $PACKAGE install php7.0-zip
        super service apache2 restart
        ;;
      debian*)
        step_done
        super -v+ $PACKAGE install php5-zip
        super service apache2 restart
        ;;
      centos*)
        step_done
        super -v+ $PACKAGE install php70u-zip
        super systemctl restart httpd.service
        ;;
      redhat*)
        step_done
        super -v+ $PACKAGE install php70u-zip
        super systemctl restart httpd.service
        ;;
      fedora*)
        step_done
        super -v+ $PACKAGE install php70u-zip
        super systemctl restart httpd.service
        ;;
      *)
        step_fail
        add_report "Cannot detect the current distro."
        fail
        ;;
    esac
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

  install_jq() {
    step "Verifying that jq is installed"
    step_done
    if command_exists jq; then
      debug "jq is installed, skipping jq installation."
      debug $(jq --version)
    else
      debug "Installing jq"
      super -v+ ${PACKAGE} -y install jq
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

  install_sed() {
    step "Verifying that sed is installed"
    step_done
    if command_exists sed; then
      debug "sed already installed"
      #debug $(sed --version)
    else
      debug "Installing sed"
      super ${PACKAGE} -y install sed
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

} # This ensures the entire script is downloaded
