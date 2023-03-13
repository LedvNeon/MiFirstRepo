# Поднимем VM из Vagrantfile, указанного в методичке (поместив его в C:\git\MiFirstRepo) 
# https://gist.github.com/lalbrekht/f811ce9a921570b1d95e07a7dbebeb1e, со следующими изменениями:
# private_network заменим на public_network, что бы VM была в моём сетевом окружении и укажим IP=192.168.1.70
# У меня в сетевом окружении есть wsl ubuntu, на котрой уже развёрнут ansible, настроенный в рамках
# выполнения дз по selinux (следующая лаба, просто делал раньше, ссылка на епозиторий - https://github.com/LedvNeon/MiFirstRepo/tree/selinux)

PS C:\git\MiFirstRepo> vagrant up

# Подключимся по ssh и перейдём режим суперпользователя
PS C:\git\MiFirstRepo> vagrant ssh
[vagrant@nginx ~]$ sudo su
[root@nginx vagrant]# 
[root@nginx ansible]# hostname
nginx
[root@nginx ansible]# yum update
[root@nginx ansible]# yum install epel-release
# Машинка доступна - всё хорошо

# На wsl ubuntu перенесём папку ./vagrant из C:\git\MiFirstRepo и положим в \\wsl$\Ubuntu-20.04\home\dima
root@DESKTOP-9BHG4U3:/home/dima# pwd
/home/dima
# Проверим наличие данного файла в указанной диреткории
root@DESKTOP-9BHG4U3:/home/dima# ls -la
total 20
drwxr-xr-x 1 dima dima  512 Mar 12 23:11 .
drwxr-xr-x 1 root root  512 Mar  7  2021 ..
drwxr-xr-x 1 dima dima  512 Mar  6 16:09 .ansible
-rw------- 1 dima dima  845 Mar  6 22:23 .bash_history
-rw-r--r-- 1 dima dima  220 Mar  7  2021 .bash_logout
-rw-r--r-- 1 dima dima 3771 Mar  7  2021 .bashrc
drwxr-xr-x 1 dima dima  512 Mar  7  2021 .landscape
-rw-r--r-- 1 dima dima    0 Mar 12 22:48 .motd_shown
-rw-r--r-- 1 dima dima  807 Mar  7  2021 .profile
-rw-r--r-- 1 dima dima    0 Mar  6 15:57 .sudo_as_admin_successful
drwxr-xr-x 1 dima dima  512 Mar 12 23:10 .vagrant
-rw------- 1 dima dima 1239 Mar 12 23:08 .viminfo
drwxr-xr-x 1 dima dima  512 Mar  6 15:55 files
-rw-r--r-- 1 root root  158 Mar 12 23:11 hosts
-rw-r--r-- 1 dima dima 3117 Mar  6 21:00 playbook.yml
drwxr-xr-x 1 root root  512 Mar  6 20:27 testbook
# Файл есть

# Создадим в /home/dima файл hosts со следующем содержанием:
<#
[web]
# имя хоста      IP хоста      порт для опдлкючения   пользователь    адрес файла с ключом ssh для подключения
nginx ansible_host=192.168.1.70 ansible_port=22 ansible_user=vagrant ansible_private_key_file=/home/dima/.vagrant/machines/nginx/virtualbox/private_key
#>

# Проверим возможность работы с удалённм хостом

root@DESKTOP-9BHG4U3:/home/dima# ansible nginx -i hosts -m ping
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
# Получили ответ pong - всё хорошо

# Создадим файл конфигурации ansible.cfg, что не указывать явно hosts и прочие параметры. Их пропишем в ansible.cfg.
root@DESKTOP-9BHG4U3:/home/dima# cat ansible.cfg
[defaults]
inventory = hosts
remote_user = vagrant
host_key_checking = False
retry_files_enabled = False

# Теперь уберём лишнее из hosts (информацию о пользователе)
root@DESKTOP-9BHG4U3:/home/dima# cat hosts
[web]
nginx ansible_host=192.168.1.70 ansible_port=22 ansible_private_key_file=/home/dima/.vagrant/machines/nginx/virtualbox/private_key

