#!/bin/bash

distro="yum"
packages="rpm -qa"
MYSQL_ROOT_PASSWORD=""

verlte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -n | head -n1`" ]
}

verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}

# git version 1.8.5.2 (Apple Git-48)
check() {
    return verlte git --version 1.0 && echo "yes" || echo "no"
}

update() {
  echo "Atualizando servidor..."
  sudo $distro -y update
}

gcc_install() {
  echo "Verificando se o gcc esta instalado"
  GCC=$($packages | grep ^gcc)
  if [ -z "GCC" ]; then
    echo "Instalando o gcc"
    sudo $distro -y install gcc
  else
    echo "gcc já instalado $GCC"
  fi
}

curl_install() {
  echo "Verificando se o curl esta instalado"
  CURL=$($packages | grep ^curl)
  if [ -z "$CURL" ]; then
    echo "Instalando o curl"
    sudo $distro -y install curl
  else
    echo "curl já instalado $CURL"
  fi
}

git_install() {
  echo "Verificando se o git esta instalado"
  GIT=$($packages | grep ^git)
  if [ -z "$GIT" ]; then
    echo "Instalando o git"
    sudo $distro -y install git
  else
    echo "git já instalado $GIT"
  fi
  if [ check == "yes" ]; then
    echo "Git não instalado ou version inferior a 1.0"
    echo "Instalando o git"
    sudo $distro -y install git
  fi
}

httpd_install() {
  sudo $distro -y install httpd
  systemctl start httpd.service
  systemctl enable httpd.service
}

mysql_install() {
  sudo $distro -y install mariadb-server mariadb
  systemctl start mariadb
  systemctl enable mariadb.service

  #echo "Senha para o banco de dados:"
  #echo $MYSQL_ROOT_PASSWORD
  #read -p "Salvou a senha em algum lugar seguro ?[Y/n]: " opcao
  #case $opcao in
  #  [n])
  #   echo "Guarde esse senha!"
  #   echo $MYSQL_ROOT_PASSWORD
  #  ;;
  #esac

  mysql_secure_installation

  #expect_install
  #SECURE_MYSQL=$(expect -c "
  #set timeout 10
  #spawn mysql_secure_installation
  #expect \"Enter current password for root:\"
  #send \"$MYSQL_ROOT_PASSWORD\r\"
  #expect \"Would you like to setup VALIDATE PASSWORD plugin?\"
  #send \"n\r\"
  #expect \"Change the password for root ?\"
  #send \"n\r\"
  #expect \"Remove anonymous users?\"
  #send \"y\r\"
  #expect \"Disallow root login remotely?\"
  #send \"y\r\"
  #expect \"Remove test database and access to it?\"
  #send \"y\r\"
  #expect \"Reload privilege tables now?\"
  #send \"y\r\"
  #expect eof
  #")
  #echo "$SECURE_MYSQL"
}

expect_install() {
  echo "Verificando se o expect esta instalado"
  EXPECT=$($packages | grep ^expect)
  if [ -z "$EXPECT" ]; then
    echo "Instalando o expect"
    sudo $distro -y install expect
  fi
}

centos_install_epel(){
  # CentOS has epel release in the extras repo
  sudo $distro -y install epel-release
  import_epel_key
}

rhel_install_epel(){
  case ${RELEASE} in
    5*) el5_download_install https://dl.fedoraproject.org/pub/epel/epel-release-latest-5.noarch.rpm;;
    6*) sudo $distro -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm;;
    7*) sudo $distro -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm;;
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
    6*) sudo $distro -y install https://centos6.iuscommunity.org/ius-release.rpm;;
    7*) sudo $distro -y install https://centos7.iuscommunity.org/ius-release.rpm;;
  esac
  import_ius_key
}

rhel_install_ius(){
  case ${RELEASE} in
    5*) el5_download_install https://rhel5.iuscommunity.org/ius-release.rpm;;
    6*) yum -y install https://rhel6.iuscommunity.org/ius-release.rpm;;
    7*) yum -y install https://rhel7.iuscommunity.org/ius-release.rpm;;
  esac
  import_ius_key
}

el5_download_install(){
  wget -O /tmp/release.rpm ${1}
  sudo $distro -y localinstall /tmp/release.rpm
  rm -f /tmp/release.rpm
}

import_ius_key(){
  rpm --import /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY
}

php_install() {
  sudo $distro -y install php70u mod_php70u php70u-common php70u-cli php70u-mysqlnd php70u-mcrypt php70u-pear php70u-devel php70u-json php70u-mbstring
  bash -c 'echo -e "<IfModule mod_rewrite.c>\n\tLoadModule rewrite_module modules/mod_rewrite.so\n</IfModule>" >> /etc/httpd/conf.modules.d/10-php.conf'
  systemctl restart httpd.service
}

oracle_instant() {
  curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
  curl -O https://s3-sa-east-1.amazonaws.com/ramon-barros/downloads/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
  sudo $distro -y localinstall oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
  sudo $distro -y localinstall oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
  mkdir /usr/lib/oracle/11.2/client64/network/admin -p

  # SQLSTATE[HY000]: pdo_oci_handle_factory; ORA-12546: TNS: permission denied (/home/user/php-7.0.6/ext/pdo_oci/)
  setsebool -P httpd_can_network_connect on
}

oci8_install() {
  pecl install oci8
  bash -c 'echo -e "; Enable oci8 extension module\nextension=oci8.so" > /etc/php.d/20-oci8.ini'
}

pdo_oci_install() {
  export ORACLE_HOME=/usr/lib/oracle/11.2/client64/
  cd ~
  curl -O rsb.cc/download/php-7.0.6.tar.bz2
  tar -jxvf php-7.0.6.tar.bz2
  cd php-7.0.6/
  cd ext/
  cd pdo_oci/
  phpize
  ./configure --with-pdo-oci=instantclient,/usr,11.2
  make
  make install
  bash -c 'echo -e "; Enable pdo_oci extension module\nextension=pdo_oci.so" > /etc/php.d/20-pdo_oci.ini'
  php -i | grep oci
  bash -c 'echo -e "<?php phpinfo(); " > /var/www/html/phpinfo.php'
  ip addr show | grep "inet 192" | awk -F/ '{print $1}' | sed -e "s/inet//g"
}

if [[ -e /etc/redhat-release ]]; then
  RELEASE_RPM=$(rpm -qf /etc/redhat-release)
  RELEASE=$(rpm -q --qf '%{VERSION}' ${RELEASE_RPM})
  case ${RELEASE_RPM} in
    centos*)
      echo "detected CentOS ${RELEASE}"
      distro="yum"
      packages="rpm -qa"
      centos_install_epel
      centos_install_ius
      ;;
    redhat*)
      echo "detected RHEL ${RELEASE}"
      distro="yum"
      packages="rpm -qa"
      rhel_install_epel
      rhel_install_ius
      ;;
    *)
      echo "unknown EL clone"
      exit 1
      ;;
  esac
  update
  gcc_install
  curl_install
  git_install
  httpd_install
  mysql_install
  php_install
  oracle_instant
  oci8_install
  pdo_oci_install

else
  echo "not an EL distro"
  exit 1
fi
