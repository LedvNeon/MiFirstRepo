# -*- mode: ruby -*-
# vim: set ft=ruby :
    Vagrant.configure(2) do |config|
        config.vm.box = "centos/7"
        
            config.vm.provider "virtualbox" do |vb|
                vb.name = "testserv1"
                vb.memory = "1024"
                vb.cpus = 1
            end

                config.vm.define "testserv1" do |testserv1|        
                    testserv1.vm.hostname = "testserv1"
                    testserv1.vm.network "private_network", ip: "192.168.50.11", virtualbox__intnet: "net1"
                    testserv1.vm.provision "shell", path: "script.sh"
                end
    end
