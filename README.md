<# Созданы файлы скриптов nfsc_script.sh (для клиента) и nfscs_script.sh (для сервера) для настройки VM. Файлы лежат в текущем репозитории.
Их нужно положить в тот же каталог, что и Vagrantfile (так же находится в текущем репозитори). Vagrantfile поднимает 2 VM и настраивате NFS. 
Дальше проверяем, корреткность того, как скрипты отработали.
#>

# Проверяем настройки сервера

C:\Homework_NFS>vagrant ssh nfss # Подключаемся к серверу по ssh


[vagrant@nfss ~]$ sudo su # переходим в режим суперпользователя

[root@nfss vagrant]# systemctl status firewalld # проверяем хапущен ли firewall
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2023-01-30 08:40:19 UTC; 10min ago
     Docs: man:firewalld(1)
 Main PID: 3301 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3301 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Jan 30 08:40:17 nfss systemd[1]: Starting firewalld - dynamic firewall daemon...
Jan 30 08:40:19 nfss systemd[1]: Started firewalld - dynamic firewall daemon.
Jan 30 08:40:20 nfss firewalld[3301]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure con...t now.
Jan 30 08:40:23 nfss firewalld[3301]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure con...t now.
Hint: Some lines were ellipsized, use -l to show in full.

[root@nfss vagrant]# ss -tnplu # смотрим прослушиваемые порты - проверяем наличие 2049/udp, 2049/tcp, 20048/udp,  20048/tcp, 111/udp, 111/tcp
Netid  State      Recv-Q Send-Q            Local Address:Port                           Peer Address:Port
udp    UNCONN     0      0                     127.0.0.1:323                                       *:*                   users:(("chronyd",pid=390,fd=5))
udp    UNCONN     0      0                             *:68                                        *:*                   users:(("dhclient",pid=2402,fd=6))
udp    UNCONN     0      0                             *:20048                                     *:*                   users:(("rpc.mountd",pid=3455,fd=7))
udp    UNCONN     0      0                             *:111                                       *:*                   users:(("rpcbind",pid=342,fd=6))
udp    UNCONN     0      0                     127.0.0.1:659                                       *:*                   users:(("rpc.statd",pid=3447,fd=10))
udp    UNCONN     0      0                             *:931                                       *:*                   users:(("rpcbind",pid=342,fd=7))
udp    UNCONN     0      0                             *:56503                                     *:*                   users:(("rpc.statd",pid=3447,fd=7))
udp    UNCONN     0      0                             *:39369                                     *:*
udp    UNCONN     0      0                             *:2049                                      *:*
udp    UNCONN     0      0                         [::1]:323                                    [::]:*                   users:(("chronyd",pid=390,fd=6))
udp    UNCONN     0      0                          [::]:20048                                  [::]:*                   users:(("rpc.mountd",pid=3455,fd=9))
udp    UNCONN     0      0                          [::]:42579                                  [::]:*
udp    UNCONN     0      0                          [::]:111                                    [::]:*                   users:(("rpcbind",pid=342,fd=9))
udp    UNCONN     0      0                          [::]:46213                                  [::]:*                   users:(("rpc.statd",pid=3447,fd=9))
udp    UNCONN     0      0                          [::]:931                                    [::]:*                   users:(("rpcbind",pid=342,fd=10))
udp    UNCONN     0      0                          [::]:2049                                   [::]:*
tcp    LISTEN     0      64                            *:40843                                     *:*
tcp    LISTEN     0      128                           *:111                                       *:*                   users:(("rpcbind",pid=342,fd=8))
tcp    LISTEN     0      128                           *:20048                                     *:*                   users:(("rpc.mountd",pid=3455,fd=8))
tcp    LISTEN     0      128                           *:22                                        *:*                   users:(("sshd",pid=690,fd=3))
tcp    LISTEN     0      100                   127.0.0.1:25                                        *:*                   users:(("master",pid=969,fd=13))
tcp    LISTEN     0      64                            *:2049                                      *:*
tcp    LISTEN     0      128                           *:34915                                     *:*                   users:(("rpc.statd",pid=3447,fd=8))
tcp    LISTEN     0      128                        [::]:33452                                  [::]:*                   users:(("rpc.statd",pid=3447,fd=11))
tcp    LISTEN     0      128                        [::]:111                                    [::]:*                   users:(("rpcbind",pid=342,fd=11))
tcp    LISTEN     0      128                        [::]:20048                                  [::]:*                   users:(("rpc.mountd",pid=3455,fd=10))
tcp    LISTEN     0      128                        [::]:22                                     [::]:*                   users:(("sshd",pid=690,fd=4))
tcp    LISTEN     0      100                       [::1]:25                                     [::]:*                   users:(("master",pid=969,fd=14))
tcp    LISTEN     0      64                         [::]:2049                                   [::]:*
tcp    LISTEN     0      64                         [::]:45572                                  [::]:*

# проверим создалась ли директория и права на неё
[root@nfss vagrant]# cd /srv/share/
[root@nfss share]# ls -la
total 0
drwxr-xr-x. 3 nfsnobody nfsnobody 20 Jan 30 08:40 .
drwxr-xr-x. 3 root      root      19 Jan 30 08:40 ..
drwxrwxrwx. 2 nfsnobody nfsnobody  6 Jan 30 08:40 upload

# проверяем экспортированную директорию
[root@nfss share]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[root@nfss share]# cat /etc/exports
/srv/share 192.168.50.11/32(rw,sync,root_squash)


