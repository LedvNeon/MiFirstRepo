#!/bin/bash

# Задача:
# Создать сервис, который рас в 30 секунд мониторит лог на наличие ключевого слова

# Остановим брандмауэр и уберём его из автозапуска
systemctl stop firewalld
systemctl disable firewalld

    # Отключим selinux заменой строк SELINUX=enforcing на SELINUX=disabled в /etc/sysconfig/selinux
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    #setenforce 0
    # Перезагрузим VM для применения настройки
    #shutdown -r 0

        # Cоздаём файл с конфигурацией для сервиса в директории /etc/sysconfig.
        # Из неё сервис будет брать необходимые переменные.
        #cat << EOF >> /etc/sysconfig/watchlog
        #> # Configuration file for my watchlog service
        #> # Place it to /etc/sysconfig
        #>
        #> # File and word in that file that we will be monit
        #> WORD="ALERT"
        #> LOG=/var/log/watchlog.log
        #> EOF
        echo -e 'WORD="ALERT" \nLOG=/var/log/watchlog.log' > /etc/sysconfig/watchlog

            # Создаём файл, в котором будем искать строку ALERT /var/log/watchlog.log 
            #cat << EOF >> /var/log/watchlog.log
            #> string 1 ALERT
            #> string 2
            #> ALERT
            #> last string
            #> EOF
            echo -e 'string 1 ALERT \nstring 2 \nALERT \nlast string' > /var/log/watchlog.log

                # Создадим файл скрипта /opt/watchlog.sh
                echo -e '#!/bin/bash \nWORD=$1 \nLOG=$2 \nDATE=`date` \nif grep $WORD $LOG &> /dev/null \nthen \nlogger "$DATE: I found word, Master!" \nelse \nexit 0 \nfi' > /opt/watchlog.sh
                # Добавим права на запуск файла
                chmod +x /opt/watchlog.sh

                    # Создадим Unit-ы для сервиса и таймера
                    echo -e '[Unit] \nDescription=Run watchlog script every 30 second \n \n[Timer] \n# Run every 30 second \nOnUnitActiveSec=30 \nUnit=watchlog.service \n \n[Install] \nWantedBy=multi-user.target' > /etc/systemd/system/watchlog.timer
                    echo -e '[Unit] \nDescription=My watchlog service \n \n[Service] \nType=oneshot \nEnvironmentFile=/etc/sysconfig/watchlog \nExecStart=/opt/watchlog.sh $WORD $LOG' > /etc/systemd/system/watchlog.service

                        # Стартуем таймер и сервис (без старта сервиса не работает)
                        #systemctl start watchlog.service
                        systemctl start watchlog.timer
                        systemctl start watchlog.service

                        # Варианты проверки:
                        # tail -f /var/log/messages - логи в реальном времени
                        # systemctl status watchlog.timer - статус работает или нет

# Задача:
# Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно также называться.

                            # Установим spawn-fcgi и нужынфе пакеты
                            yum install epel-release -y && yum install spawn-fcgi php php-climod_fcgid httpd -y
                            # Появится /etc/rc.d/init.d/spawn-fcgi - Init скрипт, который будем переписывать

                                # Раскоментируем нужные строки в /etc/sysconfig/spawn-fcgi
                                sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi
                                sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi

                                    # Создадим Юдин-файл /etc/systemd/system/spawn-fcgi.service для spawn-fcgi
                                    echo -e '[Unit] \nDescription=Spawn-fcgi startup service by Otus \nAfter=network.target \n \n[Service] \nType=simple \nPIDFile=/var/run/spawn-fcgi.pid \nEnvironmentFile=/etc/sysconfig/spawn-fcgi \nExecStart=/usr/bin/spawn-fcgi -n $OPTIONS \nKillMode=process \n \n[Install] \nWantedBy=multi-user.target' > /etc/systemd/system/spawn-fcgi.service

                                        # Стартуем spawn-fcgi
                                        systemctl start spawn-fcgi
                                        # Проверка успеха
                                        # systemctl status spawn-fcgi

# Задача:
# Дополнить Юнит-файл apache httpd возможностью запустить несколько
# инстансов сервера с разными конфигами

                                            # Внесём изменения в Юнит-файл (11 строка)
                                            mv /usr/lib/systemd/system/httpd.service /usr/lib/systemd/system/httpd@.service
                                            sed -i 's|EnvironmentFile=/etc/sysconfig/httpd|EnvironmentFile=/etc/sysconfig/httpd-%I|' /usr/lib/systemd/system/httpd@.service

                                                # Создадим новые файлы окружения
                                                echo -e '# /etc/sysconfig/httpd-first \nOPTIONS=-f conf/first.conf' > /etc/sysconfig/httpd-first
                                                echo -e '# /etc/sysconfig/httpd-second \nOPTIONS=-f conf/second.conf' > /etc/sysconfig/httpd-second

                                                    # Создаём новые файлы конфигураций с изменениями
                                                    mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
                                                    cp /etc/httpd/conf/first.conf /etc/httpd/conf/second.conf
                                                    sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/second.conf
                                                    echo "PidFile /var/run/httpd-second.pid" >> /etc/httpd/conf/second.conf

                                                        # Запускаем сервисы
                                                        systemctl start httpd@first
                                                        systemctl start httpd@second
                                                        #Проверка
                                                        #ss -tnulp | grep httpd