# Ещё раз проверим, что всё работает
root@DESKTOP-9BHG4U3:/home/dima# ansible nginx -m ping
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
# Получили pong - всё хорошо
<#
Теперь, когда мы убедились, что у нас всё подготовлено - установлен
Ansible, поднят хост для теста и Ansible имеет к нему доступ, мы можем
конфигурировать наш хост.
Для начала воспользуемсā Ad-Hoc командами и выполним некоторые
удаленные команды на нашем хосте.
#>

# Посмотрим ядро
root@DESKTOP-9BHG4U3:/home/dima# ansible nginx -m command -a "uname -r"
nginx | CHANGED | rc=0 >>
3.10.0-1160.88.1.el7.x86_64

# Посомтрим статус firewalld
root@DESKTOP-9BHG4U3:/home/dima# ansible nginx -m systemd -a name=firewalld
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "name": "firewalld",
    "status": {
        "ActiveEnterTimestampMonotonic": "0",
        "ActiveExitTimestampMonotonic": "0",
        "ActiveState": "inactive",
        "After": "polkit.service system.slice basic.target dbus.service",
        "AllowIsolate": "no",
        "AmbientCapabilities": "0",
        "AssertResult": "no",
        "AssertTimestampMonotonic": "0",
        "Before": "shutdown.target network-pre.target",
        "BlockIOAccounting": "no",
        "BlockIOWeight": "18446744073709551615",
        "BusName": "org.fedoraproject.FirewallD1",
        "CPUAccounting": "no",
        "CPUQuotaPerSecUSec": "infinity",
        "CPUSchedulingPolicy": "0",
        "CPUSchedulingPriority": "0",
        "CPUSchedulingResetOnFork": "no",
        "CPUShares": "18446744073709551615",
        "CanIsolate": "no",
        "CanReload": "yes",
        "CanStart": "yes",
        "CanStop": "yes",
        "CapabilityBoundingSet": "18446744073709551615",
        "CollectMode": "inactive",
        "ConditionResult": "no",
        "ConditionTimestampMonotonic": "0",
        "Conflicts": "shutdown.target ip6tables.service ipset.service iptables.service ebtables.service",
        "ControlPID": "0",
        "DefaultDependencies": "yes",
        "Delegate": "no",
        "Description": "firewalld - dynamic firewall daemon",
        "DevicePolicy": "auto",
        "Documentation": "man:firewalld(1)",
        "EnvironmentFile": "/etc/sysconfig/firewalld (ignore_errors=yes)",
        "ExecMainCode": "0",
        "ExecMainExitTimestampMonotonic": "0",
        "ExecMainPID": "0",
        "ExecMainStartTimestampMonotonic": "0",
        "ExecMainStatus": "0",
        "ExecReload": "{ path=/bin/kill ; argv[]=/bin/kill -HUP $MAINPID ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }",
        "ExecStart": "{ path=/usr/sbin/firewalld ; argv[]=/usr/sbin/firewalld --nofork --nopid $FIREWALLD_ARGS ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }",
        "FailureAction": "none",
        "FileDescriptorStoreMax": "0",
        "FragmentPath": "/usr/lib/systemd/system/firewalld.service",
        "GuessMainPID": "yes",
        "IOScheduling": "0",
        "Id": "firewalld.service",
        "IgnoreOnIsolate": "no",
        "IgnoreOnSnapshot": "no",
        "IgnoreSIGPIPE": "yes",
        "InactiveEnterTimestampMonotonic": "0",
        "InactiveExitTimestampMonotonic": "0",
        "JobTimeoutAction": "none",
        "JobTimeoutUSec": "0",
        "KillMode": "mixed",
        "KillSignal": "15",
        "LimitAS": "18446744073709551615",
        "LimitCORE": "18446744073709551615",
        "LimitCPU": "18446744073709551615",
        "LimitDATA": "18446744073709551615",
        "LimitFSIZE": "18446744073709551615",
        "LimitLOCKS": "18446744073709551615",
        "LimitMEMLOCK": "65536",
        "LimitMSGQUEUE": "819200",
        "LimitNICE": "0",
        "LimitNOFILE": "4096",
        "LimitNPROC": "656",
        "LimitRSS": "18446744073709551615",
        "LimitRTPRIO": "0",
        "LimitRTTIME": "18446744073709551615",
        "LimitSIGPENDING": "656",
        "LimitSTACK": "18446744073709551615",
        "LoadState": "loaded",
        "MainPID": "0",
        "MemoryAccounting": "no",
        "MemoryCurrent": "18446744073709551615",
        "MemoryLimit": "18446744073709551615",
        "MountFlags": "0",
        "Names": "firewalld.service",
        "NeedDaemonReload": "no",
        "Nice": "0",
        "NoNewPrivileges": "no",
        "NonBlocking": "no",
        "NotifyAccess": "none",
        "OOMScoreAdjust": "0",
        "OnFailureJobMode": "replace",
        "PermissionsStartOnly": "no",
        "PrivateDevices": "no",
        "PrivateNetwork": "no",
        "PrivateTmp": "no",
        "ProtectHome": "no",
        "ProtectSystem": "no",
        "RefuseManualStart": "no",
        "RefuseManualStop": "no",
        "RemainAfterExit": "no",
        "Requires": "system.slice basic.target",
        "Restart": "no",
        "RestartUSec": "100ms",
        "Result": "success",
        "RootDirectoryStartOnly": "no",
        "RuntimeDirectoryMode": "0755",
        "SameProcessGroup": "no",
        "SecureBits": "0",
        "SendSIGHUP": "no",
        "SendSIGKILL": "yes",
        "Slice": "system.slice",
        "StandardError": "null",
        "StandardInput": "null",
        "StandardOutput": "null",
        "StartLimitAction": "none",
        "StartLimitBurst": "5",
        "StartLimitInterval": "10000000",
        "StartupBlockIOWeight": "18446744073709551615",
        "StartupCPUShares": "18446744073709551615",
        "StatusErrno": "0",
        "StopWhenUnneeded": "no",
        "SubState": "dead",
        "SyslogLevelPrefix": "yes",
        "SyslogPriority": "30",
        "SystemCallErrorNumber": "0",
        "TTYReset": "no",
        "TTYVHangup": "no",
        "TTYVTDisallocate": "no",
        "TasksAccounting": "no",
        "TasksCurrent": "18446744073709551615",
        "TasksMax": "18446744073709551615",
        "TimeoutStartUSec": "1min 30s",
        "TimeoutStopUSec": "1min 30s",
        "TimerSlackNSec": "50000",
        "Transient": "no",
        "Type": "dbus",
        "UMask": "0022",
        "UnitFilePreset": "enabled",
        "UnitFileState": "disabled",
        "Wants": "network-pre.target",
        "WatchdogTimestampMonotonic": "0",
        "WatchdogUSec": "0"
    }
}

