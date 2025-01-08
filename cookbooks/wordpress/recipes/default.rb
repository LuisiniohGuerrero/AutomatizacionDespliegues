# Instalar Apache
package 'apache2' do
  action :install
  notifies :run, 'execute[check_apache_installation]', :immediately
end

# Comprobar que Apache se instaló correctamente
execute 'check_apache_installation' do
  command 'apache2 -v'
  action :nothing
  not_if 'which apache2'
  user 'root'
  only_if { ::File.exist?('/etc/apache2/apache2.conf') }
  notifies :stop, 'service[apache2]', :immediately
end

# Asegurarse de que el servicio de Apache esté habilitado y corriendo
service 'apache2' do
  action [:enable, :start]
end

# Instalar PHP y las extensiones necesarias
%w(php libapache2-mod-php php-mysql php-cli php-curl php-xml php-mbstring).each do |pkg|
  apt_package pkg do
    action :install
    notifies :run, "execute[check_php_installation_#{pkg}]", :immediately
  end

  # Comprobar instalación de PHP
  execute "check_php_installation_#{pkg}" do
    command "dpkg -l | grep #{pkg}"
    action :nothing
    not_if "dpkg -l | grep #{pkg}"
    notifies :stop, 'service[apache2]', :immediately
  end
end

# Instalar MySQL Server
apt_package 'mysql-server' do
  action :install
  notifies :run, 'execute[check_mysql_installation]', :immediately
end

# Comprobar que MySQL se instaló correctamente
execute 'check_mysql_installation' do
  command 'mysql --version'
  action :nothing
  not_if 'which mysql'
  user 'root'
  notifies :stop, 'service[mysql]', :immediately
end

# Verificar si MySQL está corriendo
execute 'check_mysql_status' do
  command 'systemctl status mysql'
  action :run
  only_if 'systemctl is-active --quiet mysql'
  not_if 'systemctl is-active --quiet mysql'
  notifies :run, 'execute[repair_mysql]', :immediately
end

# Corregir permisos y archivos de MySQL (Validar)
execute 'repair_mysql' do
  command <<-EOH
    # Asegurarse de que los permisos y directorios de MySQL sean correctos
    chown -R mysql:mysql /var/lib/mysql
    chown -R mysql:mysql /var/run/mysqld
    chmod -R 755 /var/lib/mysql
    systemctl start mysql
  EOH
  action :nothing
  notifies :restart, 'service[mysql]', :immediately
end



# Espera a que el socket de MySQL esté disponible
execute 'wait_for_mysql_socket' do
  command 'while ! mysqladmin ping --silent; do sleep 1; done;'
  action :run
  not_if 'mysqladmin ping --silent'
end

execute 'check_mysql_status' do
  command 'systemctl status mysql'
  action :run
  only_if 'systemctl is-active --quiet mysql'
  not_if 'systemctl is-active --quiet mysql'
end

execute 'check_mysql_socket' do
  command 'while ! test -e /var/run/mysqld/mysqld.sock; do sleep 1; done;'
  action :run
  not_if 'test -e /var/run/mysqld/mysqld.sock'
end


# Contraseña de root
root_password = 'root_password'

# Asegurarse de que el usuario root utilice mysql_native_password
execute 'set_native_password_for_root' do
  command "mysql -u root -p#{root_password} -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '#{root_password}'; FLUSH PRIVILEGES;\""
  not_if "mysql -u root -p#{root_password} -e \"SELECT plugin FROM mysql.user WHERE User = 'root' AND Host = 'localhost';\" | grep 'mysql_native_password'"
  notifies :stop, 'service[mysql]', :immediately
end

# Crear base de datos de WordPress si no existe
execute 'create_wordpress_database' do
  command "mysql -u root -p#{root_password} -e \"CREATE DATABASE IF NOT EXISTS wordpress;\""
  action :run
  not_if "mysql -u root -p#{root_password} -e \"SHOW DATABASES LIKE 'wordpress';\""
  only_if 'systemctl is-active --quiet mysql'  # Verifica si MySQL está corriendo
  notifies :stop, 'service[mysql]', :immediately
end


# Crear usuario wordpress_user si no existe
execute 'create_wordpress_user' do
  command "mysql -u root -p#{root_password} -e \"CREATE USER IF NOT EXISTS 'wordpress_user'@'localhost' IDENTIFIED BY 'password';\""
  action :run
  notifies :stop, 'service[mysql]', :immediately
end

# Permisos al usuario wordpress_user sobre la base de datos wordpress
execute 'grant_permissions' do
  command "mysql -u root -p#{root_password} -e \"GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress_user'@'localhost'; FLUSH PRIVILEGES;\""
  action :run
  not_if "mysql -u root -p#{root_password} -e \"SHOW GRANTS FOR 'wordpress_user'@'localhost';\""
  notifies :stop, 'service[mysql]', :immediately
end

# MySQL se reinicie después de la configuración
service 'mysql' do
  action :nothing
end

# Descargar e instalar WordPress
remote_file '/tmp/latest.tar.gz' do
  source 'https://wordpress.org/latest.tar.gz'
  action :create
  notifies :run, 'bash[install_wordpress]', :immediately
end

# Descomprimir e instalar WordPress
bash 'install_wordpress' do
  code <<-EOH
    # Descomprimir y mover los archivos de WordPress a /var/www/html
    tar xzvf /tmp/latest.tar.gz -C /var/www/html
    mv /var/www/html/wordpress/* /var/www/html/
    rmdir /var/www/html/wordpress
    
    # Cambiar permisos y propiedad para Apache
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
  EOH
  action :nothing
  not_if { ::File.exist?('/var/www/html/wp-config.php') }
  notifies :stop, 'service[apache2]', :immediately
end

# Configurar la base de datos en wp-config.php
template '/var/www/html/wp-config.php' do
  source 'wp-config.php.erb'
  variables(
    db_name: 'wordpress',
    db_user: 'wordpress_user',
    db_password: 'password',
    db_host: 'localhost'
  )
  not_if { ::File.exist?('/var/www/html/wp-config.php') }
  notifies :stop, 'service[apache2]', :immediately
end

# Configurar VirtualHost de Apache
file '/etc/apache2/sites-available/wordpress.conf' do
  content <<-EOH
    <VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        # Página predeterminada de Apache
        <Directory /var/www/html>
            Options Indexes FollowSymLinks
            AllowOverride None
            Require all granted
        </Directory>

        # WordPress en /wp-admin
        Alias /wp-admin /var/www/wordpress/wp-admin
        <Directory /var/www/wordpress/wp-admin>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        # Resto de WordPress
        <Directory /var/www/wordpress>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>
  EOH
  action :create
  notifies :stop, 'service[apache2]', :immediately
end

# Habilitar sitio y escritura
execute 'enable_wordpress_site' do
  command 'a2ensite wordpress && a2enmod rewrite'
  notifies :restart, 'service[apache2]', :immediately
end

# Reiniciar Apache para cargar los cambios
service 'apache2' do
  action :restart
end

# Detener el servicio si algún paso anterior falló (validar)
service 'apache2' do
  action :nothing
end

service 'mysql' do
  action :nothing
end
