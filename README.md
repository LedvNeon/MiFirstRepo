<#Задания на выбор:

написать свою реализацию ps ax используя анализ /proc
Результат ДЗ - рабочий скрипт который можно запустить
написать свою реализацию lsof
Результат ДЗ - рабочий скрипт который можно запустить
дописать обработчики сигналов в прилагаемом скрипте, оттестировать, приложить сам скрипт, инструкции по использованию
Результат ДЗ - рабочий скрипт который можно запустить + инструкция по использованию и лог консоли
реализовать 2 конкурирующих процесса по IO. пробовать запустить с разными ionice
Результат ДЗ - скрипт запускающий 2 процесса с разными ionice, замеряющий время выполнения и лог консоли
реализовать 2 конкурирующих процесса по CPU. пробовать запустить с разными nice
Результат ДЗ - скрипт запускающий 2 процесса с разными nice и замеряющий время выполнения и лог консоли
#>

<#Для выполнения ДЗ используется стенд ns01 из дз по selinux (ветка selinux в данном репозитории)
1. Напишем свою реализацию lsof (LiSt Open Files).
Данная команда показывает какие файлы открыты какими процессами#>

# Для начала установим lsof - посмотрим её результат
[root@ns01 vagrant]# lsof
bash: lsof: command not found
[root@ns01 vagrant]# yum install lsof
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.corbina.net
 * extras: mirrors.datahouse.ru
 * updates: mirror.corbina.net
base                                                                                          | 3.6 kB  00:00:00     
extras                                                                                        | 2.9 kB  00:00:00     
updates                                                                                       | 2.9 kB  00:00:00     
updates/7/x86_64/primary_db                                                                   |  20 MB  00:00:15     
Resolving Dependencies
--> Running transaction check
---> Package lsof.x86_64 0:4.87-6.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===================================================================================================================== Package                  Arch                       Version                          Repository                Size 
=====================================================================================================================Installing:
 lsof                     x86_64                     4.87-6.el7                       base                     331 k 

Transaction Summary
=====================================================================================================================Install  1 Package

Total download size: 331 k
Installed size: 927 k
Is this ok [y/d/N]: y
Is this ok [y/d/N]: y
Downloading packages:
lsof-4.87-6.el7.x86_64.rpm                                                                    | 331 kB  00:00:00     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : lsof-4.87-6.el7.x86_64                                                                            1/1 
  Verifying  : lsof-4.87-6.el7.x86_64                                                                            1/1 

Installed:
  lsof.x86_64 0:4.87-6.el7

Complete!

# Вывод lsof очень большой, поэтому приложу часть
[root@ns01 vagrant]# lsof
lsof      1547        root  txt       REG                8,1   154184     231834 /usr/sbin/lsof
lsof      1547        root  mem       REG                8,1  3489392  100664374 /usr/lib/locale/locale-archive      
lsof      1547        root  mem       REG                8,1   142144       6862 /usr/lib64/libpthread-2.17.so       
lsof      1547        root  mem       REG                8,1    19248       6810 /usr/lib64/libdl-2.17.so
lsof      1547        root  mem       REG                8,1   402384       7123 /usr/lib64/libpcre.so.1.2.0
lsof      1547        root  mem       REG                8,1  2156240       6804 /usr/lib64/libc-2.17.so
lsof      1547        root  mem       REG                8,1   155744      11332 /usr/lib64/libselinux.so.1
lsof      1547        root  mem       REG                8,1   163312       6797 /usr/lib64/ld-2.17.so
lsof      1547        root    4r     FIFO                0,9      0t0      19179 pipe
lsof      1547        root    7w     FIFO                0,9      0t0      19180 pipe

# Т.к. мы знаем, что у нас есть директория /proc с информацией по процессам, воспользуемся ею
# Вывод так же будет огромным - поэтому приложу только часть
[root@ns01 vagrant]# find /proc/[0-9]*/fd -type l exec ls -l {} \;
l-wx------. 1 root root 64 Mar 11 09:12 /proc/978/fd/6 -> /run/systemd/sessions/1.ref
lr-x------. 1 root root 64 Mar 11 09:12 /proc/978/fd/7 -> pipe:[17131]
l-wx------. 1 root root 64 Mar 11 09:12 /proc/978/fd/8 -> pipe:[17131]
lrwx------. 1 root root 64 Mar 11 09:00 /proc/980/fd/0 -> /dev/tty1
lrwx------. 1 root root 64 Mar 11 09:00 /proc/980/fd/1 -> /dev/tty1
lrwx------. 1 root root 64 Mar 11 09:00 /proc/980/fd/2 -> /dev/tty1
lrwx------. 1 root root 64 Mar 11 09:00 /proc/980/fd/3 -> socket:[17146]
lrwx------. 1 root root 64 Mar 11 09:12 /proc/980/fd/4 -> socket:[17162]
l-wx------. 1 root root 64 Mar 11 09:00 /proc/980/fd/6 -> /run/systemd/sessions/1.ref
lrwx------. 1 root root 64 Mar 11 09:12 /proc/981/fd/0 -> /dev/tty1
lrwx------. 1 root root 64 Mar 11 09:12 /proc/981/fd/1 -> /dev/tty1
lrwx------. 1 root root 64 Mar 11 09:12 /proc/981/fd/2 -> /dev/tty1
lrwx------. 1 root root 64 Mar 11 09:12 /proc/981/fd/255 -> /dev/tty1