# По методичке нужно удалённо поставить epel-release, но он уже установлен. Просто приведу команду, как пример.
# ansible nginx -m yum -a "name=epel-release state=present" -b

# Напишем простой playbook для установки epel-release
root@DESKTOP-9BHG4U3:/home/dima# cat epel.yml
---
  - name: Install EPEL Repo
    hosts: nginx
    become: true
    tasks:
     - name: Install EPEL Repo package from standart repo
       yum:
         name: epel-release
         state: present

root@DESKTOP-9BHG4U3:/home/dima# ansible-playbook epel.yml

PLAY [Install EPEL Repo] **********************************************************************

TASK [Gathering Facts] ************************************************************************
ok: [nginx]

TASK [Install EPEL Repo package from standart repo] *******************************************
ok: [nginx]

PLAY RECAP ************************************************************************************
nginx                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

# Выполним ansible nginx -m yum -a "name=epel-release state=absent" -b и попробуем запустить playbook ещё раз

root@DESKTOP-9BHG4U3:/home/dima# ansible nginx -m yum -a "name=epel-release state=absent" -b
nginx | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "changes": {
        "removed": [
            "epel-release"
        ]
    },
    "msg": "",
    "rc": 0,
    "results": [
        "Loaded plugins: fastestmirror\nResolving Dependencies\n--> Running transaction check\n---> Package epel-release.noarch 0:7-14 will be erased\n--> Finished Dependency Resolution\n\nDependencies Resolved\n\n================================================================================\n Package                Arch             Version          Repository       Size\n================================================================================\nRemoving:\n epel-release           noarch           7-14             @epel            25 k\n\nTransaction Summary\n================================================================================\nRemove  1 Package\n\nInstalled size: 25 k\nDownloading packages:\nRunning transaction check\nRunning transaction test\nTransaction test succeeded\nRunning transaction\n  Erasing    : epel-release-7-14.noarch                                     1/1 \n  Verifying  : epel-release-7-14.noarch                                     1/1 \n\nRemoved:\n  epel-release.noarch 0:7-14                                                    \n\nComplete!\n"
    ]
}

