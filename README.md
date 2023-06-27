# Задание:
Для выполнения домашнего задания используйте методичку https://drive.google.com/file/d/139irfqsbAxNMjVcStUN49kN7MXAJr_z9/view?usp=share_link
Что нужно сделать?
В материалах приложены ссылки на вагрант для репликации и дамп базы bet.dmp
1. Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы:
| bookmaker |
| competition |
| market |
| odds |
| outcome

2. Настроить GTID репликацию
x
варианты которые принимаются к сдаче
рабочий вагрантафайл
скрины или логи SHOW TABLES
конфиги*
пример в логе изменения строки и появления строки на реплике*

# Решение:
## ВАЖНО: в mysql.yml закомментирован Play "copy conf on slave" это сделано для того, что бы выполнить первую часть задания. На пункте 9 его можно выполнить - он с тегом.
1. Развернём 2 сервера - master и slave из Vagrantfile (приложен в репозиторий)

На хост нужно скачать mysql.yml, hosts, ansible.cfg в /home/vagrant/mysql/.
Файлы конфигов поместить в /home/vagrant/mysql/conf/.
Файл дампа поместить в /home/vagrant/mysql/damp/.

2. Развёртывание происходит в сети public.
3. Настройка будет производиться по средствами playbook mysql.yml (приложен в репозиторий).
4. В рамках playbook будет утановлен percona server, скопированы файлы кнфигурации на master и  damp DB,
5. После копирования файлов конфига в /etc/my.cnf.d, сменим пароль вручную, посмотрев автоматически сгенерированный в /var/log/mysqld.log

[root@master vagrant]# cat /var/log/mysqld.log | grep pass*

2023-06-27T06:50:15.807310Z 1 [Note] A temporary password is generated for root@localhost: pg1=/elj:7*M

### Примечание:
При настройке через ansible возникала проблема, что после перекидывания файла конфига с хостовой машины, при входе в MySQL было предупреждение, что файл /etc/my.cnf проигнорирован. Пробовал разные права 777, 755, 644 и т.д., но не помогало. Если проверять ихзначальные права, то там используются 644 и владелец root root.
[root@master vagrant]# ls -la /etc/my.cnf

-rw-r--r--. 1 root root 636 Jun 27 06:45 /etc/my.cnf

Подскажите, как нужно было задать корреткно права?

### Внутри sql
[root@slave vagrant]# mysql -uroot -p

Enter password:

mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'P@ssw0rd2023';

Query OK, 0 rows affected (0.01 sec)

mysql> FLUSH PRIVILEGES;

Query OK, 0 rows affected (0.00 sec)

Теперь ещё раз проверим server_id

[root@slave vagrant]# mysql -uroot -p

Enter password:

mysql> SELECT @@server_id;

+-------------+
| @@server_id |
+-------------+
|           0 |
+-------------+

1 row in set (0.00 sec) - это на slave

mysql> SELECT @@server_id;

+-------------+
| @@server_id |
+-------------+
|           1 |
+-------------+

1 row in set (0.00 sec) - это на master

Убеждаемся на master что GTID (глобальный идентификатор транзакций) включен:

mysql> SHOW VARIABLES LIKE 'gtid_mode';

+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_mode     | ON    |
+---------------+-------+

1 row in set (0.03 sec)

7. Теперь восстановим БД из дампа врчуную.

[root@master vagrant]# mysql -uroot -p

Enter password: 

mysql> CREATE DATABASE bet;

Query OK, 1 row affected (0.00 sec)

mysql> exit

Bye

[root@master vagrant]# mysql -uroot -p -D bet < /home/vagrant/bet.dmp

Enter password:

mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed

mysql> SHOW TABLES;

+------------------+
| Tables_in_bet    |
+------------------+
| bookmaker        |
| competition      |
| events_on_demand |
| market           |
| odds             |
| outcome          |
| v_same_event     |
+------------------+

7 rows in set (0.00 sec)

8. Создадим пользователя для репликации и дадим ему права на это

mysql> CREATE USER 'repl'@'%' IDENTIFIED BY '!OtusLinux2023';
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT user,host FROM mysql.user where user='repl';
+------+------+
| user | host |
+------+------+
| repl | %    |
+------+------+
1 row in set (0.00 sec)

mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%' IDENTIFIED BY '!OtusLinux2023';
Query OK, 0 rows affected, 1 warning (0.01 sec)

8. Дампим базу
[root@master vagrant]# mysqldump --all-databases --triggers --routines --master-data --ignore-table=bet.events_on_demand --ignore-table=bet.v_same_event -uroot -p > /home/vagrant/master.sql

Enter password: 

Warning: A partial dump from a server that has GTIDs will by default include the GTIDs of all transactions, even those that changed suppressed parts of the database. If you don't want to restore GTIDs, pass --set-gtid-purged=OFF. To make a complete dump, pass --all-databases --triggers --routines --events.

[root@master vagrant]# ls

bet.dmp  master.sql

9. Теперь по средствам ansible скопируем конфиги на slave и изменим врчуную следующее:

- правим в /etc/my.cnf.d/01-base.cnf директиву server-id = 2

- раскомментируем в /etc/my.cnf.d/05-binlog.cnf строки:

#replicate-ignore-table=bet.events_on_demand

#replicate-ignore-table=bet.v_same_event
(Таким образом указываем таблицы которые будут игнорироваться при репликации)

10. Копируем master.sql на slave - я сделал вручную, сгенереировав ssh ключ и прописав его на slave
[root@master vagrant]# scp /home/vagrant/master.sql vagrant@172.20.10.4:/home/vagrant

master.sql  

[root@slave vagrant]# ls /home/vagrant/

master.sql

11. Перезапустим Mysql на slave и проверим server-id

mysql> select @@server_id;

+-------------+
| @@server_id |
+-------------+
|           2 |
+-------------+

1 row in set (0.00 sec)

12. Заливаем дамп мастера и убеждаемся что база есть и она без лишних таблиц:

mysql> SOURCE /home/vagrant/master.sql;

Query OK, 0 rows affected (0.08 sec)

Query OK, 0 rows affected (0.01 sec)

.
.
.

Query OK, 0 rows affected (0.00 sec)

mysql> SHOW DATABASES LIKE 'bet';

+----------------+
| Database (bet) |
+----------------+
| bet            |
+----------------+

1 row in set (0.00 sec)

mysql> USE bet;

Database changed

mysql> show tables;

+---------------+
| Tables_in_bet |
+---------------+
| bookmaker     |
| competition   |
| market        |
| odds          |
| outcome       |
+---------------+

5 rows in set (0.00 sec)
(видим что таблиц v_same_event и events_on_demand нет)

13. Запустим репликацию

mysql> CHANGE MASTER TO MASTER_HOST = "172.20.10.3", MASTER_PORT = 3306, MASTER_USER = "repl", MASTER_PASSWORD = "!OtusLinux2023", MASTER_AUTO_POSITION = 1;
Query OK, 0 rows affected, 2 warnings (0.02 sec)

mysql> START SLAVE;
Query OK, 0 rows affected (0.01 sec)

mysql> SHOW SLAVE STATUS\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 172.20.10.3
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000004
          Read_Master_Log_Pos: 119631
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 1231
        Relay_Master_Log_File: mysql-bin.000004
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
            .
            .
            .
            
                       Retrieved_Gtid_Set: deb88ce9-14b6-11ee-8a10-5254004d77d3:39-41
            Executed_Gtid_Set: deb88ce9-14b6-11ee-8a10-5254004d77d3:1-41,

Тут правда пришлось сделать drop user repl на slave.

14. Промерим репликацию, добавив информацию на master

mysql> USE bet;

Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed

mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
Query OK, 1 row affected (0.00 sec)

mysql> SELECT * FROM bookmaker;

+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+

5 rows in set (0.00 sec)

Теперь на slave
mysql> use bet
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed

mysql> SELECT * FROM bookmaker;

+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+

5 rows in set (0.00 sec)

Так же изменения пишутся в bin-log.
mysql> SHOW BINARY LOGS;
+------------------+-----------+
| Log_name         | File_size |
+------------------+-----------+
| mysql-bin.000001 |       573 |
| mysql-bin.000002 |       217 |
| mysql-bin.000003 |    114787 |
+------------------+-----------+
3 rows in set (0.00 sec)
mysql> exit
Bye
tail -n 10 /var/lib/mysql/mysql-bin.000001

