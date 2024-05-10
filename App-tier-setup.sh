#!/bin/bash

# make sure to edit the placeholders values
sudo -su ec2-user
sudo yum install mysql -y
mysql -h CHANGE-TO-YOUR-RDS-ENDPOINT -u CHANGE-TO-USER-NAME -p
CREATE DATABASE webappdb;   
SHOW DATABASES;
USE webappdb;    
CREATE TABLE IF NOT EXISTS transactions(id INT NOT NULL
AUTO_INCREMENT, amount DECIMAL(10,2), description
VARCHAR(100), PRIMARY KEY(id));    
SHOW TABLES;    
INSERT INTO transactions (amount,description) VALUES ('400','groceries');   
SELECT * FROM transactions;
exit

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc
nvm install 16
nvm use 16
npm install -g pm2   
cd ~/
aws s3 cp s3://BUCKET_NAME/app-tier/ app-tier --recursive
cd ~/app-tier
npm install
pm2 start index.js
pm2 list
pm2 logs
pm2 startup

# copy the output of the above command an

pm2 save

# Test App 
curl http://localhost:4000/health  # expected response is "This is the health check"

curl http://localhost:4000/transaction # expected response {"result":[{"id":1,"amount":400,"description":"groceries"},{"id":2,"amount":100,"description":"class"},{"id":3,"amount":200,"description":"other groceries"},{"id":4,"amount":10,"description":"brownies"}]}

# app successfully setup