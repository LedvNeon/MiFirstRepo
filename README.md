<# ЗАДАЧА 1
Запустить nginx на нестандартном порту 3-мя разными способами:
переключатели setsebool;
добавление нестандартного порта в имеющийся тип;
формирование и установка модуля SELinux.
К сдаче:
README с описанием каждого решения (скриншоты и демонстрация приветствуются).#>
# Поднимаем VM из Vagrantfile - в процессе запуска, видим, что nginx не запустился 
    selinux: Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
    selinux: ● nginx.service - The nginx HTTP and reverse proxy server
    selinux:    Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
    selinux:    Active: failed (Result: exit-code) since Sun 2023-03-05 17:56:09 UTC; 68ms ago
    selinux:   Process: 2845 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
    selinux:   Process: 2843 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    selinux: 
    selinux: Mar 05 17:56:09 selinux nginx[2845]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    selinux: Mar 05 17:56:09 selinux nginx[2845]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
    selinux: Mar 05 17:56:09 selinux nginx[2845]: nginx: configuration file /etc/nginx/nginx.conf test failed
    selinux: Mar 05 17:56:09 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
    selinux: Mar 05 17:56:09 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
    selinux: Mar 05 17:56:09 selinux systemd[1]: Unit nginx.service entered failed state.
    selinux: Mar 05 17:56:09 selinux systemd[1]: nginx.service failed.
The SSH command responded with a non-zero exit status. Vagrant
assumes that this means the command failed. The output for this command
should be in the log above. Please read the output to determine what
went wrong.
vagrant up
# Подключаемся к пондятой VM по ssh
PS C:\git\MiFirstRepo> vagrant ssh
[vagrant@selinux ~]$ sudo su
[root@selinux vagrant]# 
# Проверим режим работы selinux
[root@selinux vagrant]# sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      31

# По задания нужно было отключить firewall - проверим
[root@selinux vagrant]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)

# Проверим конфигурацию nginx

[root@selinux vagrant]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

# Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool
# Находим в логах (/var/log/audit/audit.log) информацию о блокировании порта
[root@selinux vagrant]# cat /var/log/audit/audit.log | grep 4881
type=AVC msg=audit(1678038969.859:810): avc:  denied  { name_bind } for  pid=2845 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
# Ставим утилиты yum install policycoreutils-python (вывод большой, не прилагаю)
[root@selinux vagrant]# yum install policycoreutils-python
# Определим причину запрета доступа из файла аудита 
[root@selinux vagrant]# grep 1678038969.859:810  /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1678038969.859:810): avc:  denied  { name_bind } for  pid=2845 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1

