Vagrant.configure("2") do |config|
  config.vm.define "master" do |master|
    master.vm.box = "centos/7"
    master.vm.provider :virtualbox
    master.vm.hostname = "master"
    master.vm.network "public_network", ip: "172.20.10.3"

    master.vm.provision "shell", inline: <<-SHELL
    mkdir -p ~root/.ssh
          cp ~vagrant/.ssh/auth* ~root/.ssh
          SHELL
  end

  config.vm.define "slave" do |slave|
    slave.vm.box = "centos/7"
    slave.vm.provider :virtualbox
    slave.vm.hostname = "slave"
    slave.vm.network "public_network", ip: "172.20.10.4"

    slave.vm.provision "shell", inline: <<-SHELL
    mkdir -p ~root/.ssh
          cp ~vagrant/.ssh/auth* ~root/.ssh
          SHELL
  end

  config.vm.provision "ansible" do |ansible|
    ansible.verbose = "vvv"
    ansible.playbook = "/home/vagrant/mysql/mysql.yml"
    ansible.sudo = "true"
  end

end
