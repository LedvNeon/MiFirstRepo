# Задача:
1. Следуя шагам из документа https://docs.centos.org/en-US/8-docs/advanced-install/assembly_preparing-for-a-network-install  установить и настроить загрузку по сети для дистрибутива CentOS 8.
В качестве шаблона воспользуйтесь репозиторием https://github.com/nixuser/virtlab/tree/main/centos_pxe 
2. Поменять установку из репозитория NFS на установку из репозитория HTTP.
3. Настроить автоматическую установку для созданного kickstart файла (*) Файл загружается по HTTP.
* 4.  автоматизировать процесс установки Cobbler cледуя шагам из документа https://cobbler.github.io/quickstart/. 
Задание со звездочкой выполняется по желанию.
Формат сдачи ДЗ - vagrant + ansible

# Решение:
Поднимим 2 VM из Vagrantfile (pxeclient и pxeserver).
Т.к. я работаю на win-машине, у меня есть wsl Ubuntu с предустановленным ansible. Настройка будет проводится с неё.
Изменения, которые внёс в искомый Vagrantfile - раскоментил строку server.vm.network "forwarded_port", guest: 80, host: 8080, удалил блок настройки PXE-сервера с помощью bash-скрипта "ENABLE to setup PXE" удалл, т.к. будем настраивать через Ansible. Так же добавил интерфейс public, т.к. буду настраивать с хостовой машины из своей сети.

## Пишем playbook playbook.yml
## Содержимое inventory-файла:
[pxe_servers]
pxeserver ansible_host=192.168.1.70 ansible_port=22 ansible_private_key_file="home/dima/.vagrant/machines/pxeserver/virtualbox/private_key"

## Содержимое файла ansible.cfg:
inventory = hosts
remote_user = vagrant
host_key_checking = False
retry_files_enabled = False

## Тестовый playbook для проверки доступности сервера-pxe:
---
  - name: PING pxeserver
    hosts: pxeserver
    become: true

    tasks:
      - name: PING web
        action: ping

## Проверка доступности сервера через ping.yml:
root@DESKTOP-9BHG4U3:/home/dima# ansible-playbook -i hosts ping.yml

PLAY [PING pxeserver] **************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [pxeserver]

TASK [PING web] ********************************************************************************************************
ok: [pxeserver]

PLAY RECAP *************************************************************************************************************
pxeserver                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

playbook.yml приложен в репозиторий. 

Создадим файл /etc/httpd/conf.d/pxeboot.conf со следующим содержимым на сервере вручную
Alias /centos7 /iso
<Directory /iso>
    Options Indexes FollowSymLinks
    Require all granted
</Directory>

[root@pxeserver vagrant]# vi /etc/httpd/conf.d/pxeboot.conf

Так же вручную был создан vi /var/lib/tftpboot/pxelinux.cfg/default

default menu.c32
prompt 0
#Время счётчика с обратным отсчётом (установлено 15 секунд)
timeout 150
#Параметр использования локального времени
ONTIME local
#Имя «шапки» нашего меню
menu title OTUS PXE Boot Menu
       #Описание первой строки
       label 1
       #Имя, отображаемое в первой строке
       menu label ^ Graph install CentOS 8.4
       #Адрес ядра, расположенного на TFTP-сервере
       kernel /vmlinuz
       #Адрес файла initrd, расположенного на TFTP-сервере
       initrd /initrd.img
       #Получаем адрес по DHCP и указываем адрес веб-сервера
       append ip=enp0s3:dhcp inst.repo=http://10.0.0.20/centos8
       label 2
       menu label ^ Text install CentOS 8.4
       kernel /vmlinuz
       initrd /initrd.img
       append ip=enp0s3:dhcp inst.repo=http://10.0.0.20/centos8 text
       label 3
       menu label ^ rescue installed system
       kernel /vmlinuz
       initrd /initrd.img
       append ip=enp0s3:dhcp inst.repo=http://10.0.0.20/centos8 rescue


Так же вручную был создан /etc/dhcp/dhcpd.conf
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;

#Указываем сеть и маску подсети, в которой будет работать DHCP-сервер
subnet 10.0.0.0 netmask 255.255.255.0 {
        #Указываем шлюз по умолчанию, если потребуется
        #option routers 10.0.0.1;
        #Указываем диапазон адресов
        range 10.0.0.100 10.0.0.120;

        class "pxeclients" {
          match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
          #Указываем адрес TFTP-сервера
          next-server 10.0.0.20;
          #Указываем имя файла, который надо запустить с TFTP-сервера
          filename "pxelinux.0";
        }

Выполним playbook:
root@DESKTOP-9BHG4U3:/home/dima# ansible-playbook -i hosts playbook.yml

Проверка приложена в отдельном файлу word - "Проверка"
