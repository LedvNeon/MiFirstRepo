#!/bin/bash

	# установим nfs-utils 
	yum install nfs-utils 
		
		# включаем firewall
		systemctl enable firewalld --now 
		
			# добавляем в __/etc/fstab__ строку
			echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
			
				systemctl daemon-reload 
					
					systemctl restart remote-fs.target 
					
					#Дальше необходимо вручную проверить серверы
