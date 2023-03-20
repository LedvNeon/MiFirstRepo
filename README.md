# Задание:
<#1.Написать Dockerfile на базе apache/nginx который будет содержать две статичные web-страницы на разных портах. 
Например, 80 и 3000. 
2.Пробросить эти порты на хост машину. Обе страницы должны быть доступны по адресам localhost:80 и localhost:3000 
3.Добавить 2 вольюма. Один для логов приложения, другой для web-страниц.
#>

# Поднимим VM из Vagrantfile
PS C:\git\MiFirstRepo> vagrant up

# Подключимся к VM по ssh и перейдём в режим супрепользователя
PS C:\git\MiFirstRepo> vagrant ssh
[vagrant@localhost ~]$ sudo su

# Обновим ОС:
[root@localhost vagrant]# yum update -y

# Отключим firewalld и selinux, т.к. лабораторная работа тестовая
[root@localhost docker]# systemctl stop firewalld.service
[root@localhost docker]# systemctl disable firewalld.service
[root@localhost docker]# vi /etc/selinux/config
[root@localhost docker]# cat /etc/selinux/config
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
# SELINUX=enforcing
  SELINUX=disabled
# SELINUXTYPE= can take one of three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
[root@localhost docker]# setenforce 0

# Хотя я проверял и с включенными - работает без доп. настроек

# Установим docker
[root@localhost vagrant]# yum install docker -y

# Запустим docker и добавим в автозагрузку
[root@localhost vagrant]# systemctl start docker
[root@localhost vagrant]# systemctl enable docker
Created symlink from /etc/systemd/system/multi-user.target.wants/docker.service to /usr/lib/systemd/system/docker.service.
[root@localhost vagrant]# systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2023-03-19 15:05:57 UTC; 22s ago
     Docs: http://docs.docker.com
 Main PID: 20582 (dockerd-current)
   CGroup: /system.slice/docker.service
           ├─20582 /usr/bin/dockerd-current --add-runtime docker-runc=/usr/libexec/docker/docker-runc-current --default-runti...           └─20587 /usr/bin/docker-containerd-current -l unix:///var/run/docker/libcontainerd/docker-containerd.sock --metric...
Mar 19 15:05:54 localhost.localdomain dockerd-current[20582]: time="2023-03-19T15:05:54.990652528Z" level=info msg="libco...587"Mar 19 15:05:56 localhost.localdomain dockerd-current[20582]: time="2023-03-19T15:05:56.298502702Z" level=info msg="Graph...nds"Mar 19 15:05:56 localhost.localdomain dockerd-current[20582]: time="2023-03-19T15:05:56.302766762Z" level=info msg="Loadi...rt."Mar 19 15:05:56 localhost.localdomain dockerd-current[20582]: time="2023-03-19T15:05:56.602648953Z" level=info msg="Firew...lse"Mar 19 15:05:56 localhost.localdomain dockerd-current[20582]: time="2023-03-19T15:05:56.960857653Z" level=info msg="Defau...ess"Mar 19 15:05:57 localhost.localdomain dockerd-current[20582]: time="2023-03-19T15:05:57.178364363Z" level=info msg="Loadi...ne."Mar 19 15:05:57 localhost.localdomain dockerd-current[20582]: time="2023-03-19T15:05:57.327970503Z" level=info msg="Daemo...ion"Mar 19 15:05:57 localhost.localdomain dockerd-current[20582]: time="2023-03-19T15:05:57.328089285Z" level=info msg="Docke...13.1Mar 19 15:05:57 localhost.localdomain dockerd-current[20582]: time="2023-03-19T15:05:57.537032876Z" level=info msg="API l...ock"Mar 19 15:05:57 localhost.localdomain systemd[1]: Started Docker Application Container Engine.
Hint: Some lines were ellipsized, use -l to show in full.

# Создадим директорию, где будем создавать dockerfile 
[root@localhost vagrant]# pwd
/home/vagrant
[root@localhost vagrant]# mkdir /home/vagrant/docker
[root@localhost vagrant]# cd docker/

