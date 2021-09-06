#!/bin/bash
apt update -y
apt install apache2 -y
echo "<html><body><h1>Hello World from PlayQ Test</h1></body></html>" > /var/www/html/index.html
systemctl start apache2
systemctl enable apache2
