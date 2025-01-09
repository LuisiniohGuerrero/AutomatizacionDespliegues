Vagrant.configure("2") do |config|

    # Configuración para la máquina Ubuntu
    config.vm.define "ubuntu_vm" do |ubuntu|
      ubuntu.vm.box = "bento/ubuntu-20.04"
      ubuntu.vm.hostname = "wordpress-ubuntu"
      ubuntu.vm.network "forwarded_port", guest: 80, host: 8080
      ubuntu.vm.network "private_network", ip: "192.168.56.101"
      ubuntu.vm.provider "virtualbox" do |vb|
        vb.memory = 1024
        vb.cpus = 2
      end
      ubuntu.vm.provision "chef_solo" do |chef|
        chef.cookbooks_path = "cookbooks"
        chef.add_recipe "wordpress" #"wordpress::default"
        chef.arguments = "--chef-license accept" # Aceptar la licencia automáticamente
      end
    end
  
    # Configuración para la máquina CentOS (Pendiente)
    config.vm.define "centos_vm" do |centos|
      centos.vm.box = "bento/centos-8"
      centos.vm.hostname = "wordpress-centos"
      centos.vm.network "private_network", ip: "192.168.56.102"
      centos.vm.provider "virtualbox" do |vb|
        vb.memory = 1024
        vb.cpus = 2
      end
      centos.vm.provision "chef_solo" do |chef|
        chef.cookbooks_path = "cookbooks"
        chef.add_recipe "wordpress::default"
        chef.arguments = "--chef-license accept" # Aceptar la licencia automáticamente
      end
    end
  
  end
