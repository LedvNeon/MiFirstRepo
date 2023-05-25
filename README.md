# Задание:
## Цель домашнего задания:
Создать домашнюю сетевую лабораторию. Изучить основы DNS, научиться работать с технологией Split-DNS в Linux-based системах.
## Описание домашнего задания:
### Взять стенд https://github.com/erlong15/vagrant-bind
1. добавить еще один сервер client2
2. завести в зоне dns.lab имена:
- web1 - смотрит на клиент1
- web2  смотрит на клиент2
3. завести еще одну зону newdns.lab
4. завести в ней запись
- www - смотрит на обоих клиентов
### Настроить split-dns
1. клиент1 - видит обе зоны, но в зоне dns.lab только web1
2. клиент2 видит только dns.lab
### Дополнительное задание:
- настроить все без выключения selinux

Формат сдачи ДЗ - vagrant + ansible

# Решение:
Я отредактировал предложенный Vagrantfile заменив внутреннюю сеть на публичную, что бы VM оказались в моей сети.
Это необходимо, т.к. в моём распоряжении win10 + wsl Ubuntu, с которого я буду настраивать VM через ansible.

Описание файлов из репозитория:
1. README.md -  файл с описанием ДЗ
2. Vagrantfile - файл для сборки стенда
3. ansible.cfg - конфигурационные параметры ansible
4. ping.yml - файл тестового ping для ansible для проверки доступности хостов
5. hosts - файл с серверами, администрируемыми ansible
6. bind.yml - основной playbook
7. FIlesNamedConfig.7z - архив с named.conf и файлами зон (добавил архивом, что бы не заграмождать)

Развернём VM.
C:\git\MiFirstRepo> vagrant up
Подключимся к wsl ubuntu, перейдём в режим супер пользователя и создади директорию dns-bind, в которой создадим следующие фалйлы (приложены в репозитории):
dima@DESKTOP-9BHG4U3:~$ sudo su
[sudo] password for dima:
root@DESKTOP-9BHG4U3:/home/dima
root@DESKTOP-9BHG4U3:/home/dima# mkdir dns-bind

Допишем открытый ключ из ubuntu из /home/dima/.ssh/ в /home/vagrant/.ssh/authorized_keys

### Проверим доступность хостов по ansible 

root@DESKTOP-9BHG4U3:/home/dima/dns-bind ansible-playbook ping.yml

PLAY [ping] ************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [ns01]
ok: [ns02]
ok: [client]
ok: [client2]

TASK [ping] ************************************************************************************************************
ok: [ns01]
ok: [client2]
ok: [ns02]
ok: [client]

PLAY RECAP *************************************************************************************************************
client                     : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
client2                    : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
ns01                       : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
ns02                       : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

#### Напишем playbook с именем bind.yml и выполним его для настройки bind-серверов и клиентов.
В процессе настройки потребуется копировать файлы на VM, создадим их предварительно в \\wsl.localhost\Ubuntu-20.04\home\dima\dns-bind\ns02.

После запуска playbook bind.yml проверим с клиентов разрешение имён (ниже пример проверки с хоста client).
В моём примере я сразу создал конфигурацию для 2-х зон. Если добавлять отдельно, то в playbook нужно хапустить (есть в последнем play-е)
- name: "example"
  hosts: servers
  command: systemctl restart named

[root@client vagrant]# hostname
client

### Проверка разрешения имени web01 с машины client через nslookup
[root@client vagrant]# nslookup web1.dns.lab 192.168.1.100
Server:         192.168.1.100
Address:        192.168.1.100#53

Name:   web1.dns.lab
Address: 192.168.1.115

### через dig
[root@client vagrant]# dig @192.168.1.100 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.13 <<>> @192.168.1.100 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 47177
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.                  IN      A

;; ANSWER SECTION:
web1.dns.lab.           3600    IN      A       192.168.1.115

;; AUTHORITY SECTION:
dns.lab.                3600    IN      NS      ns02.dns.lab.
dns.lab.                3600    IN      NS      ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.1.100
ns02.dns.lab.           3600    IN      A       192.168.1.110

;; Query time: 2 msec
;; SERVER: 192.168.1.100#53(192.168.1.100)
;; WHEN: Wed May 24 19:55:02 UTC 2023
;; MSG SIZE  rcvd: 127

### Ппроверка разрешения www с client
[root@client vagrant]# nslookup www.newdns.lab 192.168.1.100
Server:         192.168.1.100
Address:        192.168.1.100#53

Name:   www.newdns.lab
Address: 192.168.1.115
Name:   www.newdns.lab
Address: 192.168.1.120

При проверке можно не указывать принудительно dns-сервер, через который мы хотим разрешать имена.
Для этого нужно добавить в /etc/resolv.conf следующее:
ns01 192.168.1.100
ns02 192.168.1.110

### Настроим split-dns
Для этого создадим в хостовой машине файлы master-named.conf (новый файл конфига named для первичного сервера), named.dns.lab.client - файл с настройками для зоны, slave-named.conf - новый файл конфига для вторичного сервера.

Допишем в playbook новый play по настройке split-dns.
После выполнения playbook проверим работу.

### Проверка с client
[root@client vagrant]# nslookup web1.dns.lab 192.168.1.100
Server:         192.168.1.100
Address:        192.168.1.100#53

Name:   web1.dns.lab
Address: 192.168.1.115

[root@client vagrant]# nslookup www.newdns.lab 192.168.1.100
Server:         192.168.1.100
Address:        192.168.1.100#53

Name:   www.newdns.lab
Address: 192.168.1.115
Name:   www.newdns.lab
ВИДИТ СЕРВЕРА В ОБОИХ ЗОНАХ

### Проверка с client2
[root@client2 vagrant]# nslookup web1.dns.lab 192.168.1.100
Server:         192.168.1.100
Address:        192.168.1.100#53

Name:   web1.dns.lab
Address: 192.168.1.115

[root@client2 vagrant]# nslookup www.newdns.lab 192.168.1.100
Server:         192.168.1.100
Address:        192.168.1.100#53

** server can't find www.newdns.lab: NXDOMAIN

ВИДИТ СЕРВЕРА ТОЛЬКО ИЗ ЗОНЫ dns.lab

У меня вопрос - как сделать так, что бы из зоны dns.lab видел только конкретные адреса? Не нашёл этого в методичке. И не противоречит ли это rfc в целом? Ведь сервер смотрит в зону цкликом, не нашёл информации, как скрыть конкретные адреса. Просьба подсказать, если это возможно.