# Содадим простенький Dockerfile с nginx с содержимым:
FROM nginx:latest

# Соберём из него образ и запустим контейнер (точка в конце build означает, что пусть к Dockerfile в текущей директории)
[root@localhost docker]# docker build -t nginx .
Sending build context to Docker daemon 2.048 kB
Step 1/1 : FROM nginx:latest
Trying to pull repository docker.io/library/nginx ... 
latest: Pulling from docker.io/library/nginx
3f9582a2cbe7: Pull complete
9a8c6f286718: Pull complete
e81b85700bc2: Pull complete
73ae4d451120: Pull complete
6058e3569a68: Pull complete
3a1b8f201356: Pull complete
Digest: sha256:aa0afebbb3cfa473099a62c4b32e9b3fb73ed23f2a75a65ce1d4b4f55a5c2ef2
Status: Downloaded newer image for docker.io/nginx:latest
 ---> 904b8cb13b93
Successfully built 904b8cb13b93

[root@localhost docker]# docker run -it --rm -d -p 80:80 -p 3000:3000 --name nginx nginx
377b30d9cb8d777c97dc38fd0b51ca5c1f382232a891517c9ab1b5c6fd04147e

# Т.к. несколько раз перезапускал контейнер, ID могут различаться

[root@localhost vagrant]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS
                 NAMES
53ee58b9ad93        nginx               "/docker-entrypoin..."   39 minutes ago      Up 39 minutes       0.0.0.0:80->80/tcp, 0.0.0.0:3000->3000/tcp   nginx

# Создадим директорию /home/vagrant/webserv, в которой подготовим новый файл конфигурации nginx (default.conf) со следующим содержимым:
server {
        listen       80;
        listen       [::]:80;
        server_name  localhost;
        # root         /usr/share/nginx/html;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
}

server {
        listen       3000;
        listen       [::]:3000;
        server_name  localhost;
       # root         /usr/share/nginx/html;
    location / {
        root   /usr/share/nginx/html;
        index  srv.html srv.htm;
    }
        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }

}

# В этой же директории подготовим файл с содержимым ещё одной странички srv.html
<HTML>
<HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>TEST WEB SITE</title>
</HEAD>
<BODY>
<h1>HELLO WORLD</h1>
</BODY>
</HTML>

# Зайдём в контейнер и уалим старый файл конфигурации
[root@localhost vagrant]# docker exec -it nginx bash
root@53ee58b9ad93:/# rm /etc/nginx/conf.d/default.conf
root@53ee58b9ad93:/# exit

# Скописруем новые файлы в онтейнер
[root@localhost vagrant]# docker cp /home/vagrant/webserv/default.conf nginx:/etc/nginx/conf.d/default.conf
[root@localhost vagrant]# docker cp /home/vagrant/webserv/srv.html nginx:/usr/share/nginx/html/srv.html

# Зайдём в контейнер, проверим конфигурацию nginx и перезагрузим его
# После этого выйдем из контейнера и проверим доступность на разных портах
[root@localhost vagrant]# docker exec -it nginx bash
root@53ee58b9ad93:/# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

root@53ee58b9ad93:/# nginx -s reload
2023/03/20 11:54:26 [notice] 122#122: signal process started

root@53ee58b9ad93:/# exit
exit

[root@localhost vagrant]# curl http://localhost:3000
<HTML>
<HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>TEST WEB SITE</title>
</HEAD>
<BODY>
<h1>HELLO WORLD</h1>
</BODY>
</HTML>
[root@localhost vagrant]# curl http://localhost:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

# Видим, что вывод из разных файлов. Т.е. каждый порт отдаёт свою страничку.

