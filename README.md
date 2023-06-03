# Задание:
1. Установить FreeIPA;
2. Написать Ansible playbook для конфигурации клиента;
3. Firewall должен быть включен на сервере и на клиенте*
Формат сдачи ДЗ - vagrant + ansible

# Решение:
Развернём стенд из 3-х VM с помощью Vagrantfile.
Playbook состоит из 2-х play (1 для серверов и 1 для клиентов).
ВАЖНО: при проверке Playbook зависает task по настройке ipa-server, предполагаю, что это связано с тем, что при выполнении  команды yum install -y ipa-server нужно указать следующий парметр:
Do you want to configure integrated DNS (BIND)? [no]: no
Не нашёл, как этос делать с помощью команды (ниже приведено, как я пытался).
Поэтому данный кусок выполнил вручную на сервере.
Ниже, текст task для подобной настройки из play.
Подскажите, что нужно добавить, что бы на первом запросе выбрать "no", а на последнем "yes"?
Каких параметров не хватает?
Хотя, возможно, я просто не дождался выполнения - хоть и ждал пол часа.
ПЕРЕД РАЗВЁРТЫВАНИЕМ НУЖНО ПОПРВИТЬ ЭТОТ КУСОК и добавить в Play "ipa", ИНАЧЕ ДАЛЬШЕ НЕ ПОЛУЧИТСЯ ВЫПОЛНИТЬ ПОСЛЕДНИЙ TASK КЛИЕНТОВ.


1. - name: ipa settings
2. shell: ipa-server-install --mkhomedir --hostname=ipa.otus.lan --realm=otus.lan --domain=otus.lan --no-ntp --ds-password=Otus2023 --admin-password=Otus2023
3. tags: ipa settings
4.
5. Setup complete
6. 
7. Next steps:
        1. You must make sure these network ports are open:
                2. TCP Ports:
                  3. * 80, 443: HTTP/HTTPS
                  4. * 389, 636: LDAP/LDAPS
                  5. * 88, 464: kerberos
                6. UDP Ports:
                  7. * 88, 464: kerberos
                  8. * 123: ntp

## Проверим, что установка прошла успешно
1. [root@ipa soft]# kinit admin
2. Password for admin@OTUS.LAN: 
3. [root@ipa soft]# klist 
4. Ticket cache: KEYRING:persistent:0:0
5. Default principal: admin@OTUS.LAN
6.
7. Valid starting       Expires              Service principal
8. 06/03/2023 15:07:37  06/04/2023 15:07:32  krbtgt/OTUS.LAN@OTUS.LAN
9. 
## Проверим клиентов, создав нового пользователя.

1. [root@ipa vagrant]# kinit admin
2. Password for admin@OTUS.LAN: 
3. [root@ipa vagrant]# ipa user-add otus-user --first=Otus --last=User --password
4. Password: 
5. Enter Password again to verify:
----------------------
6. Added user "otus-user"
7. ----------------------
8.   User login: otus-user
9.  First name: Otus
10. Last name: User
11.  Full name: Otus User
12.  Display name: Otus User
13.  Initials: OU
14.   Home directory: /home/otus-user
15.   GECOS: Otus User
16.  Login shell: /bin/sh
17.   Principal name: otus-user@OTUS.LAN
18.  Principal alias: otus-user@OTUS.LAN
19.  User password expiration: 20230603122755Z
20.  Email address: otus-user@otus.lan
21.  UID: 1519000001
22.  GID: 1519000001
23.  Password: True
24.  Member of groups: ipausers
25.  Kerberos keys available: True
26.
27. [root@client2 vagrant]# kinit otus-user
28. Password for otus-user@OTUS.LAN: 
29. Password expired.  You must change it now.
30. Enter new password:
31. Enter it again:
32. [root@client2 vagrant]# 

## Видим, что авторизация проходит