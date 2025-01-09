# Copiar el script de instalación de MySQL a la máquina virtual
cookbook_file '/home/vagrant/install_mysql.sh' do
  source 'install_mysql.sh'
  mode '0755'  # Asegúrate de que tenga permisos de ejecución
  action :create
end

# Ejecutar el script de instalación de MySQL
execute 'run_mysql_setup' do
  command 'bash /home/vagrant/install_mysql.sh'
  action :run
  not_if { ::File.exist?('/var/lib/mysql/wordpress') }
end

# Copiar el script de instalación de WordPress a la máquina virtual
cookbook_file '/home/vagrant/install_wordpress.sh' do
  source 'install_wordpress.sh'
  mode '0755'  # Asegúrate de que tenga permisos de ejecución
  action :create
end

# Ejecutar el script de instalación de WordPress
execute 'run_wordpress_setup' do
  command 'bash /home/vagrant/install_wordpress.sh'
  action :run
  not_if { ::File.exist?('/var/www/html/wp-config.php') }
end