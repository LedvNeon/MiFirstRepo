# Домашняя работа по SYSTEMD

<# Задание:
Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig).
Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).
Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.#>

#Решение:
<#Решение поставленных задач реализовано через Vagrantfile и скрипт - script.sh, загруженные в данный репозиторий с комментариями внутри. Необходимо скачать Vagrantfile и script.sh, поместить их в одну директорию и выполнить Vagrant up. В результате мы получим vm с поднятыми и настроенными сервисами. Результат проверки прикладываю ниже#>

PS C:\git\MiFirstRepo> vagrant ssh
[vagrant@testserv1 ~]$ sudo su

# Проверка работы сервиса по поиску слова в файле лога
[root@testserv1 vagrant]# tail -f /var/log/messages
Feb 10 13:28:22 localhost su: (to root) vagrant on pts/0
Feb 10 13:28:50 localhost systemd: Starting My watchlog service...
Feb 10 13:28:50 localhost root: Fri Feb 10 13:28:50 UTC 2023: I found word, Master!
Feb 10 13:28:50 localhost systemd: Started My watchlog service.
Feb 10 13:29:20 localhost systemd: Starting My watchlog service...
Feb 10 13:29:20 localhost root: Fri Feb 10 13:29:20 UTC 2023: I found word, Master!
Feb 10 13:29:20 localhost systemd: Started My watchlog service.
Feb 10 13:29:50 localhost systemd: Starting My watchlog service...

# Проверка работы spawn-fcgi
[root@testserv1 vagrant]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2023-02-10 13:26:10 UTC; 4min 9s ago
 Main PID: 3451 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─3451 /usr/bin/php-cgi
           ├─3458 /usr/bin/php-cgi
           ├─3459 /usr/bin/php-cgi
           ├─3460 /usr/bin/php-cgi
           ├─3461 /usr/bin/php-cgi
           ├─3462 /usr/bin/php-cgi
           ├─3463 /usr/bin/php-cgi
           ├─3464 /usr/bin/php-cgi
           ├─3465 /usr/bin/php-cgi
           ├─3466 /usr/bin/php-cgi
           ├─3467 /usr/bin/php-cgi
           ├─3468 /usr/bin/php-cgi
           ├─3469 /usr/bin/php-cgi
           ├─3470 /usr/bin/php-cgi
           ├─3471 /usr/bin/php-cgi
           ├─3472 /usr/bin/php-cgi
           ├─3473 /usr/bin/php-cgi
           ├─3474 /usr/bin/php-cgi
           ├─3476 /usr/bin/php-cgi
           ├─3477 /usr/bin/php-cgi
           ├─3478 /usr/bin/php-cgi
           ├─3479 /usr/bin/php-cgi
           ├─3480 /usr/bin/php-cgi
           ├─3481 /usr/bin/php-cgi
           ├─3482 /usr/bin/php-cgi
           ├─3483 /usr/bin/php-cgi
           ├─3484 /usr/bin/php-cgi
           ├─3485 /usr/bin/php-cgi
           ├─3486 /usr/bin/php-cgi
           ├─3487 /usr/bin/php-cgi
           ├─3488 /usr/bin/php-cgi
           ├─3489 /usr/bin/php-cgi
           └─3490 /usr/bin/php-cgi

# Список прослушиваемых портов
[root@testserv1 vagrant]# ss -tnulp | grep httpd
tcp    LISTEN     0      128    [::]:8080               [::]:*                   users:(("httpd",pid=3502,fd=4),("httpd",pid=3501,fd=4),("httpd",pid=3500,fd=4),("httpd",pid=3499,fd=4),("httpd",pid=3498,fd=4),("httpd",pid=3497,fd=4))
tcp    LISTEN     0      128    [::]:80                 [::]:*                   users:(("httpd",pid=3496,fd=4),("httpd",pid=3495,fd=4),("httpd",pid=3494,fd=4),("httpd",pid=3493,fd=4),("httpd",pid=3492,fd=4),("httpd",pid=3475,fd=4))

# Статус httpd сервисов
[root@testserv1 vagrant]# systemctl status httpd@first
● httpd@first.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2023-02-10 13:26:11 UTC; 12min ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 3475 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/system-httpd.slice/httpd@first.service
           ├─3475 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND
           ├─3492 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND
           ├─3493 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND
           ├─3494 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND
           ├─3495 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND
           └─3496 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND

Feb 10 13:26:11 testserv1 systemd[1]: Starting The Apache HTTP Server...
Feb 10 13:26:11 testserv1 httpd[3475]: AH00558: httpd: Could not reliably determine the server's fully qualified domain...essageFeb 10 13:26:11 testserv1 systemd[1]: Started The Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.
[root@testserv1 vagrant]# systemctl status httpd@second
● httpd@second.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2023-02-10 13:26:11 UTC; 12min ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 3497 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/system-httpd.slice/httpd@second.service
           ├─3497 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─3498 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─3499 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─3500 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─3501 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           └─3502 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND

Feb 10 13:26:11 testserv1 systemd[1]: Starting The Apache HTTP Server...
Feb 10 13:26:11 testserv1 httpd[3497]: AH00558: httpd: Could not reliably determine the server's fully qualified domain...essageFeb 10 13:26:11 testserv1 systemd[1]: Started The Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.