            #!/bin/bash
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
            sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
            systemctl restart sshd
            yum update -y
            yum install epel-release -y
            systemctl stop firewalld.service
            systemctl disable firewalld.service
            setenforce 0
            yum install docker -y
            systemctl start docker
            systemctl enable docker
            mkdir /home/vagrant/docker
            echo -e 'FROM nginx:latest \nCOPY default.conf /etc/nginx/conf.d/ \nADD srv.html /usr/share/nginx/html/ \nVOLUME /var/log/nginx/ /logs_container \nEXPOSE 80 3000' > /home/vagrant/docker/Dockerfile
            cp /mnt/default.conf /home/vagrant/docker/default.conf
            cp /mnt/srv.html /home/vagrant/docker/srv.html
            docker build -t web2 /home/vagrant/docker/
            docker run -it -d --rm -p 80:80 -p 3000:3000 --name web2  web2