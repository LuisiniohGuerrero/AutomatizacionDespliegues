# spec/unit/recipes/default_spec.rb
require 'chefspec'

describe 'wordpress::default' do
  platform 'ubuntu', '20.04'  # Puedes especificar el sistema operativo aquí

  # Verificar que Apache se instala
  it 'installs apache2' do
    expect(chef_run).to install_package('apache2')
  end

  # Verificar que Apache está habilitado y en ejecución
  it 'enables and starts apache2 service' do
    expect(chef_run).to enable_service('apache2')
    expect(chef_run).to start_service('apache2')
  end

  # Verificar que PHP y las extensiones necesarias se instalan
  %w(php libapache2-mod-php php-mysql php-cli php-curl php-xml php-mbstring).each do |pkg|
    it "installs package #{pkg}" do
      expect(chef_run).to install_package(pkg)
    end
  end

  # Verificar que MySQL se instala
  it 'installs mysql-server' do
    expect(chef_run).to install_package('mysql-server')
  end

  # Verificar que se crea la base de datos 'wordpress'
  it 'creates wordpress database' do
    expect(chef_run).to run_execute('create_wordpress_database')
  end

  # Verificar que el archivo wp-config.php se crea correctamente
  it 'creates wp-config.php' do
    expect(chef_run).to create_template('/var/www/html/wp-config.php')
  end
end