# Результат запуска epel.yml ниже
root@DESKTOP-9BHG4U3:/home/dima# ansible-playbook epel.yml

PLAY [Install EPEL Repo] *******************************************************************************************

TASK [Gathering Facts] *********************************************************************************************
ok: [nginx]

TASK [Install EPEL Repo package from standart repo] ****************************************************************
changed: [nginx]

PLAY RECAP *********************************************************************************************************
nginx                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 

# Видим одно изменение changed=1 

# ТЕПЕРЬ НАПИШЕМ PLAYBOOK ДЛЯ УСТАНОВКИ NGINX

root@DESKTOP-9BHG4U3:/home/dima# mv epel.yml /home/dima/nginx.yml
root@DESKTOP-9BHG4U3:/home/dima# ls
1.yml  ansible.cfg  files  hosts  nginx.yml  playbook.yml  testbook

root@DESKTOP-9BHG4U3:/home/dima# cat nginx.yml
---
  - name: NGINX | Install and configure NGINX
    hosts: nginx
    become: true

    tasks:
      - name: NGINX | Install EPEL Repo package from standart repo
        yum:
          name: epel-release
          state: present
        tags:
          - epel-package
          - packages

      - name: NGINX | Install NGINX package from EPEL Repo
        yum:
          name: nginx
          state: latest
        tags:
          - nginx-package
          - packages
root@DESKTOP-9BHG4U3:/home/dima#

# Тэги добавили, что бы давать задания выборочно
# Выведем в консоль все тэги

root@DESKTOP-9BHG4U3:/home/dima# ansible-playbook nginx.yml --list-tags

playbook: nginx.yml

  play #1 (nginx): NGINX | Install and configure NGINX  TAGS: []
      TASK TAGS: [epel-package, nginx-package, packages]

# Запустим установку nginx
root@DESKTOP-9BHG4U3:/home/dima# ansible-playbook nginx.yml -t nginx-package

PLAY [NGINX | Install and configure NGINX] *************************************************************************

TASK [Gathering Facts] *********************************************************************************************
ok: [nginx]

TASK [NGINX | Install NGINX package from EPEL Repo] ****************************************************************
changed: [nginx]

PLAY RECAP *********************************************************************************************************
nginx                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  

# Добавим шаблон для конфига NGINX и модуль, который будет копировать этот шаблон на хост.
<# 
Для начала создадим директорию templates, где поместим файл nginx.conf.j2 следующего содержания:
# {{ ansible_managed }}
events {
    worker_connections 1024;
}

http {
    server {
        listen       {{ nginx_listen_port }} default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        location / {
        }
    }
}
#>

root@DESKTOP-9BHG4U3:/home/dima# mkdir templates
root@DESKTOP-9BHG4U3:/home/dima# cd templates/
root@DESKTOP-9BHG4U3:/home/dima# touch nginx.conf.j2
root@DESKTOP-9BHG4U3:/home/dima# vi nginx.conf.j2

