Задача 1:
Определить алгоритм с наилучшим сжатием
Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);
Создать 4 файловых системы на каждой применить свой алгоритм сжатия;
Для сжатия использовать либо текстовый файл, либо группу файлов.

Решение:

C:\Homework_ZFS>vagrant ssh - подключаемся к VM по SSH
[vagrant@zfs ~]$ sudo su - переходим в режим супервользовтеля
[root@zfs vagrant]# lsblk - просмотр всех блочных утср-в
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk
sdc      8:32   0  512M  0 disk
sdd      8:48   0  512M  0 disk
sde      8:64   0  512M  0 disk
sdf      8:80   0  512M  0 disk
sdg      8:96   0  512M  0 disk
sdh      8:112  0  512M  0 disk
sdi      8:128  0  512M  0 disk

#Создаём пулы в режиме RAID1 (mirror)
[root@zfs vagrant]# zpool create otus1 mirror /dev/sdb /dev/sdc
[root@zfs vagrant]# zpool create otus2 mirror /dev/sdd /dev/sde
[root@zfs vagrant]# zpool create otus3 mirror /dev/sdf /dev/sdg
[root@zfs vagrant]# zpool create otus4 mirror /dev/sdh /dev/sdi

# ПОсмотрим информацию о пулах
[root@zfs vagrant]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -

# Добавляем в каждый пул свой алгоритм сжатия
[root@zfs vagrant]# zfs set compression=lzjb otus1
[root@zfs vagrant]# zfs set compression=lz4 otus2
[root@zfs vagrant]# zfs set compression=gzip-9 otus3
[root@zfs vagrant]# zfs set compression=zle otus4

#Посмотрим в каких пулах какой алгоритм
[root@zfs vagrant]# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local

# Скачиваем один и тот же файл во все пулы
[root@zfs vagrant]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
--2023-01-26 10:38:12--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus1/pg2600.converter.log’

100%[=============================================>] 40,894,017  1.76MB/s   in 30s

2023-01-26 10:38:44 (1.28 MB/s) - ‘/otus1/pg2600.converter.log’ saved [40894017/40894017]

--2023-01-26 10:38:44--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus2/pg2600.converter.log’

100%[=============================================>] 40,894,017  1.80MB/s   in 24s

2023-01-26 10:39:09 (1.61 MB/s) - ‘/otus2/pg2600.converter.log’ saved [40894017/40894017]

--2023-01-26 10:39:09--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus3/pg2600.converter.log’

100%[=============================================>] 40,894,017  1.73MB/s   in 31s

2023-01-26 10:39:42 (1.24 MB/s) - ‘/otus3/pg2600.converter.log’ saved [40894017/40894017]

--2023-01-26 10:39:42--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus4/pg2600.converter.log’

100%[=============================================>] 40,894,017   995KB/s   in 54s

2023-01-26 10:40:37 (738 KB/s) - ‘/otus4/pg2600.converter.log’ saved [40894017/40894017]

# Проверим наличие фала в пулах
[root@zfs vagrant]#  ls -l /otus*
/otus1:
total 22036
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus2:
total 17981
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus3:
total 10953
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus4:
total 39963
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

# Посмотрим информацию о пулах (занятое пространство), что бы определить где файл занимает меньше места
[root@zfs vagrant]# zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.6M   330M     21.5M  /otus1
otus2  17.7M   334M     17.6M  /otus2
otus3  10.8M   341M     10.7M  /otus3
otus4  39.1M   313M     39.0M  /otus4

# Смотрим степень сжатия в разных пулах
[root@zfs vagrant]# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.81x                  -
otus2  compressratio         2.22x                  -
otus3  compressratio         3.64x                  -
otus4  compressratio         1.00x                  -

Ответ: исходя из результата трёх последних команд видно, что наилучший алгоритм сжатия gzip-9, который настроен на otus3


Задача 2:
Определить настройки пула
С помощью команды zfs import собрать pool ZFS;
Командами zfs определить настройки:
    - размер хранилища;
    - тип pool;
    - значение recordsize;
    - какое сжатие используется;
    - какая контрольная сумма используется.

Решение:

#Скачиваем архив в формате gz
wget -O archive.tar.gz https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
--2023-01-26 12:11:47--  https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
Resolving drive.google.com (drive.google.com)... 142.251.9.194, 2a00:1450:4025:c03::c2
Connecting to drive.google.com (drive.google.com)|142.251.9.194|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://drive.google.com/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg [following]
--2023-01-26 12:11:48--  https://drive.google.com/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
Reusing existing connection to drive.google.com:443.
HTTP request sent, awaiting response... 303 See Other
Location: https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/9e50ch72lfstogafuktaq5b9vb3d8pib/1674735375000/16189157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg?uuid=06230587-ea0d-4024-af9e-9ef07ba440fb [following]
Warning: wildcards not supported in HTTP.
--2023-01-26 12:11:53--  https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/9e50ch72lfstogafuktaq5b9vb3d8pib/1674735375000/16189157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg?uuid=06230587-ea0d-4024-af9e-9ef07ba440fb
Resolving doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)... 142.250.147.132, 2a00:1450:4025:c01::84
Connecting to doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)|142.250.147.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7275140 (6.9M) [application/x-gzip]
Saving to: ‘archive.tar.gz’