# Теперь создадим 2 папки для логов и пробросим их в контейнер с помощью volume 
# Их расположение на хосте:
# /home/vagrant/docker_volume1 - папка, где будут храниться логи самих страничек.
# она будет равна папке /var/log/nginx/ в контейнере (ПАПКА ПО УМОЛЧАНИЮ)
# /home/vagrant/docker_volume2 - папка, где будут храниться логи контейнера 
# Она будет равна /logs_container в самом контейнере
# Для получения логов контейнера используем команду docker logs nginx - она будет выполняться скриптом
# /home/vagrant/scripts/docker_logs_nginx.sh 

#!/bin/bash
docker logs nginx >> /home/vagrant/docker_volume2/logs_apps

# Добавим исполнение данного скрипта каждый час через crond
[root@localhost scripts]# crontab -e

* */1 * * *  /home/vagrant/scripts/docker_logs_nginx.s

# Тепер остановим и запустим контейнер заного, снова докинув файл конфигураций и вторую страничку html
[root@localhost scripts]# docker stop nginx
[root@localhost vagrant]# docker run -it -d --rm -v /home/vagrant/docker_volume2:/logs_container -v /home/vagrant/docker_volume1:/var/log/nginx/ -p 3000:3000 -p 80:80 --name nginx  nginx

[root@localhost vagrant]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS
                 NAMES
2b6aa6b42d38        nginx               "/docker-entrypoin..."   17 seconds ago      Up 14 seconds       0.0.0.0:80->80/tcp, 0.0.0.0:3000->3000/tcp   nginx

[root@localhost vagrant]# docker cp /home/vagrant/webserv/default.conf nginx:/etc/nginx/conf.d/default.conf
[root@localhost vagrant]# docker cp /home/vagrant/webserv/srv.html nginx:/usr/share/nginx/html/srv.html

[root@localhost vagrant]# docker exec -it nginx bash
root@2b6aa6b42d38:/# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

root@2b6aa6b42d38:/# nginx -s reload
root@2b6aa6b42d38:/# exit

[root@localhost vagrant]# curl http://localhost:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
[root@localhost vagrant]# curl http://localhost:3000
<HTML>
<HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>TEST WEB SITE</title>
#!/bin/bash
</HEAD>
<BODY>
<h1>HELLO WORLD</h1>
</BODY>
</HTML>

# Теперь выполним скрипт, и проверим наличие логов внутри контейнера, тоже самое сделаем и с volume1 на хостовой машине.
# Проверим, пробросились ли на неё папки с контейнера

[root@localhost vagrant]# cd docker_volume1
[root@localhost docker_volume1]# ls
access.log  error.log

root@2b6aa6b42d38:/# ls /logs_container/
logs_apps
root@2b6aa6b42d38:/# cat logs_container/logs_apps 
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
# Здесь полный вывод не приводил

# Теперь настроим всё через Dockerfile
# Его вид будет таким:
FROM nginx:latest # Указал последнюю версию nginx
COPY default.conf /etc/nginx/conf.d/ # Скопировал из текущей директории файл конигурации nginx в контейнер
ADD srv.html /usr/share/nginx/html/ # Скопировал из текущей директории файл со второй страничкой nginx в контейнер
VOLUME /var/log/nginx/ /logs_container # Создал 2 VLUME для хранения данных и связки с ОС, они будут тут:
# в хостовой ситеме они будут тут /var/lib/docker/volumes/
EXPOSE 80 3000 # Указал необходимость открыть порты

# Запустим сборку образа
[root@localhost docker]# docker build -t web2 .
Sending build context to Docker daemon 6.144 kB
Step 1/5 : FROM nginx:latest
 ---> 904b8cb13b93
Step 2/5 : COPY default.conf /etc/nginx/conf.d/
 ---> Using cache
 ---> fe708ff5e6bb
Step 3/5 : ADD srv.html /usr/share/nginx/html/
 ---> Using cache
 ---> c4e3674b1e69
Step 4/5 : VOLUME /var/log/nginx/ /logs_container
 ---> Running in e974ce7d8da8
 ---> 44550ea03063
