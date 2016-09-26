#!/bin/bash

{ # This ensures the entire script is downloaded

VERSION="0.1.0"
ROOT_UID=0
ARRAY_SEPARATOR="#"
OS=""
OS_VERSION=""
PLATFORM=""
ARCH=""
PROJECT=""
PACKAGE=""
UPDATE="false"
HTTPD_ROOT=""
SERVER=""

main() {
  welcome
  check_plataform
  update_plataform
  check_gcc
  check_grep
  menu
  success
}

welcome() {
  GREEN="$(tput setaf 2)"
  printf '%s' "$GREEN"
  printf '%s\n' '.__                 __         .__  .__                          .__     '
  printf '%s\n' '|__| ____   _______/  |______  |  | |  |   ___________      _____|  |__  '
  printf '%s\n' '|  |/    \ /  ___/\   __\__  \ |  | |  | _/ __ \_  __ \    /  ___/  |  \ '
  printf '%s\n' '|  |   |  \\___ \  |  |  / __ \|  |_|  |_\  ___/|  | \/    \___ \|   Y  \'
  printf '%s\n' '|__|___|  /____  > |__| (____  /____/____/\___  >__|    /\/____  >___|  /'
  printf '%s\n' '        \/     \/            \/               \/        \/     \/     \/ '
  printf '%s\n' 'Please look over the ~/.installerrc file to select plugins and options.'
  printf '%s\n'
  printf '%s\n' 'p.s. Follow us at https://twitter.com/rbarros.'
  printf '%s\n' '------------------------------------------------------------------'
}

check_plataform() {
  step "Checking platform"

  # Detecting PLATFORM and ARCH
  UNAME="$(uname -a)"
  case "$UNAME" in
    Linux\ *)   PLATFORM=linux ;;
    Darwin\ *)  PLATFORM=darwin ;;
    SunOS\ *)   PLATFORM=sunos ;;
    FreeBSD\ *) PLATFORM=freebsd ;;
  esac
  case "$UNAME" in
    *x86_64*) ARCH=x64 ;;
    *i*86*)   ARCH=x86 ;;
    *armv6l*) ARCH=arm-pi ;;
  esac

  if [ -z $PLATFORM ] || [ -z $ARCH ]; then
    step_fail
    add_report "Cannot detect the current platform."
    fail
  fi

  step_done
  debug "Detected platform: $PLATFORM, $ARCH"

  if [ "$PLATFORM" = "linux" ]; then
    check_distro
  else
    ""
  fi
}

check_distro() {
  step "Checking distro platform"
  # Detecting OS and OS_VERSION
  . /etc/os-release
  OS=$ID
  OS_VERSION=$VERSION_ID
  step_done
  debug "Detected distribution: $OS, $OS_VERSION"

  step "Get package distro"
  case ${OS} in
    ubuntu*)
      step_done
      #debug "detected Ubuntu ${OS_VERSION}"
      PACKAGE="apt-get"
      ;;
    debian*)
      step_done
      #debug "detected Debian ${OS_VERSION}"
      PACKAGE="apt-get"
      ;;
    centos*)
      step_done
      #debug "detected CentOS ${OS_VERSION}"
      PACKAGE="yum"
      ;;
    redhat*)
      step_done
      #debug "detected RHEL ${OS_VERSION}"
      PACKAGE="yum"
      ;;
    fedora*)
      step_done
      #debug "detected Fedora ${OS_VERSION}"
      PACKAGE="yum"
      ;;
    *)
      step_fail
      add_report "Cannot detect the current distro."
      fail
      ;;
  esac
}

update_plataform() {
  STOP=0
  trap abort_update INT

  debug "Will be update within 10 seconds."
  debug "To prevent its update, just press CTRL+C now."
  counter

  if [ "$STOP" = 0 ]; then
    step_wait "Update $OS, $OS_VERSION ..."
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
     debug "9 - Sair"
     debug ""
     debug "Enter the desired option:"
     read p
     case $p in
     9) break;;
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

download() {
  # Download plugin
  echo -e "|   Downloading plugin.sh to /etc/installersh\n|\n|   + $(wget -nv -o /dev/stdout -O /etc/installersh/nq-agent.sh --no-check-certificate https://raw.github.com/rbarros/installer.sh/master/installer.sh)"
}

install_lamp() {
  step "Install LAMP"
  step_done
  check_webserver
  check_php
  check_mysql
}

check_webserver() {
  step "Verifying that webserver is installed"
  step_done

  if command_exists apache2; then
    SERVER="apache2"
    HTTPD_ROOT="/var/www/html"
  elif command_exists nginx; then
    SERVER="nginx"
    HTTPD_ROOT="/usr/share/nginx/html"
  fi
  if [ -d "$HTTPD_ROOT" ]; then
    debug $($SERVER -v)
    debug "ok [$HTTPD_ROOT]"
  else
    install_httpd
  fi
}

