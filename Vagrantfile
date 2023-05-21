# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
    config.vm.box = "centos/7"
    config.vm.define "server" do |server|
    server.vm.hostname = "server.loc"
    server.vm.network "public_network", ip: "192.168.1.100"
    end
    config.vm.define "client" do |client|
    client.vm.hostname = "client.loc"
    client.vm.network "public_network", ip: "192.168.1.110"
    end
    end