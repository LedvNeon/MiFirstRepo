# Задание:
Запретить всем пользователям, кроме группы admin, логин в выходные (суббота и воскресенье), без учета праздников
* дать конкретному пользователю права работать с докером
и возможность рестартить докер сервис

# Критерии оценки:
Статус "Принято" ставится при выполнении описанного требования.
Доп. задание выполняется по желанию.

# Решение:
Подними VM с именем pam из Vagrantfile (приложенного в методичке), поделючимся по ssh и перейдём в режим суперпользователя:
PS C:\git\MiFirstRepo> vagrant up

В Vagrantfile сразу разрешено пользователям подключаться к поднятой VM по SSH с использованием пароля.

PS C:\git\MiFirstRepo> vagrant ssh

[vagrant@pam ~]$ sudo su

Создадим 2-х пользователей otusadm и otus и зададим им пароли Otus2023! :
[root@pam vagrant]# useradd otusadm && useradd otus
[root@pam vagrant]# passwd otus
Changing password for user otus.
New password: 
BAD PASSWORD: The password contains the user name in some form
Retype new password:
passwd: all authentication tokens updated successfully.
[root@pam vagrant]# passwd otusadm
Changing password for user otusadm.
New password: 
Retype new password: 
passwd: all authentication tokens updated successfully.

Проверим, что пользователи появились:
[root@pam vagrant]# cat /etc/passwd | grep otus
otusadm:x:1001:1001::/home/otusadm:/bin/bash
otus:x:1002:1002::/home/otus:/bin/bash

Создадим группу admin и проверим появилась ли она:
[root@pam vagrant]# groupadd admin
[root@pam vagrant]# cat /etc/group | grep admin
printadmin:x:997:
admin:x:1003:

Добавляем пользователей vagrant,root и otusadm в группу admin:
[root@pam vagrant]#  usermod otusadm -a -G admin && usermod root -a -G admin && usermod vagrant -a -G admin
[root@pam vagrant]# cat /etc/group | grep admin
printadmin:x:997:
admin:x:1003:otusadm,root,vagrant

Проверим возможность опдключения по ssh одним из пользователей
PS C:\git\MiFirstRepo> ssh otus@192.168.57.10
The authenticity of host '192.168.57.10 (192.168.57.10)' can't be established.
ECDSA key fingerprint is SHA256:64KBGCpmlS4qefWMMH3T1WF5W3sJvKI0FOwL2e17fYo.  
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.57.10' (ECDSA) to the list of known hosts.
otus@192.168.57.10's password: 
[otus@pam ~]$ 

Теперь создадим правило, по которому все пользователи кроме тех, что указаны в группе admin не смогут подключаться в выходные дни:

Выберем метод PAM-аутентификации, так как у нас используется только ограничение по времени, то было бы логично использовать метод pam_time, однако, данный метод не работает с локальными группами пользователей, и, получается, что использование данного метода добавит нам большое количество однообразных строк с разными пользователями. В текущей ситуации лучше написать небольшой скрипт контроля и использовать модуль pam_exec

Создадим файл-скрипт /usr/local/bin/login.sh со следующим содержимым (тут значки # убрал, что бы git не воспринимал, как заголовки)
!/bin/bash
Первое условие: если день недели суббота или воскресенье
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
 Второе условие: входит ли пользователь в группу admin
 if getent group admin | grep -qw "$PAM_USER"; then
        Если пользователь входит в группу admin, то он может подключиться
        exit 0
      else
        Иначе ошибка (не сможет подключиться)
        exit 1
    fi
  Если день не выходной, то подключиться может любой пользователь
  else
    exit 0
fi

В скрипте подписаны все условия. Скрипт работает по принципу: 
Если сегодня суббота или воскресенье, то нужно проверить, входит ли пользователь в группу admin, если не входит — то подключение запрещено. При любых других вариантах подключение разрешено. 

Добавим права на исполнение файла
[root@pam vagrant]# chmod +x /usr/local/bin/login.sh

Укажем в файле /etc/pam.d/sshd модуль pam_exec и наш скрипт:
(нужно добавить строку - account    required     pam_exec.so /usr/local/bin/login.sh)
Used with polkit to reauthorize users in remote sessions
Used with polkit to reauthorize users in remote sessions
-auth      optional     pam_reauthorize.so prepare
account    required     pam_nologin.so
Важно добавить именно после этой строки, иначе не работает
account    required     pam_exec.so /usr/local/bin/login.sh
account    include      password-auth

Дата выполнения - 22.04.2023 (сб)
Проверим:

Пробуем подключиться otusadm и otus
PS C:\git\MiFirstRepo> ssh otusadm@192.168.57.10
otusadm@192.168.57.10's password: 
[otusadm@pam ~]$ 
otusadm - получилось


PS C:\git\MiFirstRepo> ssh otus@192.168.57.10  
otus@192.168.57.10's password: 
/usr/local/bin/login.sh failed: exit code 1
Connection closed by 192.168.57.10 port 22
otus - не получилось

Сменим принудительно дату и попробуем подключиться любым другим пользователем
[root@pam vagrant]# date 042112302023
Fri Apr 21 12:30:00 UTC 2023

otus@192.168.57.10's password: 
Last failed login: Sat Apr 22 12:39:03 UTC 2023 from 192.168.57.1 on ssh:notty
There were 2 failed login attempts since the last successful login.
Last login: Sat Apr 22 12:31:54 2023 from 192.168.57.1
[otus@pam ~]$ 
otus - получилось

PS C:\git\MiFirstRepo> ssh otusadm@192.168.57.10
otusadm@192.168.57.10's password: 
Last login: Sat Apr 22 12:38:56 2023 from 192.168.57.1 (дата изменена на 21 число, но т.к. 22 были упсшные подключения, не смотря на будущее время - информация выходит)
[otusadm@pam ~]$ date
Fri Apr 21 12:33:00 UTC 2023

Видим, что в пятницу удалось подключиться любым пользователем, а в сб только otusadm
