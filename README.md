# Задание:
1) в вагранте поднимаем 2 машины web и log
2) на web поднимаем nginx
3) на log настраиваем центральный лог сервер на любой системе на выбор
-journald;
-rsyslog;
-elk.
4) настраиваем аудит, следящий за изменением конфигов нжинкса
Все критичные логи с web должны собираться и локально и удаленно.
Все логи с nginx должны уходить на удаленный сервер (локально только критичные).
Логи аудита должны также уходить на удаленную систему.
Формат сдачи ДЗ - vagrant + ansible
развернуть еще машину elk*
-таким образом настроить 2 центральных лог системы elk и какую либо еще;
-в elk должны уходить только логи нжинкса;
- во вторую систему все остальное.
В чат ДЗ отправьте ссылку на ваш git-репозиторий . Обычно мы проверяем ДЗ в течение 48 часов.
Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Slack.
Удачи при выполнении!

# Критерии оценки:
Статус "Принято" ставится, если присылаете логи скриншоты без вагранта.
Задание со звездочкой выполняется по желанию.

# Решение:
Поднимим 2 виртульаные машины из Vagrantfile "web" (web - сервер) и "log" (сервер, где будем хранить логи).
C:\git\MiFirstRepo> vagrant up

## Настройка даты и времени на серверах
Подключимся к web-серверу, перейдём в режим суперпользователя и укажим время по Москве.
Аналjuично сделаем и для log - сервера.
Настройку приведу только для web, т.к. они идентичны
C:\git\MiFirstRepo> vagrant ssh web
[vagrant@web ~]$ sudo su
[root@web vagrant]# 
[root@web vagrant]# cp /usr/share/zoneinfo/Europe/Moscow /etc/localtime
cp: overwrite ‘/etc/localtime’? y
[root@web vagrant]# systemctl restart chronyd
[root@web vagrant]# systemctl status chronyd
● chronyd.service - NTP client/server
   Loaded: loaded (/usr/lib/systemd/system/chronyd.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2023-04-09 13:26:57 MSK; 5s ago
     Docs: man:chronyd(8)
           man:chrony.conf(5)
  Process: 3290 ExecStartPost=/usr/libexec/chrony-helper update-daemon (code=exited, status=0/SUCCESS)
  Process: 3286 ExecStart=/usr/sbin/chronyd $OPTIONS (code=exited, status=0/SUCCESS)
 Main PID: 3288 (chronyd)
   CGroup: /system.slice/chronyd.service
           └─3288 /usr/sbin/chronyd

Apr 09 13:26:57 web systemd[1]: Starting NTP client/server...
Apr 09 13:26:57 web chronyd[3288]: chronyd version 3.4 starting (+CMDMON +NTP +REFCLOCK +RTC +PRIVDROP +SCFILTER +SIGND +ASYNCDNS +SEC...6 +DEBUG)Apr 09 13:26:57 web chronyd[3288]: Frequency -7.086 +/- 4.848 ppm read from /var/lib/chrony/drift
Apr 09 13:26:57 web systemd[1]: Started NTP client/server.
Hint: Some lines were ellipsized, use -l to show in full.
[root@web vagrant]# date
Sun Apr  9 13:29:04 MSK 2023

## Установка nginx на web-сервере
[root@web vagrant]# yum install -y epel-release
[root@web vagrant]# yum install -y nginx

ПРоцесс загрузки и установления репозитория не привожу, что бы не захламлять данный файл

[root@web vagrant]# systemctl start nginx
[root@web vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2023-04-09 13:34:24 MSK; 3s ago
  Process: 3474 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3472 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3471 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3476 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3476 nginx: master process /usr/sbin/nginx
           └─3477 nginx: worker process

Apr 09 13:34:24 web systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 09 13:34:24 web nginx[3472]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 09 13:34:24 web nginx[3472]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Apr 09 13:34:24 web systemd[1]: Started The nginx HTTP and reverse proxy server.

Проверим, что сервер работает корреткно через curl (целиком вывод не привожу, тчо бы не захламлять файл)

[root@web vagrant]# curl http://192.168.1.30:80
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css">

## Настройка центрального сервера по сбору логов
Подключимся по ssh к log и перейдём в режим супервользователя (дату/время настроили ранее - см. комментарии выше)
PS C:\git\MiFirstRepo> vagrant ssh log
[vagrant@log ~]$ sudo su

Проверим установлен ли сервис управления логами Rsyslog
[root@log vagrant]# yum list rsyslog
Loaded plugins: fastestmirror
Determining fastest mirrors
 * base: mirror.corbina.net
 * extras: centos-mirror.rbc.ru
 * updates: centos-mirror.rbc.ru
base                                                                                                                       | 3.6 kB  00:00:00     
extras                                                                                                                     | 2.9 kB  00:00:00     
updates                                                                                                                    | 2.9 kB  00:00:00     
(1/4): base/7/x86_64/group_gz                                                                                              | 153 kB  00:00:00     
(2/4): extras/7/x86_64/primary_db                                                                                          | 249 kB  00:00:01     
(3/4): base/7/x86_64/primary_db                                                                                            | 6.1 MB  00:00:03     
(4/4): updates/7/x86_64/primary_db                                                                                         |  20 MB  00:00:08     
Installed Packages
rsyslog.x86_64                                                     8.24.0-52.el7                                                         @anacondaAvailable Packages
rsyslog.x86_64                                                     8.24.0-57.el7_9.3                                                     updates

Все настройки Rsyslog хранятся в файле /etc/rsyslog.conf
Для того, чтобы наш сервер мог принимать логи, нам необходимо внести следующие изменения в файл: 

[root@log vagrant]# vi /etc/rsyslog.conf

Открываем порт 514 (TCP и UDP): 
Находим закомментированные строки:
#Provides UDP syslog reception
#$ModLoad imudp
#$UDPServerRun 514

И приводим их к виду:
module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp")
input(type="imtcp" port="514")
В конец файла /etc/rsyslog.conf добавляем правила приёма сообщений от хостов (тут важно не накосячить с пробелами и запятыми):
#Add remote logs
$template RemoteLogs, "/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~

В данном примере мы создаем шаблон с названием RemoteLogs, который принимает логи всех категорий, любого уровня; логи, полученный по данному шаблону будут сохраняться в каталоге по маске /var/log/rsyslog/<имя компьютера, откуда пришел лог>/<приложение, чей лог пришел>.log; конструкция & ~ говорит о том, что после получения лога, необходимо остановить дальнейшую его обработку.

Данные параметры будут отправлять в папку /var/log/rsyslog логи, которые будут приходить от других серверов. Например, Access-логи nginx от сервера web, будут идти в файл /var/log/rsyslog/web/nginx_access.log

Перезапустим службу управления логами
[root@log vagrant]# systemctl restart rsyslog

Проверим открыт ли у нас 514 порт с помощью утилиты ss
[root@log vagrant]# ss -tuln | grep 514
udp    UNCONN     0      0         *:514                   *:*
udp    UNCONN     0      0      [::]:514                [::]:*
tcp    LISTEN     0      25        *:514                   *:*
tcp    LISTEN     0      25     [::]:514                [::]:*

## Настроим отправку логов с web-сервера

vagrant ssh web
sudo su

Проверяем версию nginx
[root@web vagrant]# rpm -qa | grep nginx
nginx-filesystem-1.20.1-10.el7.noarch
nginx-1.20.1-10.el7.x86_64

Версия старше 1.7 - удавлетворяет требованиям (т.к. только с этой версии у nginx появилась возможность
самостоятельно отправлять логи на сервер)

Находим в файле /etc/nginx/nginx.conf раздел с логами и приводим их к следующему виду (error_log и access_log
разные разделы файла конфигурации!!!):
error_log /var/log/nginx/error.log; 
error_log syslog:server=192.168.1.35:514,tag=nginx_error ;
access_log syslog:server=192.168.1.35:514,tag=nginx_access,severity=info combined ;
Tag нужен для того, чтобы логи записывались в разные файлы

[root@web vagrant]# vi /etc/nginx/nginx.conf

Проверим конфигурацию nginx после изменений
[root@web vagrant]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

Перезапустим nginx
[root@web vagrant]# systemctl restart nginx

Попробуем несколько раз зайти по адресу http://192.168.50.10 (сделаю это из хостовой машины через браузер)
Далее заходим на log-сервер и смотрим информацию об nginx:
(Если предварительно сэмитрировать ошибку на стороне nginx, то появится ещё и nginx_error.log)
[root@log vagrant]# cat /var/log/rsyslog/web/nginx_access.log 
Apr  9 16:37:43 web nginx_access: 192.168.1.65 - - [09/Apr/2023:16:37:43 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
Apr  9 16:37:44 web nginx_access: 192.168.1.65 - - [09/Apr/2023:16:37:44 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"

## Настройка аудита, контролирующего изменения конфигурации nginx
Проверим наличие утилиты для аудита
[root@web vagrant]# rpm -qa | grep audit
audit-2.8.5-4.el7.x86_64
audit-libs-2.8.5-4.el7.x86_64

Настроим аудит изменения конфигурации nginx через файл /etc/audit/rules.d/audit.rules
Добавим туда:
-w /etc/nginx/nginx.conf -p wa -k nginx_conf
-w /etc/nginx/default.d/ -p wa -k nginx_conf
Данные правила позволяют контролировать запись (w) и измения атрибутов (a) в:
/etc/nginx/nginx.conf
Всех файлов каталога /etc/nginx/default.d/
Для более удобного поиска к событиям добавляется метка nginx_conf

Перезапускаем службу auditd
[root@web vagrant]# service auditd restart
Stopping logging:                                          [  OK  ]
Redirecting start to /bin/systemctl start auditd.service

После данных изменений у нас начнут локально записываться логи аудита. Чтобы проверить, что логи аудита начали записываться локально, нужно внести изменения в файл /etc/nginx/nginx.conf или поменять его атрибут, потом посмотреть информацию об изменениях:
Также можно воспользоваться поиском по файлу /var/log/audit/audit.log, указав наш тэг: grep nginx_conf /var/log/audit/audit.log
(целиком вывод приводить не будут, что бы не захламлять файл)

[root@web vagrant]# ausearch -f /etc/nginx/nginx.conf
----
time->Sun Apr  9 17:15:55 2023
type=CONFIG_CHANGE msg=audit(1681049755.073:149): auid=1000 ses=2 op=updated_rules path="/etc/nginx/nginx.conf" key="nginx_conf" list=4 res=1     
----
time->Sun Apr  9 17:15:55 2023
type=PROCTITLE msg=audit(1681049755.073:150): proctitle=7669002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1681049755.073:150): item=3 name="/etc/nginx/nginx.conf~" inode=13224 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=CREATE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0


Далее настроим пересылку логов на удаленный сервер. Auditd по умолчанию не умеет пересылать логи, для пересылки на web-сервере потребуется установить пакет audispd-plugins:
[root@web vagrant]# yum -y install audispd-plugins

Найдем и поменяем следующие строки в файле /etc/audit/auditd.conf:
log_format = RAW
name_format = HOSTNAME
В файле /etc/audisp/plugins.d/au-remote.conf поменяем параметр active на yes
В файле /etc/audisp/audisp-remote.conf требуется указать адрес сервера и порт, на который будут отправляться логи
[root@web vagrant]# vi /etc/audit/auditd.conf
[root@web vagrant]# vi /etc/audisp/plugins.d/au-remote.conf
[root@web vagrant]# vi /etc/audisp/audisp-remote.conf

Перезапустим auditd
[root@web vagrant]# service auditd restart
Stopping logging:                                          [  OK  ]
Redirecting start to /bin/systemctl start auditd.service

## Настройка на сервере логов
Первым делом откроем 60 порт через файлик /etc/audit/auditd.conf и перезапустим службу аудита
[root@log vagrant]#  service auditd restart
Stopping logging:                                          [  OK  ]
Redirecting start to /bin/systemctl start auditd.service

Настройка закончина, поменяем что то в файле конфига nginx и проверим логи на лог-сервере (вывод неполный)
[root@log vagrant]# cat /var/log/audit/audit.log | grep web
node=web type=DAEMON_START msg=audit(1681050087.511:9187): op=start ver=2.8.5 format=raw kernel=3.10.0-1127.el7.x86_64 auid=4294967295 pid=1817 uid=0 ses=4294967295 subj=system_u:system_r:auditd_t:s0 res=success


# РЕАЛИЗУЕМ ЭТО ЧЕРЕЗ ANSIBLE
В моём распоряжении win-пк, поэтому ansible работает из wsl (настраивал для лабы по selinux - https://github.com/LedvNeon/MiFirstRepo/tree/selinux)
## Как это будет работать:
Я заранее подготовлю файлы конфигураций, что бы заменить их на хостах по средствам ansible.
Так же ansible установит все необходимые утилиты для работы.
Файлы конфигураций положим сюда \\wsl$\Ubuntu-20.04\home\dima\lab_for_logs  (в папки web и щп), а .vagrant (с информацией об образе, публичных ключах и пр. положим в \\wsl$\Ubuntu-20.04\home\dima).

ФАЙЛЫ, ПРИЛОЖЕННЫЕ В РЕПОЗИТОРИЙ НУЖНО СКАЧАТЬ И РАЗЛОЖИТЬ ПО ТАКИМ ЖЕ ДИРЕКТОРИЯМ
Просьба посомтреть, что не так с playbook - по отдельности (если делать разные playbook из кусков)
они отрабатывают. Когда внутри одного файла постоянно ругается на различные строки, как будто там ошибка 
в синтаксисе (хотя tab не использовал, файл делал в VSCode, что бы была разметка). Пример из приложенного Playbook:
ERROR! Syntax Error while loading YAML.
  did not find expected key

The error appears to be in '/home/dima/playbook.yml': line 27, column 5, but may
be elsewhere in the file depending on the exact syntax problem.

The offending line appears to be:


    - name: NGINX | Install NGINX package from EPEL Repo
    ^ here