Removing intermediate container e974ce7d8da8
Step 5/5 : EXPOSE 80 3000
 ---> Running in be197a781a34
 ---> 43933fd0709d
Removing intermediate container be197a781a34
Successfully built 43933fd0709d

# Запстим контейнер из данного образа
[root@localhost docker]# docker run -it -d --rm -p 80:80 -p 3000:3000 --name web2  web2
1c1a65f04d5ae22fc63854e43358c852c062f414a328127c5279c7a8858e8019

# Проверим, что обе странички доступны
[root@localhost docker]# curl http://localhost:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
[root@localhost docker]# curl http://localhost:3000
<HTML>
<HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>TEST WEB SITE</title>
</HEAD>
<BODY>
<h1>HELLO WORLD</h1>
</BODY>
</HTML>

# Проверим появились ли они в системе:
[root@localhost docker]# ls /var/lib/docker/volumes/
1c00f37d3d09766a18f8517c0256877b8e94d1d2abe56b0c7a4d08ad71c9ac0c  metadata.db
459cda6c4376a24f55ca758863c3ce4d285ea05b1b414758bf3a131acafbb279

# Посмотрим какой из них уже подтянул логи страничек из контейнера
[root@localhost docker]# ls /var/lib/docker/volumes/459cda6c4376a24f55ca758863c3ce4d285ea05b1b414758bf3a131acafbb279/_data/
[root@localhost docker]# ls /var/lib/docker/volumes/1c00f37d3d09766a18f8517c0256877b8e94d1d2abe56b0c7a4d08ad71c9ac0c/_data/
access.log  error.log
# Это 1c00f37d3d09766a18f8517c0256877b8e94d1d2abe56b0c7a4d08ad71c9ac0c

# Изменим скрипт, что бы он копировал логи приложения в 459cda6c4376a24f55ca758863c3ce4d285ea05b1b414758bf3a131acafbb279
[root@localhost docker]# vi /home/vagrant/scripts/docker_logs_nginx.sh
# Выполним сркипт и проверим появились ли логи
[root@localhost docker]# ls /var/lib/docker/volumes/459cda6c4376a24f55ca758863c3ce4d285ea05b1b414758bf3a131acafbb279/_data/
logs_apps
# Логи появились

<# Мы написали Dockerfile, который поднимает контейнер с 2-мя статичными страницами nginx (каждая на своём порту).
Сделали 2 VOLUME для хранения логов. Реализовали это всё через Dockerfile. #>

# Теперь создадим Vagrantfile, который будет поднимать VM, устанавливать docker, 
# собирать образ nginx и поднимать контейнер.
# В каталоге, где лежит наш Vagrntfile создадим директорию docker, она будет синхронизироваться с /mnt на VM.
# box.vm.synced_folder "C:/git/MiFirstRepo/docker", "/mnt", type: "rsync"
# Так же в этой же директории создадим скрипт, который будет производить всю настройку script.sh
# Vagrantfile представлен в репозитории отдельным файлом

# После развёртывания VM сразу сделаем curl
PS C:\git\MiFirstRepo> vagrant ssh
[vagrant@dockersrv ~]$ sudo su
[root@dockersrv vagrant]# curl http://localhost:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
[root@dockersrv vagrant]# curl http://localhost:3000
<HTML>
    <HEAD>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>TEST WEB SITE</title>
    </HEAD>
    <BODY>
    <h1>HELLO WORLD</h1>
    </BODY>
    </HTML>

  # Видим, что странички доступны

  # Проверим наличие voliume
    [root@dockersrv vagrant]# ls /var/lib/docker/volumes
5d7fbaf0c1e3cb3dbe090fb2f6fd9d78a65446a93d8a1c4bacedbcfaa2346f5c  6bcb869fb04718754bc07b39e4ecea47483c4f4088e1ba43ba9f158f0bebdf56  metadata.db

# И они есть.

# Повторно создание скрипта для сбора логов приложения приводить не буду - оно описано выше.