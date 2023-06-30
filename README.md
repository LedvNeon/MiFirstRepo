# Задание:
Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client.
Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:
1. директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB;
2. репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение;
3. имя бекапа должно содержать информацию о времени снятия бекапа;
4. глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов;
5. резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации;
6. написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение;
7. настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов.

# Проверка:
Запустите стенд на 30 минут.
Убедитесь что резервные копии снимаются.
Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа.
Для сдачи домашнего задания ожидаем настроенные стенд, логи процесса бэкапа и описание процесса восстановления.
Формат сдачи ДЗ - vagrant + ansible

# Решение:
Важно установить коллекцию community.general для Ansible на хосте, где будем разворачивать VM.
Иначе, не примапится диск для бекапа к серверу.
Все приложенные файлы нужно перенести на хостовую машину в домашнюю директорию.
В приложенных файлах ноходится:
1. Vagrantfile - файл для развёртывания 2-х VM (используется public_network - нужно поментяь на адреса из вашей подсети)
2. backup.yml - Playbook для настройки сервера (в данном файле закомментирован play auto backup - его нужно выполнять во второй части д/з (автоматизация резервного копирования))
3. hosts - inventory-файл (нужно поменять адреса на файлы из вашей подсети)
4. ansible.cfg - файл конфигурации для ansible
5. borg-backup.service - сервис бекапа
6. borg-backup.timer - таймер для запуска сервиса

# Тестирование
1. Сгенерируем на Client ssh ключ для подключения к backup и пропишем его в backup в /home/borg/.ssh/authorized_keys для пользователя borg.

## НА КЛИЕНТЕ:
[root@client vagrant] ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:Kk5hJaJLa0lhJyYRWPOV6T9Nbi2zsGWKKH5dv8dTdF0 root@client
The key's randomart image is:
+---[RSA 2048]----+
|+oo   .o         |
|.. o .o         E|
|.=..o..         o|
|+.+. o.   .   . o|
|.o  o  .S+ . . . |
|o.o. . .= O . .  |
|.+  oo.o X = .   |
|. .oo.o o o +    |
| ..o.     .o .   |
+----[SHA256]-----+
[root@client vagrant] cat /root/.ssh/id_rsa.pub

## НА СЕРВЕРЕ:
[root@backup vagrant] vi  /home/borg/.ssh/authorized_keys

## Проверим подключение по ssh с клиента до сервера
[root@client vagrant] ssh borg@172.20.10.5
[borg@backup ~]$ exit
logout
Connection to 172.20.10.5 closed.
Видим, что работает.

## Инициализируем репозиторий borg на backup сервере с client сервера:
[root@client vagrant] borg init --encryption=repokey borg@172.20.10.5:/var/backup/
Enter new passphrase: 
Enter same passphrase again:
Do you want your passphrase to be displayed for verification? [yN]: y
Your passphrase (between double-quotes): "m9C49RINEERE"
Make sure the passphrase displayed above is exactly what you wanted.

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam ssh://borg@172.20.10.5/var/backup

## Запускаем для проверки создания бэкапа
[root@client vagrant] borg create --stats --list borg@172.20.10.5:/var/backup/::"etc-{now:%Y-%m-%d_%H:%M:%S}" /etc
Приведу конец вывода:
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               28.43 MB             13.49 MB             11.84 MB
All archives:               28.43 MB             13.49 MB             11.84 MB

                       Unique chunks         Total chunks
Chunk index:                    1277                 1692
------------------------------------------------------------------------------

## Проверяем
[root@client vagrant] borg list borg@172.20.10.5:/var/backup/
Enter passphrase for key ssh://borg@172.20.10.5/var/backup:
etc-2023-06-30_07:57:35              Fri, 2023-06-30 07:57:43 [1eddf5dda4fc532329639471602800b0af0face9aab42cafe49a0998dce862b6]

Посомтрим список файлов
[root@client vagrant] borg list borg@172.20.10.5:/var/backup/::etc-2023-06-30_07:57:35
Ниже часть вывода:
drwxr-x--- root   root          0 Thu, 2020-04-30 22:09:26 etc/sudoers.d
-r--r----- root   root         33 Thu, 2020-04-30 22:09:26 etc/sudoers.d/vagrant

## Достаним файлы из бекапа (пример витягивания одного файла)
[root@client vagrant]# borg extract borg@172.20.10.5:/var/backup/::etc-2023-06-30_07:57:35 etc/hostname
Enter passphrase for key ssh://borg@172.20.10.5/var/backup:
[root@client vagrant]# pwd
/home/vagrant
[root@client vagrant]# ls
etc
[root@client vagrant]# cat etc/hostname 
client

## Автоматизируем создание бекапов
За это отвечает play в backup.yml - auto backup
Раскомментируем его, изменим следующие строки:
src: /home/dima/backup/borg-backup.service в 2-х tasks - "copy borg-backup.service on client" и "copy borg-backup.timer on client" меняем на ваше расположение данных файлов.
Выполняем play и проверяем.

[root@client vagrant] systemctl list-timers --all
NEXT                         LEFT          LAST                         PASSED      UNIT                         ACTIVATES
Fri 2023-06-30 09:09:08 UTC  1min 23s left n/a                          n/a         borg-backup.timer            borg-backup.service

## Проверяем список бекапов
[root@client vagrant] borg list borg@172.20.10.5:/var/backup/
etc-2023-06-30_09:45:49              Fri, 2023-06-30 09:45:53 [26ffa5b669ad19fb00ae4b9d3b9170a6acf88f12ab27ef95c53728c4cc02ec18]

Видим, что старый удалён и создан новый.

