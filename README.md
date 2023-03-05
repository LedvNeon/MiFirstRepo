# При выполнении работы используется vm от лабы по nfs (клиент 192.168.50.12 - с него будут идти запросы на nginx) и
# и от лабы по systemd, находящиеся в одной подсети
# Обновим систему до актуальной (вывод очень большой - не привожу)
[root@testserv1 vagrant]# yum update 
# Добавим epel-release
[root@testserv1 vagrant]# yum install epel-release
# Так же допишем запись о нашем сервере в /etc/hosts
# Настроим простейший почтовый сервер на VM (подключена к основной через NAT и имеет отдельную сеть) - Postfix
# Т.к. сервер тестовый, выключим брандмауэр и уберём его из автозапуска
[root@testserv1 vagrant]# systemctl stop firewalld
[root@testserv1 vagrant]# systemctl disable firewalld
# Для проверки работы сервера нам понадобится ещё и telnet
[root@testserv1 vagrant]# yum install telnet
# Так же выключим selinux
[root@testserv1 vagrant]# sestatus
SELinux status:                 disabled
# Проверим установлен ли postfix
[root@testserv1 vagrant]# rpm -qa | grep postfix
postfix-2.10.1-9.el7.x86_64
# В файл конфигурации внесём следующие значения:
    <#
    myhostname = smtp (имя хоста почтового сервера)
    mydomain = domain.local (имя домена)
    myorigin = $mydomain (доменное имя, используемое в почте, отправленной с сервера - ссылаемся на mydomain)
    mydestination = $myhostname, localhost.$mydomain, mail.$mydomain, www.$mydomain, localhost 
    (домены -конечные точки)
    mail_spool_directory = /var/spool/mail (центральная директория очередей с файлом для каждого пользователя)
    mynetworks = 127.0.0.0/8, 192.168.50.0/24 (сети, обслуживаемые моим сервером, от других почта не будет пересылаться)
    inet_protocols = ipv4 (используемая версия протокола)
    home_mailbox = Maildir/ (директория, куда будут падать письма пользователя (/home/user/Maildir), не работает без mail_spool_directory)
    #>
