#!/bin/bash

# Instalar Apache y PHP
apt-get update
apt-get install -y apache2 php libapache2-mod-php php-mysql php-cli php-curl php-xml php-mbstring

# Descargar WordPress
wget https://wordpress.org/latest.tar.gz -P /tmp
tar -xzvf /tmp/latest.tar.gz -C /var/www/html/

# Mover los archivos de WordPress y configurar permisos
mv /var/www/html/wordpress/* /var/www/html/
rmdir /var/www/html/wordpress
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Configurar wp-config.php
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/database_name_here/wordpress/" /var/www/html/wp-config.php
sed -i "s/username_here/wordpress_user/" /var/www/html/wp-config.php
sed -i "s/password_here/password/" /var/www/html/wp-config.php

# Configurar VirtualHost de Apache
cat <<EOL > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Habilitar sitio y reiniciar Apache
a2ensite wordpress
a2enmod rewrite
systemctl restart apache2
