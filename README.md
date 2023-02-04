<#Прежде чем настраивать запуск VM из Vagrantfile с использованием скрипта проверил последовательность действий на VM из лабы по NFS.
Файл скрипта - Script.sh. Его нужно будет при развёртывании поместить в ту же директорию, где лежит Vagrantfile.
Далее лог настрйоки на nfss.#>

#Устанавливаем необходимые пакеты (тут вывод команд не прикладывал)
yum install -y \
redhat-lsb-core \
wget \
rpmdevtools \
rpm-build \
createrepo \
yum-utils \
gcc
				
#Скачиваем архив с apache
wget --no-check-certificate https://dlcdn.apache.org/httpd/httpd-2.4.55.tar.bz2
--2023-02-01 19:36:22--  https://dlcdn.apache.org/httpd/httpd-2.4.55.tar.bz2
Resolving dlcdn.apache.org (dlcdn.apache.org)... 151.101.2.132, 2a04:4e42::644
Connecting to dlcdn.apache.org (dlcdn.apache.org)|151.101.2.132|:443... connected.
WARNING: cannot verify dlcdn.apache.org's certificate, issued by ‘/C=US/O=Let's Encrypt/CN=R3’:
  Issued certificate has expired.
HTTP request sent, awaiting response... 200 OK
Length: 7456187 (7.1M) [application/x-bzip2]
Saving to: ‘httpd-2.4.55.tar.bz2’

100%[==============================================================================>] 7,456,187   3.26MB/s   in 2.2s

2023-02-01 19:36:25 (3.26 MB/s) - ‘httpd-2.4.55.tar.bz2’ saved [7456187/7456187]

#Проверим, что скачался
[root@nfss vagrant]# ls
httpd-2.4.55.tar.bz2

# Преобразуем скачанный пакет в SRPM
[root@nfss vagrant]# rpmbuild -ts httpd-2.4.55.tar.bz2
Wrote: /root/rpmbuild/SRPMS/httpd-2.4.55-1.src.rpm

# Посмотрим содержимое файла, куда выгрузился пакет
[root@nfss vagrant]# ls /root/rpmbuild/SRPMS/
httpd-2.4.55-1.src.rpm

#Проверим, что нужные файлы создались
[root@nfss vagrant]# ls /root/rpmbuild/
BUILD  BUILDROOT  RPMS  SOURCES  SPECS  SRPMS
[root@nfss vagrant]# ls /root/rpmbuild/SPECS/
httpd.spec

#Скачиваем последние исходники OpenSSL и разархивируем их
wget https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip
unzip OpenSSL_1_1_1-stable.zip
#Вывод огромный - результат ниже:
[root@nfss vagrant]# ls /home/vagrant/
httpd-2.4.55.tar.bz2  OpenSSL_1_1_1-stable.zip  openssl-OpenSSL_1_1_1-stable

#Поставим все зависимости чтобы в процессе сборки не было ошибок
[root@nfss vagrant]# yum-builddep /root/rpmbuild/SPECS/httpd.spec
#Вывод огромный - не прикладывал, что бы не захламлять

#Изменим строку в файле spec для apache 
sed 's!%{_libdir}/httpd/modules/mod_mpm_event.so!#%{_libdir}/httpd/modules/mod_mpm_event.so!' /root/rpmbuild/SPECS/httpd.spec
#Здесь выводится результат - т.е. весь файл после выполнения команды, можно сразу увидеть изменилась строка или нет

#Соберём пакет
rpmbuild -bb /root/rpmbuild/SPECS/httpd.spec
#Вывод огромный - не прикладывал, что бы не захламлять

#Проверим, что пакеты создались:
[root@nfss vagrant]# ls /root/rpmbuild/RPMS/x86_64/
httpd-2.4.55-1.x86_64.rpm            httpd-manual-2.4.55-1.x86_64.rpm     mod_lua-2.4.55-1.x86_64.rpm
httpd-debuginfo-2.4.55-1.x86_64.rpm  httpd-tools-2.4.55-1.x86_64.rpm      mod_proxy_html-2.4.55-1.x86_64.rpm
httpd-devel-2.4.55-1.x86_64.rpm      mod_authnz_ldap-2.4.55-1.x86_64.rpm  mod_ssl-2.4.55-1.x86_64.rpm

