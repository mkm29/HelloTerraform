#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo service httpd start
sudo chkconfig httpd on
sudo bash -c 'echo "<html><h1>Hello, Terraform!</h1></html>" > /var/www/html/index.html'