# Мы видим, что нам нужно поменять параметр nis_enabled
# Включим параметр nis_enabled и перезапустим nginx
[root@selinux vagrant]# setsebool -P nis_enabled on
[root@selinux vagrant]# systemctl restart nginx
[root@selinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2023-03-05 18:16:13 UTC; 5s ago
  Process: 3129 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3127 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3125 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3131 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3131 nginx: master process /usr/sbin/nginx
           └─3132 nginx: worker process

Mar 05 18:16:13 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Mar 05 18:16:13 selinux nginx[3127]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Mar 05 18:16:13 selinux nginx[3127]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Mar 05 18:16:13 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.

[root@selinux vagrant]# curl http://localhost:4881
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css">
    #Вывод кода большой - приложил только кусок

# Проверим статус параметра nis_enabled
[root@selinux vagrant]# getsebool -a | grep nis_enabled
nis_enabled --> on

# Вернём запрет работы nginx на порту 4881 обратно и перезапустим nginx (не запустится)
[root@selinux vagrant]# setsebool -P nis_enabled off
[root@selinux vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.

# Теперь разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип
[root@selinux vagrant]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989

# Добавим порт в тип http_port_t (-a - добавить (add), -t (type) - тип, -p - протокол (protocol))
[root@selinux vagrant]# semanage port -a -t http_port_t -p tcp 4881
[root@selinux vagrant]# semanage port -l | grep  http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988

# Перезапустим nginx и проверим его работу
[root@selinux vagrant]# systemctl restart nginx
[root@selinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2023-03-05 18:25:39 UTC; 7s ago
  Process: 3181 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3179 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3177 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3183 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3183 nginx: master process /usr/sbin/nginx
           └─3184 nginx: worker process

Mar 05 18:25:38 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Mar 05 18:25:38 selinux nginx[3179]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Mar 05 18:25:38 selinux nginx[3179]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Mar 05 18:25:39 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.

# Удалим порт из списка разрешёных (параметр -d - delete)
[root@selinux vagrant]# semanage port -d -t http_port_t -p tcp 4881
[root@selinux vagrant]#
[root@selinux vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.

# Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux
# Для начала проверим лог
[root@selinux vagrant]# grep nginx /var/log/audit/audit.log
type=SYSCALL msg=audit(1678040869.236:890): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=557a0201d878 a2=10 a3=7ffe45738f30 items=0 ppid=1 pid=3201 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)
type=SERVICE_START msg=audit(1678040869.243:891): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'

# Воспользуемся утилитой audit2allow для того, чтобы на основе логов SELinux сделать модуль, разрешающий 
# работу nginx на нестандартном порту
[root@selinux vagrant]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp

# Audit2allow сформировал модуль, и сообщил нам команду, 
# с помощью которой можно применить данный модуль: semodule -i nginx.pp

[root@selinux vagrant]# semodule -i nginx.pp
[root@selinux vagrant]# 
[root@selinux vagrant]# systemctl start nginx
[root@selinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2023-03-05 18:34:19 UTC; 6s ago
  Process: 3229 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3227 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3225 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3231 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3231 nginx: master process /usr/sbin/nginx
           └─3232 nginx: worker process

Mar 05 18:34:19 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Mar 05 18:34:19 selinux nginx[3227]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Mar 05 18:34:19 selinux nginx[3227]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Mar 05 18:34:19 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.

# Посмотрим имеющиеся модули (их много вывод не приводил)
[root@selinux vagrant]# semodule -l
[root@selinux vagrant]# semodule -l | grep nginx
nginx   1.0

# Удалим созданный модуль (-r - remove - удалить)
[root@selinux vagrant]# semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
[root@selinux vagrant]# semodule -l | grep nginx

<# ЗАДАЧА 2
Обеспечить работоспособность приложения при включенном selinux.
развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems;
выяснить причину неработоспособности механизма обновления зоны (см. README);
предложить решение (или решения) для данной проблемы;
выбрать одно из решений для реализации, предварительно обосновав выбор;
реализовать выбранное решение и продемонстрировать его работоспособность.
К сдаче:
README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;
исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.#>

PS C:\> mkdir "homework_selinux"
PS C:\> cd homework_selinux
PS C:\homework_selinux> git clone https://github.com/mbfx/otus-linux-adm.git
Cloning into 'otus-linux-adm'...
remote: Enumerating objects: 558, done.
remote: Counting objects: 100% (456/456), done.
remote: Compressing objects: 100% (303/303), done.
Receiving objects: 100% (558/558), 1.38 MiB | 2.09 MiB/s, done.ed 102 eceiving objects:  88% (492/558), 1.08 MiB | 2.12 MiB/s   
Resolving deltas:  34% (48/140)


    Каталог: C:\homework_selinux


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        05.03.2023     21:42                otus-linux-adm


PS C:\homework_selinux> cd otus-linux-adm 
PS C:\homework_selinux\otus-linux-adm> vagrant init
PS C:\homework_selinux\otus-linux-adm> vagrant up
PS C:\homework_selinux\otus-linux-adm> vagrant status
Current machine states:
ns01                      running (virtualbox)
client                    running (virtualbox)

<# На самом деле на данном этапе машины из Vagrantfile развёртывал поочерёдно
+ ansible не работает, как сервер из под windows.
Сделал через wsl, подключив ubuntu wsl к поднятым vm через мост
В ubuntu wsl настроил ansible и с помощью playbook из https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problemsнастроил хосты для лабы #>

# Подулючаемся к клиенту и пробуем удалённо изменить данные в зоне dns ddns.lab
[root@client vagrant]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit
# Получаем ошибку update failed: SERVFAIL
# На клиенте ошибок нет
[root@client vagrant]# cat /var/log/audit/audit.log | audit2why
[root@client vagrant]# 
# Идём на сервер
[root@ns01 vagrant]# cat /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1678127747.047:2032): avc:  denied  { create } for  pid=4535 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
# В логах мы видим, что ошибка в контексте безопасности. Вместо типа named_t используется тип etc_t
# Проверим данную проблему в каталоге /etc/named
[root@ns01 vagrant]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab

# Тут мы также видим, что контекст безопасности неправильный. Проблема заключается в том, что конфигурационные # файлы лежат в другом каталоге.
# Посмотрим, где должны лежать, что бы политики применялись
[root@ns01 vagrant]# sudo semanage fcontext -l | grep named 
# Вывод достаточно большой - не прикладывал

# Изменим тип контекста безопасности для каталога /etc/named:
[root@ns01 vagrant]# sudo chcon -R -t named_zone_t /etc/named
[root@ns01 vagrant]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab

# Снова пробуем внести изменения с клиента
[root@client vagrant]# nsupdate -k /etc/named.zonetransfer.key                                                                  
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit 
# Ошибки нет
# Проверим работу
[root@ns01 vagrant]# dig www.ddns.lab
; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.7 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 52762
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.          IN  A

;; ANSWER SECTION:
www.ddns.lab.       60  IN  A   192.168.50.15

;; AUTHORITY SECTION:
ddns.lab.       3600    IN  NS  ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.       3600    IN  A   192.168.50.10

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Thu Nov 18 10:34:41 UTC 2021
;; MSG SIZE  rcvd: 96
[root@ns01 vagrant]#

# После перезагрузки так же всё ок
[root@ns01 vagrant]# dig @192.168.50.10 www.ddns.lab
; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.7 <<>> @192.168.50.10 www.ddns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 52392
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2


;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.          IN  A


;; ANSWER SECTION:
www.ddns.lab.       60  IN  A   192.168.50.15


;; AUTHORITY SECTION:
ddns.lab.       3600    IN  NS  ns01.dns.lab.


;; ADDITIONAL SECTION:
ns01.dns.lab.       3600    IN  A   192.168.50.10


;; Query time: 2 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Thu Nov 18 15:49:07 UTC 2021
;; MSG SIZE  rcvd: 96



