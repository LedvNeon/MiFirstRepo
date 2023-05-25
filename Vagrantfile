Vagrant.configure(2) do |config|
    config.vm.box = "centos/7"
  
    config.vm.provision "shell", inline: <<-SHELL
    mkdir -p ~root/.ssh
          cp ~vagrant/.ssh/auth* ~root/.ssh
    SHELL
  
  
    config.vm.provider "virtualbox" do |v|
        v.memory = 256
    end
  
    config.vm.define "ns01" do |ns01|
      ns01.vm.network "public_network", ip: "192.168.1.100"
      ns01.vm.hostname = "ns01"
    end
  
    config.vm.define "ns02" do |ns02|
      ns02.vm.network "public_network", ip: "192.168.1.110"
      ns02.vm.hostname = "ns02"
    end
  
    config.vm.define "client" do |client|
      client.vm.network "public_network", ip: "192.168.1.115"
      client.vm.hostname = "client"
    end
  
    config.vm.define "client2" do |client2|
      client2.vm.network "public_network", ip: "192.168.1.120"
      client2.vm.hostname = "client2"
    end
  
  end
  