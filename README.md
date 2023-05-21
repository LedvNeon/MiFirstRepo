# Задание:
Между двумя виртуалками поднять vpn в режимах
tun;
tap;
Прочуствовать разницу.
Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на виртуалку.
Самостоятельно изучить, поднять ocserv и подключиться с хоста к виртуалке*

## Ручная настройка:
### Настройка сервера
Поднимим из Vagrantfile (из методички) 2 VM (изменил Vagrantfile, указав Centos/7)
PS C:\git\MiFirstRepo> vagrant up
Подключимся к серверу и перейдём в режим суперпользователя
PS C:\git\MiFirstRepo> vagrant ssh server
[vagrant@server ~]$ sudo su  
[root@server vagrant]# 

Устанавливаем epel репозиторий, устанавливаем пакет openvpn и iperf3, до перезагрузки отключаем SELinux.
[root@server vagrant]# yum install -y epel-release
[root@server vagrant]# yum install -y openvpn iperf3
[root@server vagrant]# setenforce 0
[root@server vagrant]# sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   permissive
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      31

openvpn - для настройки VPN
iperf3 - утилита для тестирования скорости

Создаём файл ключа
[root@server vagrant]# openvpn --genkey --secret /etc/openvpn/static.key
Создаём конфигурационный файл vpn-сервера со следующим содержимым:
1. dev tap
2. ifconfig 10.10.10.1 255.255.255.0
3. topology subnet
4. secret /etc/openvpn/static.key
5. comp-lzo
6. status /var/log/openvpn-status.log
7. log /var/log/openvpn.log
8. verb 3

[root@server vagrant]# vi /etc/openvpn/server.conf

Создадим service unit для запуска openvpn. Для этого создадим /etc/systemd/system/openvpn@.service со следующим содержимым:
1. [Unit]
2. Description=OpenVPN Tunneling Application On %I
3. After=network.target
4.
5. [Service]
6. Type=notify
7. PrivateTmp=true
8. ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf
9.
10. [Install]
11. WantedBy=multi-user.target

[root@server vagrant]# vi /etc/systemd/system/openvpn@.service

Запускаем openvpn сервер и добавляем в автозагрузку
[root@server vagrant]# systemctl start openvpn@server
[root@server vagrant]# systemctl enable openvpn@server
Created symlink from /etc/systemd/system/multi-user.target.wants/openvpn@server.service to /etc/systemd/system/openvpn@.service

### Настройка клиента:
PS C:\git\MiFirstRepo> vagrant ssh client
[vagrant@client ~]$ sudo su
[root@client vagrant]# 

[root@client vagrant]# yum install -y epel-release
root@client vagrant]# yum install -y openvpn iperf3
[root@client vagrant]# setenforce 0

Создаём конфигурационный файл клиента со следующим содержимым:
1. dev tap (описываем устр-во, которое создаём - tap - эмулирует канальный уровень)
2. remote 192.168.56.10 (удалённый сервер)
3. ifconfig 10.10.10.2 255.255.255.0 (адрес получаемый)
4. topology subnet (топология - подсеть)
5. route 192.168.56.0 255.255.255.0 ()
6. secret /etc/openvpn/static.key (ключ хранится тут)
7. comp-lzo
8. status /var/log/openvpn-status.log
9. log /var/log/openvpn.log
10. verb 3

[root@client vagrant]# mkdir /etc/openvpn
[root@client vagrant]# vi /etc/openvpn/server.conf

На сервер клиента в директорию /etc/openvpn необходимо скопироватьфайл-ключ static.key, который был создан на сервере.
[root@server vagrant]# systemctl start openvpn@server
[root@client vagrant]# systemctl enable openvpn@server
Created symlink from /etc/systemd/system/multi-user.target.wants/openvpn@server.service to /usr/lib/systemd/system/openvpn@.service.

