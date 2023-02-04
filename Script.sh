#!/bin/bash
yum install -y \
redhat-lsb-core \
wget \
rpmdevtools \
rpm-build \
createrepo \
yum-utils \
gcc
		
		# Скачиваем архив с apache
		wget --no-check-certificate https://dlcdn.apache.org/httpd/httpd-2.4.55.tar.bz2
		
			# Преобразуем скачанный пакет в SRPM
			rpmbuild -ts httpd-2.4.55.tar.bz2
			
			#Выполним  rpm -i что бы появился spec файл (без него не появляется - проверял)
			rpm -i /root/rpmbuild/SRPMS/httpd-2.4.55-1.src.rpm
			
				#Изменим строку в файле spec для apache 
				sed 's!%{_libdir}/httpd/modules/mod_mpm_event.so!#%{_libdir}/httpd/modules/mod_mpm_event.so!' /root/rpmbuild/SPECS/httpd.spec
			
					# Скачаем последние исходники длā openssl
					wget https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip
					unzip OpenSSL_1_1_1-stable.zip
			
						#Поставим все зависимости чтобы в процессе сборки не было ошибок
						yum-builddep /root/rpmbuild/SPECS/httpd.spec
						
							#Соберём пакет
							rpmbuild -bb /root/rpmbuild/SPECS/httpd.spec
								
								#Установим apache
								yum localinstall -y /root/rpmbuild/RPMS/x86_64/httpd-2.4.55-1.x86_64.rpm
								
								#Запустим веб-сервер
								systemctl start httpd
								
								#Настроим свой репозиторий
								mkdir /var/www/html/repo
								cp /root/rpmbuild/RPMS/x86_64/httpd-2.4.55-1.x86_64.rpm /var/www/html/repo
								wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm -O /var/www/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm
								createrepo /var/www/html/repo/
								
								#Внесём изменения в /etc/httpd/conf/httpd.conf
								sed -i "s/Options Indexes FollowSymLinks/Options Indexes Includes/" /etc/httpd/conf/httpd.conf
								systemctl restart httpd
								
									

								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								
								