#Установим apache
[root@nfss vagrant]# yum localinstall -y /root/rpmbuild/RPMS/x86_64/httpd-2.4.55-1.x86_64.rpm
Loaded plugins: fastestmirror
Examining /root/rpmbuild/RPMS/x86_64/httpd-2.4.55-1.x86_64.rpm: httpd-2.4.55-1.x86_64
Marking /root/rpmbuild/RPMS/x86_64/httpd-2.4.55-1.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package httpd.x86_64 0:2.4.55-1 will be installed
--> Processing Dependency: /etc/mime.types for package: httpd-2.4.55-1.x86_64
Loading mirror speeds from cached hostfile
 * base: mirror.yandex.ru
 * extras: mirror.yandex.ru
 * updates: mirror.yandex.ru
base                                                                                                                                 | 3.6 kB  00:00:00
extras                                                                                                                               | 2.9 kB  00:00:00
updates                                                                                                                              | 2.9 kB  00:00:00
--> Running transaction check
---> Package mailcap.noarch 0:2.1.41-2.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

============================================================================================================================================================
 Package                         Arch                           Version                                Repository                                      Size
============================================================================================================================================================
Installing:
 httpd                           x86_64                         2.4.55-1                               /httpd-2.4.55-1.x86_64                         4.3 M
Installing for dependencies:
 mailcap                         noarch                         2.1.41-2.el7                           base                                            31 k

Transaction Summary
============================================================================================================================================================
Install  1 Package (+1 Dependent package)

Total size: 4.3 M
Total download size: 31 k
Installed size: 4.4 M
Downloading packages:
mailcap-2.1.41-2.el7.noarch.rpm                                                                                                      |  31 kB  00:00:01
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : mailcap-2.1.41-2.el7.noarch                                                                                                              1/2
  Installing : httpd-2.4.55-1.x86_64                                                                                                                    2/2
  Verifying  : httpd-2.4.55-1.x86_64                                                                                                                    1/2
  Verifying  : mailcap-2.1.41-2.el7.noarch                                                                                                              2/2

Installed:
  httpd.x86_64 0:2.4.55-1

Dependency Installed:
  mailcap.noarch 0:2.1.41-2.el7

Complete!

#Запустим сервис и проверим, заработал ли
[root@nfss vagrant]# systemctl status httpd
● httpd.service - LSB: start and stop Apache HTTP Server
   Loaded: loaded (/etc/rc.d/init.d/httpd; bad; vendor preset: disabled)
   Active: inactive (dead)
     Docs: man:systemd-sysv-generator(8)
	 
[root@nfss vagrant]# systemctl start httpd

[root@nfss vagrant]# systemctl status httpd
● httpd.service - LSB: start and stop Apache HTTP Server
   Loaded: loaded (/etc/rc.d/init.d/httpd; bad; vendor preset: disabled)
   Active: active (running) since Sat 2023-02-04 09:18:22 UTC; 22s ago
     Docs: man:systemd-sysv-generator(8)
 Main PID: 30616 (httpd)
   CGroup: /system.slice/httpd.service
           ├─30616 /usr/sbin/httpd
           ├─30618 /usr/sbin/httpd
           ├─30619 /usr/sbin/httpd
           └─30620 /usr/sbin/httpd

Feb 04 09:18:22 nfss systemd[1]: Starting LSB: start and stop Apache HTTP Server...
Feb 04 09:18:22 nfss httpd[30605]: Starting httpd: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using...is message
Feb 04 09:18:22 nfss httpd[30605]: [  OK  ]
Feb 04 09:18:22 nfss systemd[1]: Started LSB: start and stop Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.

<#Создадим свой репозиторий (в каталоге, из которого apache тянет код для сайта). 
скопируем туда собраный rpm пакет и добавим, как описано в методичке, RPM для установки репозитория Percona-Server#>
[root@nfss test1]# mkdir /var/www/html/repo

[root@nfss vagrant]# cp /root/rpmbuild/RPMS/x86_64/httpd-2.4.55-1.x86_64.rpm /var/www/html/repo

[root@nfss vagrant]# wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm -O /var/www/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm
--2023-02-04 10:18:16--  https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm
Resolving downloads.percona.com (downloads.percona.com)... 74.121.199.231, 162.220.4.222, 162.220.4.221
Connecting to downloads.percona.com (downloads.percona.com)|74.121.199.231|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 5222976 (5.0M) [application/octet-stream]
Saving to: ‘/var/www/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm’