# 2. Реализуем 2 конкурирующих процесса по IO. Попробуем запустить с разными ionice
# Сделаем это на примере dd ( предварительно создав файл на 2 Гб)
[root@ns01 dir1]# pwd
/home/vagrant
[root@ns01 dir1]# mkdir dir1
[root@ns01 dir1]# cd dir1
[root@ns01 dir1]# pwd
/home/vagrant/dir1
[root@ns01 dir1]# dd if=/dev/zero of=/home/vagrant/dir1/test1.txt  bs=2048M  count=1
0+1 records in
0+1 records out
2147479552 bytes (2.1 GB) copied, 68.7247 s, 31.2 MB/s
[root@ns01 dir1]# ls -lh
total 2.0G
-rw-r--r--. 1 root root 2.0G Mar 11 09:43 test1.txt

[root@ns01 dir1]# time dd if=/home/vagrant/dir1/test1.txt of=/dev/null &
[1] 4999
[root@ns01 dir1]# time dd if=/home/vagrant/dir1/test1.txt of=/dev/null &
[2] 5001
[root@ns01 dir1]# 4194296+0 records in
4194296+0 records out
2147479552 bytes (2.1 GB) copied, 29.6523 s, 72.4 MB/s

real    0m29.687s
user    0m1.945s
sys     0m12.728s
4194296+0 records in
4194296+0 records out
2147479552 bytes (2.1 GB) copied, 29.0966 s, 73.8 MB/s

real    0m29.112s
user    0m1.616s
sys     0m12.267s
# Видим, что время примерно одинаковое - real    0m29.687s и real    0m29.112s


# Теперь запустим один с наивысшим (ionice -n 1 -p 4993 - взято из вывода) приоритетом а второй с наименьшим (ionice -n 3 -p  4995 - взято из вывода)

[root@ns01 dir1]# time dd if=/home/vagrant/dir1/test1.txt of=/dev/null &
[1] 4993
[root@ns01 dir1]# time dd if=/home/vagrant/dir1/test1.txt of=/dev/null &
[2] 4995
[root@ns01 dir1]# ionice -n 1 -p 4993
[root@ns01 dir1]# ionice -n 3 -p 4995
[root@ns01 dir1]# 4194296+0 records in
4194296+0 records out
2147479552 bytes (2.1 GB) copied, 28.6413 s, 75.0 MB/s

real    0m28.659s
user    0m1.767s
sys     0m12.492s
4194296+0 records in
4194296+0 records out
2147479552 bytes (2.1 GB) copied, 29.5402 s, 72.7 MB/s

real    0m29.609s
user    0m1.988s
sys     0m13.078s

# Видим, что процесс с меньшим приоритетом выполнялся на секунду дольше.
# Причина в маленькой разнице в том, что система не нагружена

# Реализуем 2 конкурирующих процесса по CPU. Попробуем запустить с разными nice (используя ту же time dd if=/home/vagrant/dir1/test1.txt of=/dev/null &)

[root@ns01 dir1]# renice -n -10 -p 5019 

top - 10:00:38 up  1:01,  2 users,  load average: 1.73, 0.76, 0.59
Tasks:  91 total,   3 running,  88 sleeping,   0 stopped,   0 zombie
%Cpu(s): 12.1 us, 65.8 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi, 22.1 si,  0.0 st
KiB Mem :   240644 total,     3996 free,    51400 used,   185248 buff/cache
KiB Swap:  2097148 total,  1973256 free,   123892 used.   180600 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                                           
 5019 root      10 -10    7816    580    484 R 87.9  0.2   0:12.92 dd                                                
 5021 root      20   0    7816    584    484 R  9.2  0.2   0:06.23 dd 

 # Используя top видим, что приоритет изменился. Теперь процесс с приоритетом 10 выполнится быстрее
# Разница в 5 секунд

real    0m25.748s
user    0m1.848s
sys     0m12.800s
4194296+0 records in
4194296+0 records out
2147479552 bytes (2.1 GB) copied, 30.0528 s, 71.5 MB/s

real    0m30.058s
user    0m1.681s
sys     0m12.262s
