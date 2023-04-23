# Задание
# Дано:
https://github.com/erlong15/otus-linux/tree/network
(ветка network)
Vagrantfile с начальным построением сети

inetRouter
centralRouter
centralServer
тестировалось на virtualbox
Планируемая архитектура
построить следующую архитектуру
Сеть office1
192.168.2.0/26 - dev
192.168.2.64/26 - test servers
192.168.2.128/26 - managers
192.168.2.192/26 - office hardware
Сеть office2
192.168.1.0/25 - dev
192.168.1.128/26 - test servers
192.168.1.192/26 - office hardware
Сеть central
192.168.0.0/28 - directors
192.168.0.32/28 - office hardware
192.168.0.64/26 - wifi
```
Office1 ---\
----> Central --IRouter --> internet
Office2----/
```
Итого должны получится следующие сервера
inetRouter
centralRouter
office1Router
office2Router
centralServer
office1Server
office2Server

# Теоретическая часть
Найти свободные подсети
Посчитать сколько узлов в каждой подсети, включая свободные
Указать broadcast адрес для каждой подсети
проверить нет ли ошибок при разбиении

# Практическая часть
Соединить офисы в сеть согласно схеме и настроить роутинг
Все сервера и роутеры должны ходить в инет черз inetRouter
Все сервера должны видеть друг друга
у всех новых серверов отключить дефолт на нат (eth0), который вагрант поднимает для связи
при нехватке сетевых интервейсов добавить по несколько адресов на интерфейс
Формат сдачи ДЗ - vagrant + ansible
В чат ДЗ отправьте ссылку на ваш git-репозиторий. Обычно мы проверяем ДЗ в течение 48 часов.
Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Slack.
Удачи при выполнении!

# Критерии оценки:
Статус "Принято" ставится, если сделана хотя бы часть.
Задание со звездочкой - выполнить всё.

# Решение теоретической части:
Маска - отвечает за разделение адреса под-сети от адресов устр-в, так же рабивает сеть на подсети.
Кол-во устр-в в сети рассчитывается по формуле: 2^(32−маска)−2.
2 адреса отнимаем, т.к. один из них (последний) - широковещательный, а первый принадлежит подсети.
Сам IP адрес это 4 октета по 8 бит (0 или 1), каждый из которых это 2 в степени порядка справ на лево:
2^7 2^6 2^5 2^4 2^3 2^2 2^1 2^0
Адрес подсети определяется наложением маски на IP адрес (выполняется операция логического сложения)

Исходя из этого построим таблицу для указанных в задании подсетей:

Имя сети             Сеть            Маска          Кол-во адресов   1-й адрес          Посл-й адрес    Широковещат. адрес
Сеть office1
dev             192.168.2.0/26    255.255.255.192        62          192.168.2.1         192.168.2.62      192.168.2.63
test servers    192.168.2.64/26   255.255.255.192        62          192.168.2.65        192.168.2.126     192.168.2.127
managers        192.168.2.128/26  255.255.255.192        62          192.168.2.129       192.168.2.190     192.168.2.191
office hardware 192.168.2.192/26  255.255.255.192        62          192.168.2.193       192.168.2.254     192.168.2.255

Сеть office2    
dev             192.168.1.0/25    255.255.255.128        126         192.168.1.1         192.168.1.126     192.168.1.127
test servers    192.168.1.128/26  255.255.255.192        62          192.168.1.129       192.168.1.190     192.168.1.191
office hardware 192.168.1.192/26   255.255.255.192       62          192.168.1.293       192.168.1.254     192.168.1.255

Сеть central   
directors       192.168.0.0/28    255.255.255.240        14          192.168.0.1         192.168.0.14      192.168.0.15
office hardware 192.168.0.32/28   255.255.255.240        14          192.168.0.33        192.168.0.46      192.168.0.47
wifi            192.168.0.64/26   255.255.255.192        62          192.168.0.65        192.168.0.126     192.168.0.127

Inet — central  192.168.255.0/30  255.255.255.252        2           192.168.255.1       192.168.255.2     192.168.255.3

Теерь мы можем определить свободные сети.
Свободные сети определяем так: если широковещательный адрес текущей подсети, к примеру равен 192.168.0.15, то адрес следующей сети 192.168.0.16. Далее, накладываем имеющуюся маску на адрес новой сети и смотрим, попадает ли она с этой 
маской в интервал до следующей сети 192.168.0.32/28. В этом примере попадает.Если попадания не происходит, значит нужно менять значение во втором октете (справа налево). ЕСЛИ ОПИСАЛ НЕПРАВИЛЬНО, ПРОСЬБА СКОРРЕКТИРОВАТЬ.
192.168.0.16/28 
192.168.0.48/28
192.168.0.128/25
192.168.255.64/26
192.168.255.32/27
192.168.255.16/28
192.168.255.8/29  
192.168.255.4/30 

