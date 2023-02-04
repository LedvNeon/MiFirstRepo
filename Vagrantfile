# -*- mode: ruby -*-
# vi: set ft=ruby :

	Vagrant.configure(2) do |config|
		config.vm.box = "centos/7"
		#config.vm.provision "shell", s.inline = 'mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh'
		
				config.vm.provider "virtualbox" do |v|
					v.memory = 256
					v.cpus = 1
				end
				
							config.vm.define "vmtest" do |vmtest|
								vmtest.vm.network "private_network", ip: "192.168.50.10", virtualbox__intnet: "net1"
								vmtest.vm.hostname = "vmtest"
								vmtest.vm.provision "shell", path: "Script.sh"
							end
	end
	