100%[=============================================>] 7,275,140   2.00MB/s   in 3.5s

2023-01-26 12:11:57 (2.00 MB/s) - ‘archive.tar.gz’ saved [7275140/7275140]

# Проверим, что архив скачался
[root@zfs vagrant]# ls
archive.tar.gz

# Распаковываем
[root@zfs vagrant]# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb

# Проверим, возможно ли импортировать данный каталог в пул
[root@zfs vagrant]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

        otus                                 ONLINE
          mirror-0                           ONLINE
            /home/vagrant/zpoolexport/filea  ONLINE
            /home/vagrant/zpoolexport/fileb  ONLINE
# Данный вывод показывает нам имя пула, тип raid и его состав

# Сделаем импорт данного пула к нам в ОС
[root@zfs vagrant]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

        otus                                 ONLINE
          mirror-0                           ONLINE
            /home/vagrant/zpoolexport/filea  ONLINE
            /home/vagrant/zpoolexport/fileb  ONLINE

[root@zfs vagrant]# zpool import -d zpoolexport/ otus

# Выведем подробную информацию о пулах
[root@zfs vagrant]# zpool status
  pool: otus
 state: ONLINE
  scan: none requested
config:

        NAME                                 STATE     READ WRITE CKSUM
        otus                                 ONLINE       0     0     0
          mirror-0                           ONLINE       0     0     0
            /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
            /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

  pool: otus1
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus1       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors

  pool: otus2
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus2       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors

  pool: otus3
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus3       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdf     ONLINE       0     0     0
            sdg     ONLINE       0     0     0

errors: No known data errors

  pool: otus4
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus4       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdh     ONLINE       0     0     0
            sdi     ONLINE       0     0     0

errors: No known data errors

# Посмотрим все параметры файловой системы
[root@zfs vagrant]# zpool get all otus
NAME  PROPERTY                       VALUE                          SOURCE
otus  size                           480M                           -
otus  capacity                       0%                             -
otus  altroot                        -                              default
otus  health                         ONLINE                         -
otus  guid                           6554193320433390805            -
otus  version                        -                              default
otus  bootfs                         -                              default
otus  delegation                     on                             default
otus  autoreplace                    off                            default
otus  cachefile                      -                              default
otus  failmode                       wait                           default
otus  listsnapshots                  off                            default
otus  autoexpand                     off                            default
otus  dedupditto                     0                              default
otus  dedupratio                     1.00x                          -
otus  free                           478M                           -
otus  allocated                      2.09M                          -
otus  readonly                       off                            -
otus  ashift                         0                              default
otus  comment                        -                              default
otus  expandsize                     -                              -
otus  freeing                        0                              -
otus  fragmentation                  0%                             -
otus  leaked                         0                              -
otus  multihost                      off                            default
otus  checkpoint                     -                              -
otus  load_guid                      16432398896076356390           -
otus  autotrim                       off                            default
otus  feature@async_destroy          enabled                        local
otus  feature@empty_bpobj            active                         local
otus  feature@lz4_compress           active                         local
otus  feature@multi_vdev_crash_dump  enabled                        local
otus  feature@spacemap_histogram     active                         local
otus  feature@enabled_txg            active                         local
otus  feature@hole_birth             active                         local
otus  feature@extensible_dataset     active                         local
otus  feature@embedded_data          active                         local
otus  feature@bookmarks              enabled                        local
otus  feature@filesystem_limits      enabled                        local
otus  feature@large_blocks           enabled                        local
otus  feature@large_dnode            enabled                        local
otus  feature@sha512                 enabled                        local
otus  feature@skein                  enabled                        local
otus  feature@edonr                  enabled                        local
otus  feature@userobj_accounting     active                         local
otus  feature@encryption             enabled                        local
otus  feature@project_quota          active                         local
otus  feature@device_removal         enabled                        local
otus  feature@obsolete_counts        enabled                        local
otus  feature@zpool_checkpoint       enabled                        local
otus  feature@spacemap_v2            active                         local
otus  feature@allocation_classes     enabled                        local
otus  feature@resilver_defer         enabled                        local
otus  feature@bookmark_v2            enabled                        local

