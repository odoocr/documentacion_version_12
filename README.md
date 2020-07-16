# odoodeploy

(Copyright 2020 - crfactura.com)

Odoo Deploy Tools

## odoo.service

This file is used from odooxx.sh for to install Odoo Start Service

## odooxx.sh
This script install Odoo in Your Server

## Requirements

* Tested on Ubuntu Server / Desktop 16.04LTS to 20.04.LTS
* This script should works on Debian Also (no tested).

## Enviroments

* Ubuntu Desktop 18.04 LTS to 20.04 LTS (Local PC)
* Ubuntu Server 18.04 LTS to 20.04 LTS (VPS)

    * OVH
    * Google Cloud
    * Amazon AWS
    * Digital Ocean
    * Hetzner
    * CONTABO

## How to install

### Ubuntu Desktop

1. Copy this Folder in your System (Desktop, Downloads, etc.)
2. Go to Directory and open a terminal
3. chmod +x  *.sh
4. Execute: ./odooxx.sh
5. Enjoy

### Ubuntu Server (VPS)

1. Copy this Folder in your User Home Directory using Filezilla or WinSCP OR SCP command)
2. Go to this Folder by terminal
3. chmod +x  *.sh
4. Execute: ./odooxx.sh
5. Enjoy

### Odoo Service Manager

* sudo systemctl status odooxx (shows state Odoo service)
* sudo systemctl start odooxx (start service)
* sudo systemctl stop odooxx (stop service)
* sudo systemctl restart odooxx (restart service)
* sudo systemctl disable odooxx (disable autostart)
* sudo tail -f /opt/odoo/xx.0/log/ (Shows Live Odoo Log)


### Source Odoo location

* /opt/odoo (All Source)
* /opt/odoo/xx.0/extra-addons (Extra Addons)
* /opt/odoo/xx.0/data (Filestore)
* /opt/odoo/log/ (Log file)
* /opt/odoo/config/ (Config file)