100%[==================================================================================================================>] 5,222,976   2.65MB/s   in 1.9s

2023-02-04 10:18:19 (2.65 MB/s) - ‘/var/www/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm’ saved [5222976/5222976]

[root@nfss vagrant]# ls /var/www/html/repo
httpd-2.4.55-1.x86_64.rpm  percona-orchestrator-3.2.6-2.el8.x86_64.rpm

[root@nfss vagrant]# createrepo /var/www/html/repo/
Spawning worker 0 with 2 pkgs
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete

<#Внесём изменения в /etc/httpd/conf/httpd.conf
меняем Options Indexes FollowSymLinks на Options Indexes Includes
делал через VI, поэтому не приложил вывод#>

#Проверим, что всё получилось после перезапуска сервиса
[root@nfss vagrant]# curl http://localhost/repo/
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
 <head>
  <title>Index of /repo</title>
 </head>
 <body>
<h1>Index of /repo</h1>
<ul><li><a href="/"> Parent Directory</a></li>
<li><a href="httpd-2.4.55-1.x86_64.rpm"> httpd-2.4.55-1.x86_64.rpm</a></li>
<li><a href="percona-orchestrator-3.2.6-2.el8.x86_64.rpm"> percona-orchestrator-3.2.6-2.el8.x86_64.rpm</a></li>
<li><a href="repodata/"> repodata/</a></li>
</ul>
</body></html>

#Добавим репозиторий в /etc/yum.repos.d
[root@nfss vagrant]# cat >> /etc/yum.repos.d/otus.repo << EOF
> [otus]
> name=otus-linux
> baseurl=http://localhost/repo
> gpgcheck=0
> enabled=1
> EOF

#Проверим, что всё ок
[root@nfss vagrant]# yum repolist enabled | grep otus
otus                                otus-linux                                 2

[root@nfss test1]# yum list | grep otus
percona-orchestrator.x86_64                 2:3.2.6-2.el8              otus
#Здесь почему то не отобразился apache, но, при выполнении wget он загружается (ниже лог)
[root@nfss test1]# wget http://localhost/repo/httpd-2.4.55-1.x86_64.rpm
--2023-02-04 10:35:12--  http://localhost/repo/httpd-2.4.55-1.x86_64.rpm
Resolving localhost (localhost)... ::1, 127.0.0.1
Connecting to localhost (localhost)|::1|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 1402908 (1.3M)
Saving to: ‘httpd-2.4.55-1.x86_64.rpm’

100%[==================================================================================================================>] 1,402,908   --.-K/s   in 0.006s

2023-02-04 10:35:12 (220 MB/s) - ‘httpd-2.4.55-1.x86_64.rpm’ saved [1402908/1402908]

[root@nfss test1]# ls
httpd-2.4.55-1.x86_64.rpm

#[root@nfss test1]# yum install percona-orchestrator.x86_64 -y
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.corbina.net
 * extras: mirror.sale-dedic.com
 * updates: mirror.corbina.net
otus                                                                                                                                 | 2.9 kB  00:00:00
Resolving Dependencies
--> Running transaction check
---> Package percona-orchestrator.x86_64 2:3.2.6-2.el8 will be installed
--> Processing Dependency: jq >= 1.5 for package: 2:percona-orchestrator-3.2.6-2.el8.x86_64
--> Processing Dependency: oniguruma for package: 2:percona-orchestrator-3.2.6-2.el8.x86_64
--> Processing Dependency: libc.so.6(GLIBC_2.28)(64bit) for package: 2:percona-orchestrator-3.2.6-2.el8.x86_64
--> Finished Dependency Resolution
Error: Package: 2:percona-orchestrator-3.2.6-2.el8.x86_64 (otus)
           Requires: oniguruma
Error: Package: 2:percona-orchestrator-3.2.6-2.el8.x86_64 (otus)
           Requires: jq >= 1.5
Error: Package: 2:percona-orchestrator-3.2.6-2.el8.x86_64 (otus)
           Requires: libc.so.6(GLIBC_2.28)(64bit)
 You could try using --skip-broken to work around the problem
 You could try running: rpm -Va --nofiles --nodigestУстановим репозиторий percona-release:

# При запуске скрипта почему то не срабатывает yum-builddep /root/rpmbuild/SPECS/httpd.spec, хотя в рабочей VM все команды срабатывают
#Ошибка - Bad spec faile 