#!/bin/bash
# Copyright 2020 crfactura.com
# AVISO IMPORTANTE!!! (WARNING!!!)
# ASEGURESE DE TENER UN SERVIDOR / VPS CON AL MENOS > 2GB DE RAM
# You must to have at least > 2GB of RAM
# Ubuntu 18.04, 19, 20.04 LTS tested
# v2.2
# Last updated: 17-10-2020

OS_NAME=$(lsb_release -cs)
usuario=$USER
DIR_PATH=$(pwd)
VCODE=12
VERSION=12.0
PORT=8069
DEPTH=1
PROJECT_NAME=odoo$VCODE
PATHBASE=/opt/$PROJECT_NAME
PATH_LOG=$PATHBASE/log
PATHREPOS=$PATHBASE/extra-addons
PATHREPOS_OCA=$PATHREPOS/oca

if [[ $OS_NAME == "disco" ]];

then
	echo $OS_NAME
	OS_NAME="bionic"

fi

if [[ $OS_NAME == "focal" ]];

then
	echo $OS_NAME
	OS_NAME="bionic"

fi

wk64="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1."$OS_NAME"_amd64.deb"
wk32="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1."$OS_NAME"_i386.deb"

sudo adduser --system --quiet --shell=/bin/bash --home=$PATHBASE --gecos 'ODOO' --group $usuario
sudo adduser $usuario sudo

# add universe repository & update (Fix error download libraries)
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y git

# Update and install Postgresql
sudo apt-get install postgresql -y
sudo su - postgres -c "createuser -s $usuario"

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

# FIX wkhtml* dependencie Ubuntu Server 18.04
sudo apt-get -y install libxrender1

# Install nodejs and less
sudo apt-get install -y npm node-less
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less

# Download & install WKHTMLTOPDF
sudo wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb $PATHBASE

if [[ "`getconf LONG_BIT`" == "32" ]];

then
	sudo wget $wk32
else
	sudo wget $wk64
fi

sudo dpkg -i --force-depends $PATHBASE/wkhtmltox_0.12.5-1*.deb
sudo apt-get -f -y install
sudo ln -s /usr/local/bin/wkhtml* /usr/bin
sudo rm $PATHBASE/wkhtmltox*.deb
sudo apt-get -f -y install

# install python requirements file (Odoo)
sudo chown -R $usuario: $PATHBASE
sudo sed -i "s/psycopg2==2.7.3.1; sys_platform != 'win32'/psycopg2==2.7.3.1; sys_platform != 'win32' and python_version < '3.8'/g" $PATHBASE/odoo/requirements.txt
sudo sed -i "s/psycopg2==2.8.3; sys_platform == 'win32'/psycopg2==2.8.3; sys_platform == 'win32' or python_version >= '3.8'/g" $PATHBASE/odoo/requirements.txt
sudo sed -i '/libsass/d' $PATHBASE/odoo/requirements.txt
sudo pip3 install libsass vobject qrcode num2words
sudo pip3 install -r $PATHBASE/odoo/requirements.txt

cd $DIR_PATH

sudo mkdir $PATHBASE/config
sudo rm $PATHBASE/config/odoo$VCODE.conf
sudo touch $PATHBASE/config/odoo$VCODE.conf
echo "
[options]
; This is the password that allows database operations:
;admin_passwd =
db_host = False
db_port = False
;db_user =
;db_password =
data_dir = $PATHBASE/data
logfile= $PATH_LOG/odoo$VCODE.log

############# addons path ######################################

addons_path =
    $PATHREPOS,
    $PATHREPOS/backend_theme,
    $PATHREPOS_OCA/web,
    $PATHBASE/odoo/addons

#################################################################

xmlrpc_port = $PORT
longpolloing_port = 8072
;dbfilter = ^%d$
;dbfilter = .*
;proxy_mode = True
logrotate = True
;workers = 5
limit_time_real = 6000
limit_time_cpu = 6000
limit_memory_soft = 3355443200
limit_memory_hard = 4026531840
" | sudo tee --append $PATHBASE/config/odoo$VCODE.conf

sudo rm /etc/systemd/system/odoo$VCODE.service
sudo touch /etc/systemd/system/odoo$VCODE.service
sudo chmod +x /etc/systemd/system/odoo$VCODE.service
echo "
[Unit]
Description=Odoo$VCODE
After=postgresql.service

[Service]
Type=simple
User=$usuario
ExecStart=$PATHBASE/odoo/odoo-bin --config $PATHBASE/config/odoo$VCODE.conf

[Install]
WantedBy=multi-user.target
" | sudo tee --append /etc/systemd/system/odoo$VCODE.service
sudo systemctl daemon-reload
sudo systemctl enable odoo$VCODE.service
sudo systemctl start odoo$VCODE

sudo chown -R $usuario: $PATHBASE

echo "Odoo $VERSION Installation has finished!! ;) by crfactura.com"
IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
echo "You can access from: http://$IP:$PORT  or http://localhost:$PORT"
