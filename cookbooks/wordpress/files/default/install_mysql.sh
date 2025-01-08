#!/bin/bash

# Variables
MYSQL_ROOT_PASSWORD="root_password"
MYSQL_USER="wordpress_user"
MYSQL_PASSWORD="password"

# Actualizar paquetes
apt-get update

# Instalar MySQL Server
DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

# Configuración de MySQL
systemctl enable mysql
systemctl start mysql

# Crear usuario y base de datos para WordPress
mysql -u root -e "CREATE DATABASE IF NOT EXISTS wordpress;"
mysql -u root -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON wordpress.* TO '${MYSQL_USER}'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

echo "MySQL instalado y configurado correctamente."