Замерим скорость в туннеле
На сервере запустим iperf, как сервер, а на клиенте, как клиент, получаем:
[root@server vagrant]# iperf3 -s &
[1] 19890
[root@server vagrant]# -----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.10.2, port 35630
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 35632
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.00   sec  4.69 MBytes  39.4 Mbits/sec
[  5]   1.00-2.00   sec  5.31 MBytes  44.5 Mbits/sec
[  5]   2.00-3.01   sec  5.35 MBytes  44.7 Mbits/sec
[  5]   3.01-4.00   sec  5.17 MBytes  43.5 Mbits/sec
[  5]   4.00-5.00   sec  5.01 MBytes  42.1 Mbits/sec
[root@server vagrant]# [  5]  23.00-24.00  sec  4.15 MBytes  34.8 Mbits/sec
[  5]  24.00-25.00  sec  2.59 MBytes  21.7 Mbits/sec
[  5]  24.00-25.00  sec  2.59 MBytes  21.7 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-25.00  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-25.00  sec   116 MBytes  39.1 Mbits/sec                  receiver
iperf3: the client has terminated
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------

[root@client vagrant]# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 35632 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.01   sec  28.7 MBytes  48.1 Mbits/sec    0    974 KBytes
[  4]   5.01-10.00  sec  22.3 MBytes  37.4 Mbits/sec   25   1.09 MBytes
[  4]  10.00-15.01  sec  18.7 MBytes  31.3 Mbits/sec    6    930 KBytes
[  4]  15.01-20.00  sec  24.8 MBytes  41.8 Mbits/sec    0   1.06 MBytes
[  4]  20.00-25.00  sec  22.3 MBytes  37.3 Mbits/sec   31    779 KBytes
^C[  4]  25.00-25.50  sec  1.25 MBytes  21.1 Mbits/sec    0    820 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-25.50  sec   118 MBytes  38.8 Mbits/sec   62             sender
[  4]   0.00-25.50  sec  0.00 Bytes  0.00 bits/sec                  receiver
iperf3: interrupt - the client has terminated

## Теперь сделаем для режима работы tun (изменим тип в /etc/openvpn/server.conf, заменив tap на tun и на клиенте и на сервере)
[root@server vagrant]# vi /etc/openvpn/server.conf
[root@server vagrant]# systemctl restart openvpn@server

Вывод результата с клиента:
[root@client vagrant]# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 35636 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec  28.4 MBytes  47.6 Mbits/sec   23    378 KBytes
[  4]   5.00-10.00  sec  28.6 MBytes  48.0 Mbits/sec    0    403 KBytes       
[  4]  10.00-15.00  sec  24.2 MBytes  40.6 Mbits/sec    0    535 KBytes       
[  4]  15.00-20.00  sec  23.1 MBytes  38.8 Mbits/sec   10    620 KBytes       
[  4]  20.00-25.00  sec  27.3 MBytes  45.7 Mbits/sec    2    544 KBytes       
[  4]  25.00-30.00  sec  23.3 MBytes  39.2 Mbits/sec    0    560 KBytes       
[  4]  30.00-35.00  sec  19.4 MBytes  32.6 Mbits/sec    8    359 KBytes       
[  4]  35.00-40.00  sec  24.7 MBytes  41.5 Mbits/sec    0    388 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-40.00  sec   199 MBytes  41.7 Mbits/sec   43             sender
[  4]   0.00-40.00  sec   198 MBytes  41.4 Mbits/sec                  receiver

iperf Done.

# RAS на базе OpenVPN
На сервере установим:
[root@server vagrant]# yum install -y openvpn easy-rsa
Инициализируем pki
[root@server openvpn]# /usr/share/easy-rsa/3.0.8/easyrsa init-pki

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /etc/openvpn/pki

