#!/bin/bash
	#Устанавливаем nfs-utils
	yum install nfs-utils
		
		#Включаем firewall
		systemctl enable firewalld --now
			
			#разрешаем в firewall доступ к сервисам NFS 
			firewall-cmd --add-service="nfs3" \
			--add-service="rpc-bind" \
			--add-service="mountd" \
			--permanent 
			firewall-cmd --reload
				
				#включаем автозапуск firewall
				systemctl enable nfs --now 
				
					#создаём и настраиваем директорию, которая будет экспортирована в будущем
					mkdir -p /srv/share/upload 
					chown -R nfsnobody:nfsnobody /srv/share 
					chmod 0777 /srv/share/upload
					
						#создаём в файле __/etc/exports__ структуру, которая позволит экспортировать ранее созданную директорию
						echo "/srv/share 192.168.50.11/32(rw,sync,root_squash)" >> /etc/exports
							
							#экспортируем ранее созданную директорию
							exportfs -r 
