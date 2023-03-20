# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :dockersrv => {
        :box_name => "centos/7",
        :ip_addr => '192.168.1.100'
  }
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          box.vm.network "public_network", ip: boxconfig[:ip_addr]

          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "200"]
        
          box.vm.synced_folder "C:/git/MiFirstRepo/docker", "/mnt", type: "rsync"
          end
          
          box.vm.provision "shell", path: "script.sh"

      end
  end
end