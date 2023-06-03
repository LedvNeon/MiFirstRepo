Vagrant.configure("2") do |config|
    # Указываем ОС, версию, количество ядер и ОЗУ
    config.vm.box = "centos/7"
 
    config.vm.provider :virtualbox do |v|
      v.memory = 2048
      v.cpus = 1
    end
  
    # Указываем имена хостов и их IP-адреса
    boxes = [
      { :name => "ipa.otus.lan",
        :ip => "192.168.1.100",
      },
      { :name => "client1.otus.lan",
        :ip => "192.168.1.110",
      },
      { :name => "client2.otus.lan",
        :ip => "192.168.1.120",
      }
    ]
    # Цикл запуска виртуальных машин
    boxes.each do |opts|
      config.vm.define opts[:name] do |config|
        config.vm.hostname = opts[:name]
        config.vm.network "public_network", ip: opts[:ip]
      end
    end
  end