# Смотрим размер хранилища
[root@zfs vagrant]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -

# Смотрим тип пула
[root@zfs vagrant]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default

# Смотрим значение значение recordsize
[root@zfs vagrant]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local

# Смотрим алгоритм сжатия
[root@zfs vagrant]# zfs get compression otus
NAME  PROPERTY     VALUE     SOURCE
otus  compression  zle       local

# Смотрим наличие контрольных сумм и алгоритмов шифрования
[root@zfs vagrant]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local

Ответ:загружен и распакован архив, собран pool ZFS, последние 5 команд показывают настройки хранилища

Задача 3:
Работа со снапшотами
скопировать файл из удаленной директории.   https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing 
восстановить файл локально. zfs receive
найти зашифрованное сообщение в файле secret_message

Решение:


# Скачиваем файл
[root@zfs vagrant]#  wget -O otus_task2.file https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG
--2023-01-26 12:29:58--  https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG
Resolving drive.google.com (drive.google.com)... 142.251.9.194, 2a00:1450:4025:c03::c2
Connecting to drive.google.com (drive.google.com)|142.251.9.194|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://drive.google.com/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG [following]
--2023-01-26 12:30:03--  https://drive.google.com/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG
Reusing existing connection to drive.google.com:443.
HTTP request sent, awaiting response... 303 See Other
Location: https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/2iusct9rlbs6k2i4bnp3703umu9qhs68/1674736350000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?uuid=810aed5a-06d8-40f7-a578-a52433000112 [following]
Warning: wildcards not supported in HTTP.
--2023-01-26 12:30:08--  https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/2iusct9rlbs6k2i4bnp3703umu9qhs68/1674736350000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?uuid=810aed5a-06d8-40f7-a578-a52433000112
Resolving doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)... 142.250.147.132, 2a00:1450:4025:c01::84
Connecting to doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)|142.250.147.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 5432736 (5.2M) [application/octet-stream]
Saving to: ‘otus_task2.file’

100%[=============================================>] 5,432,736   1.68MB/s   in 3.1s

2023-01-26 12:30:12 (1.68 MB/s) - ‘otus_task2.file’ saved [5432736/5432736]

# Смотрим, что файл скачался
[root@zfs vagrant]# ls
archive.tar.gz  otus_task2.file  zpoolexport

# Восстанавливаем из снапшота
[root@zfs vagrant]# zfs receive otus/test@today < otus_task2.file

# Посомтрим что появилось в /otus/test (дирректория появилась после восстановления)
[root@zfs vagrant]#
[root@zfs vagrant]# ls /otus/test
10M.file        for_examaple.txt  Limbo.txt      task1              world.sql
cinderella.tar  homework4.txt     Moby_Dick.txt  War_and_Peace.txt

# Найдём "secret_message" в /otus/test
[root@zfs vagrant]# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message

# Выведем содержимое secret_message
[root@zfs vagrant]# cat /otus/test/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome

# Посомтрим, что на страничке с помощью curl
[root@zfs vagrant]# curl https://github.com/sindresorhus/awesome - тут очент большой вывод

Ответ: скопирован файл из задания, проведено восстановление из него, скрытый файл от преподавателя найден

Примечание:
В данной ветке репозитория лежи второй файл - скрипт (его нужно положить в туже директорию, что и Vagrantfile).
После запуска Vagrant up поднимается VM.
Результат ниже:

[vagrant@zfs ~]$ zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   128K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M   118K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   128K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M   128K   480M        -         -     0%     0%  1.00x    ONLINE  -
[vagrant@zfs ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk
├─sdb1   8:17   0  502M  0 part
└─sdb9   8:25   0    8M  0 part
sdc      8:32   0  512M  0 disk
├─sdc1   8:33   0  502M  0 part
└─sdc9   8:41   0    8M  0 part
sdd      8:48   0  512M  0 disk
├─sdd1   8:49   0  502M  0 part
└─sdd9   8:57   0    8M  0 part
sde      8:64   0  512M  0 disk
├─sde1   8:65   0  502M  0 part
└─sde9   8:73   0    8M  0 part
sdf      8:80   0  512M  0 disk
├─sdf1   8:81   0  502M  0 part
└─sdf9   8:89   0    8M  0 part
sdg      8:96   0  512M  0 disk
├─sdg1   8:97   0  502M  0 part
└─sdg9   8:105  0    8M  0 part
sdh      8:112  0  512M  0 disk
├─sdh1   8:113  0  502M  0 part
└─sdh9   8:121  0    8M  0 part
sdi      8:128  0  512M  0 disk
├─sdi1   8:129  0  502M  0 part
└─sdi9   8:137  0    8M  0 part
[vagrant@zfs ~]$ zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