Сгенерируем необходимые ключи и сертификаты для сервера
[root@server openvpn]# echo 'rasvpn' | /usr/share/easy-rsa/3.0.8/easyrsa build-ca nopass
Using SSL: openssl OpenSSL 1.0.2k-fips  26 Jan 2017
Generating RSA private key, 2048 bit long modulus
....................................................................................+++
.....................................................+++
e is 65537 (0x10001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:
CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/etc/openvpn/pki/ca.crt


[root@server openvpn]# echo 'rasvpn' | /usr/share/easy-rsa/3.0.8/easyrsa gen-req server nopass
Using SSL: openssl OpenSSL 1.0.2k-fips  26 Jan 2017
Generating a 2048 bit RSA private key
.....+++
..........................+++
writing new private key to '/etc/openvpn/pki/easy-rsa-20098.ZakvQ5/tmp.g4kt9v'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [server]:
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/pki/reqs/server.req
key: /etc/openvpn/pki/private/server.key


[root@server openvpn]# echo 'yes' | /usr/share/easy-rsa/3.0.8/easyrsa sign-req server server
Using SSL: openssl OpenSSL 1.0.2k-fips  26 Jan 2017


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a server certificate for 825 days:

subject=
    commonName                = rasvpn


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: Using configuration from /etc/openvpn/pki/easy-rsa-20126.j6WTSV/tmp.kYSbdQ
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'rasvpn'
Certificate is to be certified until Aug 22 07:49:54 2025 GMT (825 days)

Write out database with 1 new entries
Data Base Updated

Certificate created at: /etc/openvpn/pki/issued/server.crt


[root@server openvpn]# /usr/share/easy-rsa/3.0.8/easyrsa gen-dh
Using SSL: openssl OpenSSL 1.0.2k-fips  26 Jan 2017
Generating DH parameters, 2048 bit long safe prime, generator 2
This is going to take a long time
........+..............................................+............................................................................................................................................................................................................................................+...........................................................................................+...............+..................+.........................................................+.....................+................................................................................................................................+.................................................................+...............+..........................................+...+......................................................................................+.......................................+.............+....................................................................................................................................+.......................................................................................................................................................+....................................................................................................+.......+.................+.............................................................................................................................................................................................................................................................................................+.................................................................................................................+.............+............................................................................................................................................................................................+........................................................................................+............+.........................................................................................+.....+......................................................................................................................................................................................................................+....................................................+.................................................................................................................+...............................+....................................................................................+....................................................+...+.................+.+..........................................................................................+...................................................................................................+................................................................+..............................................................+....................................................................................................................................................+..........................+.............................................................................+..........................................+..........................+...........................+............................................................................+.......................+..............................+......................................................................................................................................................+.....................................................................................................................................................+..................+....................................................................................+..+................+.....................................................+.....................................................+.................................................................................+....................+..............................................+.............+..................................................................+..............++*++*

DH parameters of size 2048 created at /etc/openvpn/pki/dh.pem


[root@server openvpn]# openvpn --genkey --secret ca.key

Посомтрим текущую версию easy-rsa
[root@server openvpn]# rpm -qa | grep easy-rsa
easy-rsa-3.0.8-1.el7.noarch

Сгенерируем сертфиикаты для клиента
[root@server openvpn]# echo 'client' | /usr/share/easy-rsa/3/easyrsa gen-req client nopass
Using SSL: openssl OpenSSL 1.0.2k-fips  26 Jan 2017
Generating a 2048 bit RSA private key
......................................................................+++
.+++
writing new private key to '/etc/openvpn/pki/easy-rsa-20214.C6k3t8/tmp.hLdx3k'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [client]:
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/pki/reqs/client.req
key: /etc/openvpn/pki/private/client.key


[root@server openvpn]# echo 'yes' | /usr/share/easy-rsa/3/easyrsa sign-req client client
Using SSL: openssl OpenSSL 1.0.2k-fips  26 Jan 2017


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a client certificate for 825 days:

subject=
    commonName                = client


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: Using configuration from /etc/openvpn/pki/easy-rsa-20242.ltB2eZ/tmp.17lOhM
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'client'
Certificate is to be certified until Aug 22 07:53:57 2025 GMT (825 days)

Write out database with 1 new entries
Data Base Updated

Certificate created at: /etc/openvpn/pki/issued/client.crt

Создадим конфигурационный файл /etc/openvpn/server.conf со следующим содержимым:
1. port 1207
2. proto udp
3. dev tun
4. ca /etc/openvpn/pki/ca.crt
5. cert /etc/openvpn/pki/issued/server.crt
6. key /etc/openvpn/pki/private/server.key
7. dh /etc/openvpn/pki/dh.pem
8. server 10.10.10.0 255.255.255.0
9. ifconfig-pool-persist ipp.txt
10. client-to-client
11. client-config-dir /etc/openvpn/client
12. keepalive 10 120
13. comp-lzo
14. persist-key
15. persist-tun
16. status /var/log/openvpn-status.log
17. log /var/log/openvpn.log
18. verb 3

Зададим параметр iroute для клиента
[root@server openvpn]# echo 'iroute 10.10.10.0 255.255.255.0' > /etc/openvpn/client/client

(При рестарте выпал в ошибку, но при старте после этого запустился корректно)

[root@server openvpn]# systemctl start openvpn@server
[root@server openvpn]# systemctl status openvpn@server
● openvpn@server.service - OpenVPN Tunneling Application On server
   Loaded: loaded (/etc/systemd/system/openvpn@.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2023-05-20 07:35:26 UTC; 23min ago
 Main PID: 19906 (openvpn)
   Status: "Initialization Sequence Completed"
   CGroup: /system.slice/system-openvpn.slice/openvpn@server.service
           └─19906 /usr/sbin/openvpn --cd /etc/openvpn/ --config server.conf

May 20 07:35:26 server.loc systemd[1]: Starting OpenVPN Tunneling Application On server...
May 20 07:35:26 server.loc systemd[1]: Started OpenVPN Tunneling Application On server.

## Настроим клиент - здесь я добавляю по сетевому адаптеру к каждой машине с типом "мост"
Предвариельно остановим openvpn@server на клиенте
Скопируем следующие файлы сертификатов и ключ для клиента на клиент в домашнюю директорию vagrant.
1. /etc/openvpn/pki/ca.crt
2. /etc/openvpn/pki/issued/client.crt
3. /etc/openvpn/pki/private/client.key

Создадим конфигурационны файл клиента client.conf на хост-машине в /etc/openvpn (там же лежат и ключи) со следующим содержанием:

1. dev tun
2. proto udp
3. remote 192.168.1.87 1207
4. client
5. resolv-retry infinite
6. remote-cert-tls server
7. ca /etc/openvpn/ca.crt
8. cert /etc/openvpn/client.crt
9. key /etc/openvpn/client.key
10. route 192.168.1.0 255.255.255.0
11. persist-key
12. persist-tun
13. comp-lzo
14. verb 3

Подключаемся к VPN-серверу
root@DESKTOP-9BHG4U3:/home/dima# openvpn --config /home/vagrant/client.conf

[root@client vagrant]# openvpn --config client.conf
Sat May 20 09:31:12 2023 WARNING: file './client.key' is group or others accessible
Sat May 20 09:31:12 2023 OpenVPN 2.4.12 x86_64-redhat-linux-gnu [Fedora EPEL patched] [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on Mar 17 2022
Sat May 20 09:31:12 2023 library versions: OpenSSL 1.0.2k-fips  26 Jan 2017, LZO 2.06
Sat May 20 09:31:12 2023 TCP/UDP: Preserving recently used remote address: [AF_INET]192.168.1.87:1207
Sat May 20 09:31:12 2023 Socket Buffers: R=[212992->212992] S=[212992->212992]
Sat May 20 09:31:12 2023 UDP link local (bound): [AF_INET][undef]:1194
Sat May 20 09:31:12 2023 UDP link remote: [AF_INET]192.168.1.87:1207
Sat May 20 09:31:12 2023 TLS: Initial packet from [AF_INET]192.168.1.87:1207, sid=00df7b18 5522c2c5
Sat May 20 09:31:12 2023 VERIFY OK: depth=1, CN=rasvpn
Sat May 20 09:31:12 2023 VERIFY KU OK
Sat May 20 09:31:12 2023 Validating certificate extended key usage
Sat May 20 09:31:12 2023 ++ Certificate has EKU (str) TLS Web Server Authentication, expects TLS Web Server Authentication       
Sat May 20 09:31:12 2023 VERIFY EKU OK
Sat May 20 09:31:12 2023 VERIFY OK: depth=0, CN=rasvpn
Sat May 20 09:31:12 2023 Control Channel: TLSv1.2, cipher TLSv1/SSLv3 ECDHE-RSA-AES256-GCM-SHA384, 2048 bit RSA
Sat May 20 09:31:12 2023 [rasvpn] Peer Connection Initiated with [AF_INET]192.168.1.87:1207
Sat May 20 09:31:13 2023 SENT CONTROL [rasvpn]: 'PUSH_REQUEST' (status=1)
Sat May 20 09:31:13 2023 PUSH: Received control message: 'PUSH_REPLY,topology net30,ping 10,ping-restart 120,ifconfig 10.10.10.6 
10.10.10.5,peer-id 0,cipher AES-256-GCM'
Sat May 20 09:31:13 2023 OPTIONS IMPORT: timers and/or timeouts modified
Sat May 20 09:31:13 2023 OPTIONS IMPORT: --ifconfig/up options modified
Sat May 20 09:31:13 2023 OPTIONS IMPORT: peer-id set
Sat May 20 09:31:13 2023 OPTIONS IMPORT: adjusting link_mtu to 1625
Sat May 20 09:31:13 2023 OPTIONS IMPORT: data channel crypto options modified
Sat May 20 09:31:13 2023 Data Channel: using negotiated cipher 'AES-256-GCM'
Sat May 20 09:31:13 2023 Outgoing Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
Sat May 20 09:31:13 2023 Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
Sat May 20 09:31:13 2023 ROUTE_GATEWAY 192.168.1.254/255.255.255.0 IFACE=eth2 HWADDR=08:00:27:8b:9a:0d
Sat May 20 09:31:13 2023 TUN/TAP device tun0 opened
Sat May 20 09:31:13 2023 TUN/TAP TX queue length set to 100
Sat May 20 09:31:13 2023 /sbin/ip link set dev tun0 up mtu 1500
Sat May 20 09:31:13 2023 /sbin/ip addr add dev tun0 local 10.10.10.6 peer 10.10.10.5
Sat May 20 09:31:13 2023 /sbin/ip route add 192.168.1.0/24 via 10.10.10.5
Sat May 20 09:31:13 2023 WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent thisSat May 20 09:31:13 2023 Initialization Sequence Completed

Проеряем доступность по адресу VPN
[root@client vagrant]# ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.202 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.112 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.330 ms

## Настройка через Ansible
Т.к. в моём распоряжении хостовая машина win10 с wsl2, изменим тип сети в Vagrantfile на мост.
Развёрнум заново 2 VM.
Сгенерируем ключи ssh для подключения из wsl и добавим их в /home/vagrant/.ssh/authorized_keys на server и client

Проверим доступность (файлы для ansible в директории /home/dima/iptables_lab)

root@DESKTOP-9BHG4U3:/home/dima/iptables_lab# ansible-playbook -i hosts ping.yml

PLAY [ping] ************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [server]
ok: [client]

TASK [ping] ************************************************************************************************************
ok: [server]
ok: [client]

PLAY RECAP *************************************************************************************************************
client                     : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
server                     : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

Playbook.yml приложен вместе с ansible.cfg, ping.yml, hosts.