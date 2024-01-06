#!/bin/bash
sudo yum update -y
sudo yum install php php-mysqlnd httpd -y
sudo yum install wget -y
wget https://wordpress.org/wordpress-4.8.14.tar.gz
tar -xzf wordpress-4.8.14.tar.gz
sudo cp -r wordpress /var/www/html/
sudo chown -R apache.apache /var/www/html/
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl restart httpd