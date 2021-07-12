#!/bin/bash
# Copyright 2020 crfactura.com
# AVISO IMPORTANTE!!! (WARNING!!!)
# ASEGURESE DE TENER UN SERVIDOR / VPS CON AL MENOS > 2GB DE RAM
# You must to have at least > 2GB of RAM
# Ubuntu 18.04, 20.04 LTS tested
# Debian 10
# v2.2
# Last updated: 2021-07-12
# Usage: ./odoo12.sh 12 name port
# To create a service called odoo12name running on port

OS_NAME=$(lsb_release -cs)
DIR_PATH=$(pwd)
VCODE=${1:-12}
VERSION=${VCODE}.0
PORT=${3:-8069}
PORT_LONG=$((PORT+100))
DEPTH=1
PROJECT_NAME=odoo$VCODE${2:-}
PATHBASE=/opt/$PROJECT_NAME
ODOO_CONF=$PATHBASE/config/odoo.conf
PATH_LOG=$PATHBASE/log
PATHREPOS=$PATHBASE/extra-addons
PATHREPOS_OCA=$PATHREPOS/oca
ADMIN_PASS=$( cat /dev/urandom | tr -cd "[:alnum:]" | head -c 22 )

sudo adduser --system --quiet --shell=/bin/sh --home=$PATHBASE --gecos "$PROJECT_NAME" --group $PROJECT_NAME

#sudo adduser $usuario sudo

# add universe repository & update (Fix error download libraries), only for Ubuntu
test Ubuntu = `lsb_release -is` && sudo add-apt-repository universe
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y git

# Update and install Postgresql
sudo apt-get install postgresql -y
sudo su - postgres -c "createuser -s $PROJECT_NAME"

sudo mkdir $PATHBASE
sudo mkdir $PATHREPOS
sudo mkdir $PATHREPOS_OCA
sudo mkdir $PATH_LOG
cd $PATHBASE

# Download Odoo from git source
sudo git clone https://github.com/odoo/odoo.git -b $VERSION --depth $DEPTH $PATHBASE/odoo
sudo git clone https://github.com/odooerpdevelopers/backend_theme.git -b $VERSION --depth $DEPTH $PATHREPOS/backend_theme
sudo git clone https://github.com/oca/web.git -b $VERSION --depth $DEPTH $PATHREPOS_OCA/web


# Install python3 and dependencies for Odoo
sudo apt-get -y install gcc python3-dev libxml2-dev libxslt1-dev \
 libevent-dev libsasl2-dev libldap2-dev libpq-dev \
 libpng-dev libjpeg-dev xfonts-base xfonts-75dpi

sudo apt-get -y install python3 python3-pip python3-setuptools htop unzip

# Install nodejs and less
sudo apt-get install -y npm node-less
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less

# Download & install WKHTMLTOPDF
WK_VER=0.12.5
WK_REL=${WK_VER}-1
WK_DEB=wkhtmltox_0.12.5-1.${OS_NAME}_$(dpkg --print-architecture).deb

sudo wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/$WK_VER/$WK_DEB

# Install dependencies:
apt-get install -y $(dpkg -I $WK_DEB | grep Depends | cut -d: -f2 | sed 's/,//g')

sudo dpkg -i $WK_DEB
sudo apt-get -f -y install
# ¿Necesario?
sudo ln -s /usr/local/bin/wkhtml* /usr/bin
sudo rm $WK_DEB

# install python requirements file (Odoo)
sudo chown -R $PROJECT_NAME: $PATHBASE
sudo sed -i "s/psycopg2==2.7.3.1; sys_platform != 'win32'/psycopg2==2.7.3.1; sys_platform != 'win32' and python_version < '3.8'/g" $PATHBASE/odoo/requirements.txt
sudo sed -i "s/psycopg2==2.8.3; sys_platform == 'win32'/psycopg2==2.8.3; sys_platform == 'win32' or python_version >= '3.8'/g" $PATHBASE/odoo/requirements.txt
sudo sed -i '/libsass/d' $PATHBASE/odoo/requirements.txt
sudo pip3 install libsass vobject qrcode num2words
sudo pip3 install -r $PATHBASE/odoo/requirements.txt

cd $DIR_PATH

sudo mkdir $PATHBASE/config
sudo rm -f $ODOO_CONF
sudo touch $ODOO_CONF
echo "
[options]
; This is the password that allows database operations:
admin_passwd = $ADMIN_PASS
db_host = False
db_port = False
;db_user =
;db_password =
data_dir = $PATHBASE/data
logfile= $PATH_LOG/odoo.log

############# addons path ######################################

addons_path =
    $PATHREPOS,
    $PATHREPOS/backend_theme,
    $PATHREPOS_OCA/web,
    $PATHBASE/odoo/addons

#################################################################

xmlrpc_port = $PORT
longpolloing_port = $PORT_LONG
;dbfilter = ^%d$
;dbfilter = .*
;proxy_mode = True
logrotate = True
;workers = 5
limit_time_real = 6000
limit_time_cpu = 6000
limit_memory_soft = 3355443200
limit_memory_hard = 4026531840
;proxy_mode = True
" | sudo tee --append $ODOO_CONF

sudo chown -R $PROJECT_NAME: $PATHBASE

sudo rm -f /etc/systemd/system/$PROJECT_NAME.service
sudo touch /etc/systemd/system/$PROJECT_NAME.service
sudo chmod +x /etc/systemd/system/$PROJECT_NAME.service
echo "
[Unit]
Description=Odoo instance: $PROJECT_NAME
After=postgresql.service

[Service]
Type=simple
User=$PROJECT_NAME
ExecStart=$PATHBASE/odoo/odoo-bin --config $ODOO_CONF

[Install]
WantedBy=multi-user.target
" | sudo tee --append /etc/systemd/system/$PROJECT_NAME.service
sudo systemctl daemon-reload
sudo systemctl enable $PROJECT_NAME.service
sudo systemctl start $PROJECT_NAME


echo "Odoo instance $PROJECT_NAME on port $PORT has finished! Special thanks to crfactura.com" >&2
IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
echo "You can access it at: http://$IP:$PORT  or http://localhost:$PORT"
echo "Admin pass: $ADMIN_PASS ( stored in $ODOO_CONF )"