install_httpd() {
  step "Install webserver"
  case ${OS} in
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
  case ${OS} in
    ubuntu*)
      step_done
      debug "Install php ubuntu"
      super -v+ $PACKAGE install php7.0 php7.0-dev php7.0-mcrypt php7.0-common php7.0-curl php7.0-cli php7.0-gd php7.0-json php7.0-xml libapache2-mod-php7.0 php7.0-zip php-pear build-essential build-dep
      super -v+ a2enmod rewrite
      ;;
    debian*)
      step_done
      debug "Install php debian"
      #super -v+ $PACKAGE install php7.0 php7.0-dev php7.0-mcrypt php7.0-common php7.0-curl php7.0-cli php7.0-gd php7.0-json php7.0-xml libapache2-mod-php7.0 php7.0-zip php-pear build-essential build-dep
      super -v+ $PACKAGE install php5 php5-dev php5-mcrypt php5-common php5-curl php5-cli php5-gd php5-json php5-xml libapache2-mod-php5 libphp-pclzip php-pear build-essential build-dep
      super -v+ a2enmod rewrite
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
  case ${OS} in
    ubuntu*)
      step_done
      super -v+ $PACKAGE install mariadb-server mariadb-client
      ;;
    debian*)
      step_done
      super -v+ $PACKAGE install mariadb-server mariadb-client
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
  case ${OS} in
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

  if command_exists pecl; then
    debug "pecl is installed, skipping pecl installation."
  else
    install_pear
  fi
}

install_pear() {
  step "Install php"
  case ${OS} in
    ubuntu*)
      step_done
      super -v+ $PACKAGE install php-pear build-essential build-dep
      super -v+ a2enmod rewrite
      ;;
    debian*)
      step_done
      super -v+ $PACKAGE install php-pear build-essential build-dep
      super -v+ a2enmod rewrite
      ;;
    centos*)
      step_done
      super -v+ $PACKAGE install php70u-pear
      super systemctl restart httpd.service
      ;;
    redhat*)
      step_done
      super -v+ $PACKAGE install php70u-pear
      super systemctl restart httpd.service
      ;;
    fedora*)
      step_done
      super -v+ $PACKAGE install php70u-pear
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
  cd ~
  curl -L -O http://br2.php.net/get/php-$PHP_VERSION.tar.bz2/from/this/mirror> php-$PHP_VERSION.tar.bz2
  tar -jxvf php-$PHP_VERSION.tar.bz2
  cd $PHP_VERSION/
  cd ext/
  cd pdo_oci/
  phpize
  ./configure --with-pdo-oci=instantclient,/usr,11.2
  make
  make install
  bash -c 'echo -e "; Enable pdo_oci extension module\nextension=pdo_oci.so" > /etc/php.d/20-pdo_oci.ini'
  php -i | grep oci
  bash -c 'echo -e "<?php phpinfo(); " > $HTTPD_ROOT/phpinfo.php'
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
  fi
}

create_project() {
  step "Create a project installer"
  step_done
  htdocs=""
  read -p "What the directory apache/nginx [$HTTPD_ROOT] ? " htdocs
  if [ "$htdocs" ]; then
    HTTPD_ROOT=$htdocs
  fi
  read -p "What is the project name ? " PROJECT
  if [ -z "$PROJECT" ]; then
    debug "The project name is required."
    create_project
  fi
  if [ ! -d "$PROJECT" ]; then
    cd $HTTPD_ROOT
    super mkdir "$HTTPD_ROOT/$PROJECT"
  else
    debug "The project [$PROJECT] already exists!"
    UPDATE="true"
    cd "$HTTPD_ROOT/$PROJECT"
  fi
}

alter_composer() {
  step "Changing the project composer"
  step_done
  install_jq
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
    if echo "create database $DB_DATABASE charset utf8;" | mysql -u $DB_USERNAME -p$DB_PASSWORD; then    # allowed to fail
        step_done
        debug "Database $DB_DATABASE created"
    else
        step_fail
        add_report "Database $DB_DATABASE not created"
        fail
    fi

    if [ ! -f ".env.bkp" ]; then
        debug "Backup .env"
        cp .env .env.bkp
        sed -i -e "s/\(DB_HOST=\).*/\1$DB_HOST/" \
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
  if [ -d "$HTTPD_ROOT/$PROJECT" ]; then
    cd "$HTTPD_ROOT/$PROJECT"
    if [ -d "logs" ]; then
      super chmod -R 777 "logs"
    fi
    if [ -d "public/arquivos" ]; then
      super chmod -R 777 "public/arquivos"
    fi
    if [ -d "storage" ]; then
      super chmod -R 777 "storage"
    fi
  fi
}

