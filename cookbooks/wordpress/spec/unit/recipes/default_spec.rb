require 'chefspec'

describe 'wordpress::default' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '20.04').converge(described_recipe)
  end

  # Caso de prueba 1: Verifica que el script de MySQL se copie correctamente
  it 'copies the install_mysql.sh script' do
    expect(chef_run).to create_cookbook_file('/home/vagrant/install_mysql.sh')
      .with(source: 'install_mysql.sh', mode: '0755')
  end

  # Caso de prueba 2: Verifica que el script de WordPress se copie correctamente
  it 'copies the install_wordpress.sh script' do
    expect(chef_run).to create_cookbook_file('/home/vagrant/install_wordpress.sh')
      .with(source: 'install_wordpress.sh', mode: '0755')
  end

  # Caso de prueba 3: Verifica que el script de instalación de MySQL se ejecute
  it 'executes the install_mysql.sh script' do
    allow(::File).to receive(:exist?).with('/var/lib/mysql/wordpress').and_return(false)  # Simula que el archivo no existe
    expect(chef_run).to run_execute('run_mysql_setup')
      .with(command: 'bash /home/vagrant/install_mysql.sh')
  end

  # Caso de prueba 4: Verifica que el script de instalación de WordPress se ejecute
  it 'executes the install_wordpress.sh script' do
    allow(::File).to receive(:exist?).with('/var/www/html/wp-config.php').and_return(false)  # Simula que el archivo no existe
    expect(chef_run).to run_execute('run_wordpress_setup')
      .with(command: 'bash /home/vagrant/install_wordpress.sh')
  end

  # Caso de prueba 5: Verifica que el script de MySQL no se ejecute si ya existe el archivo
  it 'does not execute the install_mysql.sh script if the file exists' do
    allow(::File).to receive(:exist?).with('/var/lib/mysql/wordpress').and_return(true)  # Simula que el archivo ya existe
    expect(chef_run).to_not run_execute('run_mysql_setup')
  end

  # Caso de prueba 6: Verifica que el script de WordPress no se ejecute si ya existe el archivo
  it 'does not execute the install_wordpress.sh script if the file exists' do
    allow(::File).to receive(:exist?).with('/var/www/html/wp-config.php').and_return(true)  # Simula que el archivo ya existe
    expect(chef_run).to_not run_execute('run_wordpress_setup')
  end
end
