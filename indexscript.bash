#!bin/bash
sudo su
yum update -y
yum install httpd -y
service httpd start
chkconfig httpd on 
mkdir /var/www/html/server1
mkdir /var/www/html/server2
echo "<html><h1> Hi this is index page1 $RANDOM </h1></html>" | sudo tee /var/www/html/index.html
echo "<html><h1> Hi this is index page2 $RANDOM Server1 </h1></html>" | sudo tee /var/www/html/server1/index.html
echo "<html><h1> Hi this is index page3 $RANDOM Server2 </h1></html>" | sudo tee /var/www/html/server2/index.htm