Теперь переходим к практической части
# Практическая часть
По схеме из методички (приложена в репозиторий - Schema.pdf) мы видим, что нам потребуется создать дополнительно 2 сети 
Для соединения office1Router c centralRouter — 192.168.255.8/30
Для соединения office2Router c centralRouter — 192.168.255.4/30
На основании этой схемы мы получаем готовый список серверов. ОС на всех серверах делаю Centos7, т.к. нет другого образа для Vagrant.
Список серверов будет приложен отдельным файлом в репозиторий.

Развернём сервера из Vagrantfile. 
В данный Vagrantfile мы добавили информацию о 4 новых серверах, также к старым серверам добавили 2 интерфейса для соединения сетей офисов.

Дополнительно в коде есть сетевые устройства из подсети 192.168.50.0/24 — они потребуются, если я доберусь до насйтроки через Ansible.

После того, как все 7 серверов у нас развернуты, нам нужно настроить маршрутизацию и NAT таким образом, чтобы доступ в Интернет со всех хостов был через inetRouter и каждый сервер должен быть доступен с любого из 7 хостов. 
Часть настройки у нас уже выполнена. Рассмотрим подробнее команды из Vagrantfile.

# Настройка NAT
Для того, чтобы на всех серверах работал интернет, на сервере inetRouter должен быть настроен NAT. В нашем Vagrantfile он настраивается с помощью команды: 
iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE 
iptables - утилита для настройки firewall 
nat - режим работы  (трансляция адресов)
POSTROUTING - используется для всего исходящего трафика после принятия всех решений о маршрутизации
-t - таблица 
-A - цепочка определение-правила
-o - дальше идёт имя интерфейса, через который отправляется обрабатываемый пакет
-j - определяет цель правила
Процесс подмены роутером внутренних адресов устройств на свой собственный называется «маскарадом» (masquerade)
При настройке NAT таким образом, правило удаляется после перезагрузки сервера. Для того, чтобы правила применялись после перезагрузки, в CentOS 7 выполним следующее:

- подключиться по SSH к хосту inetRouter - провреим работает ли служба firewalld (должны быть выключена)

PS C:\git\MiFirstRepo> vagrant ssh inetRouter
[vagrant@inetRouter ~]$ sudo su
[root@inetRouter vagrant]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)

- установим пакеты iptables и iptables-services
[root@inetRouter vagrant]# yum -y install iptables iptables-services
Loaded plugins: fastestmirror
Determining fastest mirrors
 * base: mirror.corbina.net
 * extras: mirror.corbina.net
 * updates: centos-mirror.rbc.ru
 (целиком вывод не прикладывал)

 Добавить службу iptables в автозапуск
[root@inetRouter vagrant]# systemctl enable iptables
Created symlink from /etc/systemd/system/basic.target.wants/iptables.service to /usr/lib/systemd/system/iptables.service.

Отредактировать файл /etc/sysconfig/iptables
Данный файл содержит в себе базовые правила, которые появляются с установкой iptables. 
Закомментируем следующие строки:
 -A INPUT -j REJECT --reject-with icmp-host-prohibited
 -A FORWARD -j REJECT --reject-with icmp-host-prohibited
(запрет ping между хостами, через данный сервер)

[root@inetRouter vagrant]# vi /etc/sysconfig/iptables

Сохраним изменения
[root@inetRouter vagrant]# iptables-save > /etc/sysconfig/iptables 

Перезапустим службу
[root@inetRouter vagrant]# systemctl restart iptables.service

Посмотрим список настроенных правил:
[root@inetRouter vagrant]# iptables-save
#Generated by iptables-save v1.4.21 on Sun Apr 23 15:09:12 2023
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
COMMIT
Completed on Sun Apr 23 15:09:12 2023

Включим на всех роутерах функцию пропускания транзитных пакетов:
Сделаем это, добавив в файл /etc/sysctl.conf: net.ipv4.ip_forward = 1
[root@inetRouter vagrant]# vi  /etc/sysctl.conf
Применим изменения и проверим статус
[root@inetRouter vagrant]# sysctl -p
[root@inetRouter vagrant]# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1

(как пример привёл только для одного роутера)

Теперь отключим маршрут по умолчанию на eth0 для centralRouter и centralServer.
Сделаем это через внесение изменений в /etc/sysconfig/network-scripts/ifcfg-eth0.
Vagrantfile не записывает в данный файл строку DEFROUTE=yes (разрешающую маршрут по умолчанию).
Поэтому просто допишем DEFROUTE=no.

У меня данные настройки уже были сделаны:
Содржание файла привожу
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
DEFROUTE=no

