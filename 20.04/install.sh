#!/bin/bash
set -e

CURRENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${CURRENT_DIR}/../common/common.sh

[ $(id -u) != "0" ] && { ansi -n --bold --bg-red "vui long dung tai khoan root"; exit 1; }

MYSQL_ROOT_PASSWORD=`random_string`

function init_system {
    export LC_ALL="en_US.UTF-8"
    echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
    locale-gen en_US.UTF-8
    locale-gen zh_CN.UTF-8

    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

    apt-get update
    apt-get install -y software-properties-common

    init_alias
}

function init_alias {
    alias sudowww > /dev/null 2>&1 || {
        echo "alias sudowww='sudo -H -u ${WWW_USER} sh -c'" >> ~/.bash_aliases
    }
}

function install_basic_softwares {
    apt-get install -y curl git build-essential unzip supervisor
}

function install_node_yarn {
    apt-get install -y nodejs yarn
    sudo -H -u ${WWW_USER} sh -c 'cd ~ && yarn config set registry https://registry.npm.taobao.org'
}

function install_php {
    apt-get install -y php7.4-bcmath php7.4-cli php7.4-curl php7.4-fpm php7.4-gd php7.4-mbstring php7.4-mysql php7.4-opcache php7.4-pgsql php7.4-readline php7.4-xml php7.4-zip php7.4-sqlite3 php7.4-redis
}

function install_others {
    apt-get remove -y apache2
    debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"
    apt-get install -y nginx mysql-server redis-server memcached beanstalkd sqlite3
    chown -R ${WWW_USER}.${WWW_USER_GROUP} /var/www/
    systemctl enable nginx.service
}

function install_composer {
    curl https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
    chmod +x /usr/local/bin/composer
    sudo -H -u ${WWW_USER} sh -c  'cd ~ && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/'
}

call_function init_system "khoi tao" ${LOG_PATH}
call_function install_basic_softwares "cai dat co ban" ${LOG_PATH}
call_function install_php "cai dat PHP" ${LOG_PATH}
call_function install_others "cai dat Mysql / Nginx / Redis / Memcached / Beanstalkd / Sqlite3" ${LOG_PATH}
call_function install_node_yarn "cai dat Nodejs / Yarn" ${LOG_PATH}
call_function install_composer "cai dat Composer" ${LOG_PATH}

ansi --green --bold -n "cai dat"
ansi --green --bold "Mysql root pass："; ansi -n --bold --bg-yellow --black ${MYSQL_ROOT_PASSWORD}
ansi --green --bold -n "请手动执行 source ~/.bash_aliases 使 alias 指令生效。"