# Проверяем настройки клиента

C:\Homework_NFS>vagrant ssh nfsc  # подключаемся к клиенту

[vagrant@nfsc ~]$ sudo su # переходим в режим суперпользователя

[root@nfsc vagrant]# systemctl status firewalld # проверяем работу брандмауэра
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2023-01-30 08:43:06 UTC; 55min ago
     Docs: man:firewalld(1)
 Main PID: 3300 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3300 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Jan 30 08:43:05 nfsc systemd[1]: Starting firewalld - dynamic firewall daemon...
Jan 30 08:43:06 nfsc systemd[1]: Started firewalld - dynamic firewall daemon.
Jan 30 08:43:07 nfsc firewalld[3300]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option. ... it now.
Hint: Some lines were ellipsized, use -l to show in full.

[root@nfsc vagrant]# cat /etc/fstab # смотрим содежимое /etc/fstab

#
# /etc/fstab
# Created by anaconda on Thu Apr 30 22:04:55 2020
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=1c419d6c-5064-4a2b-953c-05b2c67edb15 /                       xfs     defaults        0 0
/swapfile none swap defaults 0 0
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#VAGRANT-END
192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0
[root@nfsc vagrant]# mount | grep mnt # проверяем успешность монтирования
systemd-1 on /mnt type autofs (rw,relatime,fd=42,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=25481)

#ВСЕ НАСТРОЙКИ ВЫПОЛНЕНЫ КОРРЕКТНО
#ПРОВЕРИМ РАБОТОСПОСОБНОСТЬ:

#НА СЕРВЕРЕ:

C:\Homework_NFS>vagrant ssh nfss
Last login: Mon Jan 30 08:43:40 2023 from 10.0.2.2
[vagrant@nfss ~]$ sudo su
[root@nfss vagrant]# cd /srv/share/upload
[root@nfss upload]# touch check_file
[root@nfss upload]# ls
check_file

#НА КЛИЕНТЕ:
[root@nfsc mnt]# shutdown -r 0 # перезагрузка
Shutdown scheduled for Mon 2023-01-30 12:32:40 UTC, use 'shutdown -c' to cancel.
[root@nfsc mnt]# Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.

C:\Homework_NFS>vagrant ssh nfsc
Last login: Mon Jan 30 09:50:19 2023 from 10.0.2.2
[vagrant@nfsc ~]$ sudo su
[root@nfsc vagrant]# cd /mnt/upload 
[root@nfsc upload]# ls # проверим, что файл виден после перезагрузки
check_file

#НА СЕРВЕРЕ:
[root@nfss upload]# shutdown -r 0 # перезагрузка
Shutdown scheduled for Mon 2023-01-30 12:38:16 UTC, use 'shutdown -c' to cancel.
[root@nfss upload]# Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.

C:\Homework_NFS>vagrant ssh nfss
Last login: Mon Jan 30 09:46:10 2023 from 10.0.2.2
[vagrant@nfss ~]$ sudo su
[root@nfss vagrant]# cd /srv/share/upload/
[root@nfss upload]# ls # проверим, что файл виден после перезагрузки
check_file

[root@nfss upload]# systemctl status nfs # проверка статусы службы
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Mon 2023-01-30 12:51:52 UTC; 2min 49s ago
  Process: 828 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 808 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 803 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 808 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Jan 30 12:51:52 nfss systemd[1]: Starting NFS server and services...
Jan 30 12:51:52 nfss systemd[1]: Started NFS server and services.

[root@nfss upload]# systemctl status firewalld # проверка статуса брандмауэра
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2023-01-30 12:51:46 UTC; 3min 20s ago
     Docs: man:firewalld(1)
 Main PID: 405 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─405 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Jan 30 12:51:43 nfss systemd[1]: Starting firewalld - dynamic firewall daemon...
Jan 30 12:51:46 nfss systemd[1]: Started firewalld - dynamic firewall daemon.
Jan 30 12:51:46 nfss firewalld[405]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option. I... it now.
Hint: Some lines were ellipsized, use -l to show in full.

[root@nfss upload]# exportfs -s # проверка экспортируемой директории
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)

[root@nfss upload]# showmount -a 192.168.50.10 # проверка видимости nfs сервера с шарой по сети с самого сервера
All mount points on 192.168.50.10:
192.168.50.11:/srv/share

#НА КЛИЕНТЕ:
[root@nfsc upload]# shutdown -r 0 # перезагрузка
Shutdown scheduled for Mon 2023-01-30 12:56:30 UTC, use 'shutdown -c' to cancel.
[root@nfsc upload]# Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
C:\Homework_NFS>vagrant ssh nfsc
Last login: Mon Jan 30 12:46:52 2023 from 10.0.2.2
[vagrant@nfsc ~]$ sudo su
[root@nfsc vagrant]#
[root@nfsc vagrant]# showmount -a 192.168.50.10 # проверка видимости nfs сервера с шарой по сети с клиента 
All mount points on 192.168.50.10:
[root@nfsc vagrant]# cd /mnt/upload
[root@nfsc upload]# ls
[root@nfsc upload]# mount | grep mn
systemd-1 on /mnt type autofs (rw,relatime,fd=27,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=11062)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
[root@nfsc upload]# touch final_chec # создание файла с клиента в шаре
[root@nfsc upload]# ls # проверим, что файл создан
check_file  final_chec