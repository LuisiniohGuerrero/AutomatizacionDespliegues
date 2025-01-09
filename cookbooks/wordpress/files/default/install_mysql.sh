#!/bin/bash

# Instalar MySQL Server
apt-get update
apt-get install -y mysql-server

# Contraseña de root
root_password="root_password"

# Asegurarse de que el usuario root utilice mysql_native_password
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${root_password}'; FLUSH PRIVILEGES;"

# Crear base de datos de WordPress si no existe
mysql -u root -p${root_password} -e "CREATE DATABASE IF NOT EXISTS wordpress;"

# Crear usuario wordpress_user si no existe
mysql -u root -p${root_password} -e "CREATE USER IF NOT EXISTS 'wordpress_user'@'localhost' IDENTIFIED BY 'password';"

# Permisos al usuario wordpress_user sobre la base de datos wordpress
mysql -u root -p${root_password} -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress_user'@'localhost'; FLUSH PRIVILEGES;"

# Reiniciar MySQL para aplicar configuraciones
systemctl restart mysql