После удаление маршрута по умолчанию, нужно добавить дефолтный маршрут на другой порт.
[root@centralRouter vagrant]# echo "GATEWAY=192.168.0.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
[root@centralRouter vagrant]# systemctl restart network
[root@centralRouter vagrant]# cat /etc/sysconfig/network-scripts/ifcfg-eth1
#VAGRANT-BEGIN
#The contents below are automatically generated by Vagrant. Do not modify.
NM_CONTROLLED=yes
BOOTPROTO=none
ONBOOT=yes
IPADDR=192.168.255.2
NETMASK=255.255.255.252
DEVICE=eth1
PEERDNS=no
#VAGRANT-END
GATEWAY=192.168.255.1
GATEWAY=192.168.0.1

После выполнения данной команды мы видим что у нас 2 шлюза - так и должно быть?
Судя по записям в методичке модуль lineinfile для ansinle добавляет строку в файл. Если строка уже добавлена, то второй раз она не добавится. Он сверяет строку целиком? Если да, то тут тоже будет 2 записи.


Для centralServer уже прописан такой маршрут

# Настроим статическую маршрутизацию на серверах
Для настройки статических маршрутов используется команда ip route. Данная команда работает в Debian-based и RHEL-based системах.
Hассмотрим пример настройки статического маршрута на сервере office1Server. Исходя из схемы мы видим, что трафик с данного сервера будет идти через office1Router. Office1Server и office1Router у нас соединены через сеть managers (192.168.2.128/26). В статическом маршруте нужно указывать адрес следующего хоста. Таким образом мы должны указать на сервере office1Server маршрут, в котором доступ к любым IP-адресам у нас будет происходить через адрес 192.168.2.129, который расположен на сетевом интерфейсе office1Router. Команда будет выглядеть так: ip route add 0.0.0.0/0 via 192.168.2.129 

PS C:\git\MiFirstRepo> vagrant ssh office1Server
[vagrant@office1Server ~]$ sudo  su
[root@office1Server vagrant]# ip route add 0.0.0.0/0 via 192.168.2.129 
[root@office1Server vagrant]# ip route
default via 192.168.2.129 dev eth1 
default via 10.0.2.2 dev eth0 proto dhcp metric 100 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
192.168.2.128/26 dev eth1 proto kernel scope link src 192.168.2.130 metric 101 
192.168.50.0/24 dev eth2 proto kernel scope link src 192.168.50.21 metric 102  
[root@office1Server vagrant]# 

При такой настройке маршруты удалятся после перезагрузки сервера.
Для настройки на постоянной основе нужно создать файл /etc/sysconfig/network-scripts/route-eth1 и указать там правила в формате: <Сеть назначения>/<маска> via <Next hop address> (это для интерфейса ifcfg-eth1).

[root@office1Server vagrant]# cat /etc/sysconfig/network-scripts/route-eth1
 0.0.0.0/0 via 192.168.2.129
[root@office1Server vagrant]# systemctl restart network

 Сделаем аналогично для других серверов
[root@centralServer vagrant]# cat /etc/sysconfig/network-scripts/route-eth1
0.0.0.0/0 via 192.168.0.1
[root@centralServer vagrant]# systemctl restart network

[root@office2Server vagrant]# cat /etc/sysconfig/network-scripts/route-eth1
[root@office2Server vagrant]# cat /etc/sysconfig/network-scripts/route-eth1
0.0.0.0/0 via 192.168.1.1
8.8.8.8 via 192.168.1.1

Мы прописали статический маршрут для каждого сервера через его роутер 

Установим утилиту traceroute для просомтра корреткности маршрутов
[root@office2Server vagrant]# yum install -y traceroute

Теперь проверим корректность натсройки для office2Server
там записано 2 строки в /etc/sysconfig/network-scripts/route-eth1
0.0.0.0/0 via 192.168.1.1
8.8.8.8 via 192.168.1.1

А так же добавлена запись GATEWAY=192.168.1.1 в /etc/sysconfig/network-scripts/ifcfg-eth1
[root@office2Server vagrant]# cat /etc/sysconfig/network-scripts/ifcfg-eth1
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
NM_CONTROLLED=yes
BOOTPROTO=none
ONBOOT=yes
IPADDR=192.168.1.2
NETMASK=255.255.255.128
DEVICE=eth1
PEERDNS=no
#VAGRANT-END
GATEWAY=192.168.1.1

убедимся, что все интерфейсы включены
[root@office2Server vagrant]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:4d:77:d3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 86249sec preferred_lft 86249sec
    inet6 fe80::5054:ff:fe4d:77d3/64 scope link
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:f5:ad:4f brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.2/25 brd 192.168.1.127 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fef5:ad4f/64 scope link
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:c8:c9:87 brd ff:ff:ff:ff:ff:ff
    inet 192.168.50.31/24 brd 192.168.50.255 scope global noprefixroute eth2
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fec8:c987/64 scope link
       valid_lft forever preferred_lft forever

Построим трассеровку:
[root@office2Server vagrant]# traceroute 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  gateway (192.168.1.1)  12.363 ms  12.221 ms  12.032 ms
 Видм, что она пошла через 192.168.1.1