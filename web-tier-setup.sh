#!/bin/bash

# make sure to edit the placeholders values
sudo -su ec2-user

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc
nvm install 16
nvm use 16

cd ~/
aws s3 cp s3://BUCKET_NAME/web-tier/ web-tier --recursive # use the correct s3 bucket name

cd ~/web-tier
npm install 
npm run build

sudo amazon-linux-extras install nginx1 -y
cd /etc/nginx
ls

sudo rm nginx.conf
sudo aws s3 cp s3://BUCKET_NAME/nginx.conf .

sudo service nginx restart

chmod -R 755 /home/ec2-user # To make sure Nginx has permission to access our files

sudo chkconfig nginx on # to make sure the service starts on boot
