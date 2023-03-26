<#
Задание:
Настроить дашборд с 4-мя графиками

память;
процессор;
диск;
сеть.
Настроить на одной из систем:
zabbix (использовать screen (комплексный экран);
prometheus - grafana.
Использование систем, примеры которых не рассматривались на занятии*
Список возможных систем был приведен в презентации.
В качестве результата прислать скриншот экрана - дашборд должен содержать в названии имя приславшего.
В чат ДЗ отправьте ссылку на ваш git-репозиторий. Обычно мы проверяем ДЗ в течение 48 часов.
Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Slack.
Удачи при выполнении!

Критерии оценки:
Статус "Принято" ставится при выполнении основного задания.
Задание со звездочкой выполняется по желанию.
#>

# Выполнение:
# Подними сервер Prometheus promsrv из Vagrantfile с public_network 192.168.1.25
PS C:\git\MiFirstRepo> vagrant up
# Подсключимся к серверу по ssh и обновим ОС, добавив нужные компоненты.
PS C:\git\MiFirstRepo> vagrant ssh
[vagrant@promsrv ~]$ sudo su
[root@promsrv vagrant]# yum install -y wget
[root@promsrv vagrant]# yum install -y epel-release
# Вывод не привожу, т.к. он большой
# Создадим директорию, куда будем скачивать дистрибутив Prometheus
[root@promsrv vagrant]# pwd
/home/vagrant
[root@promsrv vagrant]# mkdir Prometheus
[root@promsrv vagrant]# ls -la
total 12
drwx------. 4 vagrant vagrant  92 Mar 26 10:22 .
drwxr-xr-x. 3 root    root     21 Apr 30  2020 ..
-rw-r--r--. 1 vagrant vagrant  18 Apr  1  2020 .bash_logout
-rw-r--r--. 1 vagrant vagrant 193 Apr  1  2020 .bash_profile
-rw-r--r--. 1 vagrant vagrant 231 Apr  1  2020 .bashrc
drwxr-xr-x. 2 root    root      6 Mar 26 10:22 Prometheus
drwx------. 2 vagrant vagrant  29 Mar 26 10:14 .ssh

# Перейдём в директорию Prometheus, скачаем (с офф сайта) и распакуем дистрибутив
[root@promsrv vagrant]# cd Prometheus/
[root@promsrv Prometheus]# wget https://github.com/prometheus/prometheus/releases/download/v2.43.0/prometheus-2.43.0.linux-amd64.tar.gz
[root@promsrv Prometheus]# ls
prometheus-2.43.0.linux-amd64.tar.gz
[root@promsrv Prometheus]# tar -xvzf prometheus-2.43.0.linux-amd64.tar.gz 
# -x - распаковать
# -v - в подробном режиме
# -z – обработка архива с помощью gzip
# -f - следующая строка, это файл, с которым надо работать
# вывод не привожу, результат в следующей строке
[root@promsrv Prometheus]# ls
prometheus-2.43.0.linux-amd64  prometheus-2.43.0.linux-amd64.tar.gz
[root@promsrv Prometheus]# cd prometheus-2.43.0.linux-amd64/
[root@promsrv prometheus-2.43.0.linux-amd64]# ls
console_libraries  consoles  LICENSE  NOTICE  prometheus  prometheus.yml  promtool

# cкопируем исполняемые файлы в /usr/local/bin/
[root@promsrv prometheus-2.43.0.linux-amd64]# cp prometheus /usr/local/bin/
[root@promsrv prometheus-2.43.0.linux-amd64]# cp promtool /usr/local/bin/

# Создадим папку для файлов конфигурации и скопируем в неё конфиги
[root@promsrv prometheus-2.43.0.linux-amd64]# mkdir /etc/prometheus
[root@promsrv prometheus-2.43.0.linux-amd64]# cp -r consoles/ /etc/prometheus/consoles/
[root@promsrv prometheus-2.43.0.linux-amd64]# cp -r console_libraries/ /etc/prometheus/console_libraries/
[root@promsrv prometheus-2.43.0.linux-amd64]# cp prometheus.yml /etc/prometheus/

# Создадим папку для хранения данных
mkdir /var/lib/prometheus

# Создадим пользователя (без возможности входа в консоль) и назначим владельца файлов и папок:
# useradd - добавить пользователя
# -M - не создавать домашний каталог
# -r - системная учетная запись (без домашнего каталога и с идентификаторами в диапазоне SYS_UID_MIN - SYS_UID_MAX из файла /etc/login.defs)
# -s - путь до оболочки командной строки
# /sbin/nologin - без возможности входа в консоль
[root@promsrv prometheus-2.43.0.linux-amd64]# useradd -M -r -s /bin/nologin prometheus
[root@promsrv prometheus-2.43.0.linux-amd64]# chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Создадим systemd-юнит, чтобы удобнее управлять сервисом:
[root@promsrv prometheus-2.43.0.linux-amd64]# vi /etc/systemd/system/prometheus.service
[root@promsrv prometheus-2.43.0.linux-amd64]# cat /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus systemd service unit
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/prometheus \
--config.file=/etc/prometheus/prometheus.yml \
--storage.tsdb.path=/var/lib/prometheus \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries \
--web.listen-address=0.0.0.0:9090

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target

# Обновим список юнитов
[root@promsrv prometheus-2.43.0.linux-amd64]# systemctl daemon-reload

# Запустим Prometheus
[root@promsrv prometheus-2.43.0.linux-amd64]# systemctl start prometheus.service
[root@promsrv prometheus-2.43.0.linux-amd64]# systemctl enable prometheus.service
Created symlink from /etc/systemd/system/multi-user.target.wants/prometheus.service to /etc/systemd/system/prometheus.service.

# Теперь сервер Prometheus доступен по адресу 192.168.1.25:9090

# Теперь нам нужно установить node_exporter, для сбора данных. Установим на этот же сервер в качестве теста. 
# Предварительно создадим каталог /home/vagrant/Prometheus/node_exporter
[root@promsrv node_exporter]# wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
[root@promsrv node_exporter]# tar -xvzf node_exporter-1.5.0.linux-amd64.tar.gz
[root@promsrv node_exporter]# pwd
/home/vagrant/Prometheus/node_exporter
[root@promsrv node_exporter]# ls
node_exporter-1.5.0.linux-amd64  node_exporter-1.5.0.linux-amd64.tar.gz

# Скопируем бинарный файл в директорию /usr/local/bin/
[root@promsrv node_exporter]# cp -r node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/
[root@promsrv node_exporter]# ls /usr/local/bin/
node_exporter-1.5.0.linux-amd64  prometheus  promtool

# Созадим пользователя для node_exporter по аналогии с пользователем prometheus
[root@promsrv node_exporter]# useradd -M -r -s /bin/nologin node_exporter 

# Создадим юнит для экспортера
[root@promsrv node_exporter]# vi /etc/systemd/system/node_exporter.service
[root@promsrv node_exporter]# cat /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target

# Обновим список юнитов, включим экспортер и добавим его в автозагрузку
[root@promsrv node_exporter]# systemctl daemon-reload
[root@promsrv node_exporter]# systemctl start node_exporter.service
[root@promsrv node_exporter]# systemctl enable node_exporter.service
Created symlink from /etc/systemd/system/default.target.wants/node_exporter.service to /etc/systemd/system/node_exporter.service.

#  Внесём изменения в /etc/prometheus/prometheus.yml для сбора данных с экспортера
static_configs:
    - targets: ['localhost:9090']
  - job_name: 'node_localhost'
    static_configs:
    - targets: ['localhost:9100']

# Перезапустим сервис
[root@promsrv node_exporter]# systemctl restart prometheus.service 

# Проверим появился ли новый target в веб-интерфейсе - Status ― Targets - появился (скриншот приложен в ветке - Prometheus)

# Установим grafana
# Создадим директорию /home/vagrant/grafana и перейдём в неё
[root@promsrv vagrant]# mkdir grafana
[root@promsrv vagrant]# ls
grafana  Prometheus
[root@promsrv vagrant]# cd grafana/
[root@promsrv grafana]# wget https://dl.grafana.com/oss/release/grafana-9.4.7-1.x86_64.rpm
[root@promsrv grafana]# yum localinstall -y grafana-9.4.7-1.x86_64.rpm
[root@promsrv grafana]# systemctl start grafana-server.service
[root@promsrv grafana]# systemctl status grafana-server.service
● grafana-server.service - Grafana instance
   Loaded: loaded (/usr/lib/systemd/system/grafana-server.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2023-03-26 17:25:50 UTC; 6min ago
     Docs: http://docs.grafana.org
 Main PID: 1142 (grafana)
   CGroup: /system.slice/grafana-server.service
           └─1142 /usr/share/grafana/bin/grafana server --config=/etc/grafana/grafana.ini --pidfile=/var/run/grafana/grafana-server.pid --packa...

 [root@promsrv grafana]# systemctl enable grafana-server.service
Created symlink from /etc/systemd/system/multi-user.target.wants/grafana-server.service to /usr/lib/systemd/system/grafana-server.service.   


# Проверим доступность grafana на 192.168.1.25 на порту 3000 (скриншот приложен в репозиторий с настроенным dashbard - Grafana Dashboard.jpg)
# Пароль оставим по умолчанию admin/admin (т.к. система тестовая)
# Подключим prometheus через веб-интерфейс через data source и создадим нужный dashboard (скрин будет приложен в ветке - Grafana Dashboard.jpg)