# Перезапустим сервер postfix
[root@testserv1 vagrant]# systemctl restart postfix
# Проверим наличие ошибок
[root@testserv1 vagrant]# postfix check
# Ошибок не найдено
# Добавим postfix в автозагрузку и проверим его статус
[root@testserv1 vagrant]# systemctl enable postfix
[root@testserv1 vagrant]# systemctl status postfix
● postfix.service - Postfix Mail Transport Agent
   Loaded: loaded (/usr/lib/systemd/system/postfix.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2023-02-24 12:02:16 UTC; 2min 23s ago
 Main PID: 1257 (master)
   CGroup: /system.slice/postfix.service
           ├─1257 /usr/libexec/postfix/master -w
           ├─1258 pickup -l -t unix -u
           └─1259 qmgr -l -t unix -u
# Протестируем сервер
# 1) Создадим 2-х пользователей user1 и dima
useradd dima
passwd dima
useradd user1
passwd user1
# Отправим письмо
[root@testserv1 mail]# telnet localhost smtp
Trying ::1...
Connected to localhost.
Escape character is '^]'.
220 smtp ESMTP Postfix
ehlo
501 Syntax: EHLO hostname
ehlo localhost
250-smtp
250-PIPELINING
250-SIZE 10240000
250-VRFY
250-ETRN
250-ENHANCEDSTATUSCODES
250-8BITMIME
250 DSN
mail from:<dima@domain.local>
250 2.1.0 Ok
rcpt to:<user1@domain.local>
250 2.1.5 Ok
data
354 End data with <CR><LF>.<CR><LF>
test
.
250 2.0.0 Ok: queued as D2C8B4036DAE
quit
221 2.0.0 Bye
Connection closed by foreign host.
# Посомтрим пришло ли
cat /home/user1/Maildir/new/1677248972.V801I60919dcM435990.testserv1
Return-Path: <dima@domain.local>
X-Original-To: user1@domain.local
Delivered-To: user1@domain.local
Received: from localhost (localhost [IPv6:::1])
        by smtp (Postfix) with ESMTP id D2C8B4036DAE
        for <user1@domain.local>; Fri, 24 Feb 2023 14:29:13 +0000 (UTC)
Message-Id: <20230224142925.D2C8B4036DAE@smtp>
Date: Fri, 24 Feb 2023 14:29:13 +0000 (UTC)
From: dima@domain.local

test

# Теперь поднимем веб-сервер на nginx
[root@testserv1 mail]# yum install nginx
# Запустим веб-сервер и добавим в автозагрузку
[root@testserv1 mail]# systemctl start nginx
[root@testserv1 mail]# systemctl enable nginx
Created symlink from /etc/systemd/system/multi-user.target.wants/nginx.service to /usr/lib/systemd/system/nginx.service.
[root@testserv1 mail]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2023-02-24 14:47:35 UTC; 42s ago
 Main PID: 21030 (nginx)
   CGroup: /system.slice/nginx.service
           ├─21030 nginx: master process /usr/sbin/nginx
           └─21031 nginx: worker process

Feb 24 14:47:34 testserv1 systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 24 14:47:35 testserv1 nginx[21026]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 24 14:47:35 testserv1 nginx[21026]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Feb 24 14:47:35 testserv1 systemd[1]: Started The nginx HTTP and reverse proxy server.

# Установим утилиту mailx для работы с почтой (судя по всему она уже стояла на моём сервере) - с помощью неё скрипт будет отправлять письма
[root@testserv1 scripts]# yum install mailx
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
epel/x86_64/metalink                                                                          |  25 kB  00:00:00     
 * base: mirror.corbina.net
 * epel: mirror.yandex.ru
 * extras: mirror.docker.ru
 * updates: mirror.docker.ru
base                                                                                          | 3.6 kB  00:00:00     
epel                                                                                          | 4.7 kB  00:00:00     
extras                                                                                        | 2.9 kB  00:00:00     
updates                                                                                       | 2.9 kB  00:00:00     
(1/4): epel/x86_64/group_gz                                                                   |  99 kB  00:00:01     
(2/4): epel/x86_64/updateinfo                                                                 | 1.0 MB  00:00:02     
(3/4): updates/7/x86_64/primary_db                                                            |  19 MB  00:00:09     
(4/4): epel/x86_64/primary_db                                                                 | 7.0 MB  00:00:09     
Package mailx-12.5-19.el7.x86_64 already installed and latest version
Nothing to do

# Проверим работу mailx
[root@testserv1 scripts]# echo "Это тестовое письмо" | mail -s "Проверка отправки почты" dima@domain.local
[root@testserv1 scripts]# ls /home/dima/Maildir/new/
1678022358.V801I6091a4fM692725.testserv1
[root@testserv1 scripts]# cat /home/dima/Maildir/new/1678022358.V801I6091a4fM692725.testserv1 
Return-Path: <root@domain.local>
X-Original-To: dima@domain.local
Delivered-To: dima@domain.local
Received: by smtp (Postfix, from userid 0)
        id 9A575400A4C4; Sun,  5 Mar 2023 13:19:18 +0000 (UTC)
Date: Sun, 05 Mar 2023 13:19:18 +0000
To: dima@domain.local
Subject: =?utf-8?B?0J/RgNC+0LLQtdGA0LrQsCDQvtGC0L/RgNCw0LLQutC4INC/?=
  =?utf-8?B?0L7Rh9GC0Ys=?=
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit
Message-Id: <20230305131918.9A575400A4C4@smtp>
From: root@domain.local (root)

Это тестовое письмо

# Создадим скрипт в /home/vagrant/scripts - script.sh и дадим на него нужные права
touch /home/vagrant/scripts/script1.sh
chmod 751 script1.sh
# Данный скрипт отправляет на почту dima@domain.local информацию на текущий момент и инфо
# полученное час назад для сравнения

# Добавим расписание запуска скрипта в cron (@hourly - ежечастный запуск)
[root@testserv1 scripts]# cat /var/spool/cron/root
@hourly /home/vagrant/scripts/script1.sh