config() {
  step "Project Setup"
  step_done
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

counter() {
  for i in {0..10}; do
    echo -ne "$i"'\r';
    sleep 1;
    if [ "$STOP" = 1 ]; then
      break
    fi
  done; echo
}

comfirm() {
    text="$1 [y/N]"
    read -r -p "$text " response
    case $response in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}


curl_or_wget() {
  CURL_BIN="curl"; WGET_BIN="wget"
  if command_exists ${CURL_BIN}; then
    echo "${CURL_BIN} -sSL"
  elif command_exists ${WGET_BIN}; then
    echo "${WGET_BIN} -nv -O- -t 2 -T 10"
  fi
}

command_exists() {
  command -v "${@}" > /dev/null 2>&1
}

run_super() {
  if [ $(id -ru) != $ROOT_UID ]; then
    sudo "${@}"
  else
    "${@}"
  fi
}

super() {
  if [ "$1" = "-v" ]; then
    shift
    debug "${@}"
    run_super "${@}" > /dev/null
  elif echo "$1" | grep -P "\-v+"; then
    shift
    debug "${@}"
    run_super "${@}"
  else
    debug "${@}"
    run_super "${@}" > /dev/null 2>&1
  fi
}

atput() {
  [ -z "$TERM" ] && return 0
  eval "tput $@"
}

escape() {
  echo "$@" | sed "
    s/%{red}/$(atput setaf 1)/g;
    s/%{green}/$(atput setaf 2)/g;
    s/%{yellow}/$(atput setaf 3)/g;
    s/%{blue}/$(atput setaf 4)/g;
    s/%{magenta}/$(atput setaf 5)/g;
    s/%{cyan}/$(atput setaf 6)/g;
    s/%{white}/$(atput setaf 7)/g;
    s/%{reset}/$(atput sgr0)/g;
    s/%{[a-z]*}//g;
  "
}

log() {
  level="$1"; shift
  color=; stderr=; indentation=; tag=; opts=

  case "${level}" in
  debug)
    color="%{blue}"
    stderr=true
    indentation="  "
    ;;
  info)
    color="%{green}"
    ;;
  warn)
    color="%{yellow}"
    tag=" [WARN] "
    stderr=true
    ;;
  err)
    color="%{red}"
    tag=" [ERROR]"
  esac

  if [ "$1" = "-n" ]; then
    opts="-n"
    shift
  fi

  if [ "$1" = "-e" ]; then
    opts="$opts -e"
    shift
  fi

  if [ -z ${stderr} ]; then
    echo $opts "$(escape "${color}[installer]${tag}%{reset} ${indentation}$@")"
  else
    echo $opts "$(escape "${color}[installer]${tag}%{reset} ${indentation}$@")" 1>&2
  fi
}

step() {
  printf "$( log info $@ | sed -e :a -e 's/^.\{1,72\}$/&./;ta' )"
}

step_wait() {
  if [ ! -z "$@" ]; then
    STEP_WAIT="${@}"
    step "${STEP_WAIT}"
  fi
  echo "$(escape "%{blue}[ WAIT ]%{reset}")"
}

check_wait() {
  if [ ! -z "${STEP_WAIT}" ]; then
    step "${STEP_WAIT}"
    STEP_WAIT=
  fi
}

step_done() { check_wait && echo "$(escape "%{green}[ DONE ]%{reset}")"; }

step_warn() { check_wait && echo "$(escape "%{yellow}[ FAIL ]%{reset}")"; }

step_fail() { check_wait && echo "$(escape "%{red}[ FAIL ]%{reset}")"; }

debug() { log debug $@; }

info() { log info $@; }

warn() { log warn $@; }

err() { log err $@; }

add_report() {
  if [ -z "$report" ]; then
    report="${@}"
  else
    report="${report}${ARRAY_SEPARATOR}${@}"
  fi
}

fail() {
  echo ""
  IFS="${ARRAY_SEPARATOR}"
  add_report "Failed to install installer."
  for report_message in $report; do
    err "$report_message"
  done
  exit 1
}

success() {
  echo ""
  IFS="${ARRAY_SEPARATOR}"
  if [ "${UPDATE}" = "true" ]; then
    add_report "installer has been successfully updated."
  else
    add_report "installer has been successfully installed."
  fi
  add_report '------------------------------------------------------------------'
  for report_message in $report; do
    info "$report_message"
  done
  exit 0
}

main "${@}"

} # This ensures the entire script is downloaded