root@DESKTOP-9BHG4U3:/home/dima# cat nginx.yml
---
  - name: NGINX | Install and configure NGINX
    hosts: nginx
    become: true

    tasks:
      - name: NGINX | Install EPEL Repo package from standart repo
        yum:
          name: epel-release
          state: present
        tags:
          - epel-package
          - packages

      - name: NGINX | Install NGINX package from EPEL Repo
        yum:
          name: nginx
          state: latest
        tags:
          - nginx-package
          - packages

       - name: NGINX | Create NGINX config file from template
           template:
              src: templates/nginx.conf.j2
              dest: /tmp/nginx.conf
            tags:
               - nginx-configuration

# Добавим так же переменную с портом

root@DESKTOP-9BHG4U3:/home/dima# cat nginx.yml
---
  - name: NGINX | Install and configure NGINX
    hosts: nginx
    become: true
    vars:
        nginx_listen_port: 8080

    tasks:
      - name: NGINX | Install EPEL Repo package from standart repo
        yum:
          name: epel-release
          state: present
        tags:
          - epel-package
          - packages

      - name: NGINX | Install NGINX package from EPEL Repo
        yum:
          name: nginx
          state: latest
        tags:
          - nginx-package
          - packages

       - name: NGINX | Create NGINX config file from template
           template:
              src: templates/nginx.conf.j2
              dest: /tmp/nginx.conf
            tags:
               - nginx-configuration

# Теперь создадим handler и добавим notify к копированию шаблона. Теперь каждый раз когда конфиг будет изменāться - сервис перезагрузится.
root@DESKTOP-9BHG4U3:/home/dima# cat nginx.yml
---
  - name: NGINX | Install and configure NGINX
    hosts: nginx
    become: true
    vars:
      nginx_listen_port: 8080

    tasks:
      - name: NGINX | Install EPEL Repo package from standart repo
        yum:
          name: epel-release
          state: present
        tags:
          - epel-package
          - packages

      - name: NGINX | Install NGINX package from EPEL Repo
        yum:
          name: nginx
          state: latest
        notify:
          - restart nginx
        tags:
          - nginx-package
          - packages

      - name: NGINX | Create NGINX config file from template
        template:
          src: templates/nginx.conf.j2
          dest: /etc/nginx/nginx.conf
        notify:
          - reload nginx
        tags:
          - nginx-configuration

    handlers:
      - name: restart nginx
        systemd:
          name: nginx
          state: restarted
          enabled: yes

      - name: reload nginx
        systemd:
          name: nginx
          state:

# Запустим playbook

root@DESKTOP-9BHG4U3:/home/dima# ansible-playbook nginx.yml

PLAY [NGINX | Install and configure NGINX] *************************************************************************

TASK [Gathering Facts] *********************************************************************************************
ok: [nginx]

TASK [NGINX | Install EPEL Repo package from standart repo] ********************************************************
ok: [nginx]

TASK [NGINX | Install NGINX package from EPEL Repo] ****************************************************************
ok: [nginx]

TASK [NGINX | Create NGINX config file from template] **************************************************************
changed: [nginx]

RUNNING HANDLER [reload nginx] *************************************************************************************
changed: [nginx]

PLAY RECAP *********************************************************************************************************
nginx                      : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 

# Видим, что ошибок нет. Изменений должно было быть ольше, но я запустил Playbook до того, как создал файл шаблона.
# Поэтому после размещения файла шаблона и повторного запуска playbook изменений всего 2, а не как вметодичке

# Проверим, что web-сервер работает:

root@DESKTOP-9BHG4U3:/home/dima# curl http://192.168.1.70:8080
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css">

        html {
        background-image:url(img/html-background.png);
        background-color: white;
        font-family: "DejaVu Sans", "Liberation Sans", sans-serif;
        font-size: 0.85em;
        line-height: 1.25em;
        margin: 0 4% 0 4%;
        }
# Целком вывод не приводил, скриншот с брайзера приложу в репозиторий