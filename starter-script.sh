#!/bin/bash

REGION="us-east-1"
VPC_NAME="deen3tiervpc"
AZ1="us-east-1a"
AZ2="us-east-1b"
VPC_CIDR_BLOCK="10.0.0.0/16"
webtier_SUBNET1_CIDR="10.0.0.0/24"
webtier_SUBNET2_CIDR="10.0.1.0/24"
apptier_SUBNET1_CIDR="10.0.2.0/24"
apptier_SUBNET2_CIDR="10.0.3.0/24"
db_SUBNET1_CIDR="10.0.4.0/24"
db_SUBNET2_CIDR="10.0.5.0/24"
EXT_LB_SG="internet-facing-lb-sg"
WEB_SG="WebTierSG"
INT_LB_SG="internal-lb-sg"
PVT_SG="PrivateInstanceSG"
DB_SG="DatbaseSG"
My_IP="$(curl -s https://checkip.amazonaws.com)"

# DB VARS
DB_CLUSTER_IDENTIFIER="three-tier-db-cluster"
DB_INSTANCE_IDENTIFIER="three-tier-db-instance"
DB_INSTANCE_IDENTIFIER2="three-tier-db-instance-AZ2"
DB_ENGINE="aurora"
DB_ENGINE_VERSION="5.7.mysql_aurora.2.07.2"
DB_INSTANCE_CLASS="db.r6g.2xlarge"
DB_MASTER_USERNAME="dbadmin"
DB_MASTER_PASSWORD="MySecurePass123!"

#EC2 VARS
EC2_ROLE_NAME="threetier-ec2role"
S3_BUCKET_NAME="three-tierbucket"

# S3_BUCKET_NAME="deen3tier"
# aws s3api create-bucket \
#   --bucket $S3_BUCKET_NAME\
#   --region $REGION

#Create vpc
vpc_id=$(aws ec2 create-vpc \
 --cidr-block $VPC_CIDR_BLOCK \
 --query 'Vpc.VpcId' \
 --output text \
 --tag-specification 'ResourceType=vpc,Tags=[{Key=Name,Value=3tier-vpc}]' \
 --region $REGION)

# Enable DNS support and DNS hostnames for the VPC
aws ec2 modify-vpc-attribute \
 --vpc-id $vpc_id \
 --enable-dns-support "{\"Value\":true}"

aws ec2 modify-vpc-attribute \
 --vpc-id $vpc_id \
 --enable-dns-hostnames "{\"Value\":true}"

# Create internet gateway
IGW_ID=$(aws ec2 create-internet-gateway \
 --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=3tier-igw}]' \
 --query 'InternetGateway.InternetGatewayId' \
 --output text)

# Attach internet gateway to the VPC
aws ec2 attach-internet-gateway \
 --internet-gateway-id $IGW_ID \
 --vpc-id $vpc_id

#create webtier subnet for AZ1
web_SUB_ID1=$(aws ec2 create-subnet \
 --vpc-id $vpc_id \
 --cidr-block $webtier_SUBNET1_CIDR \
 --availability-zone $AZ1 \
 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=webtier-subnet1}]' \
 --query 'Subnet.SubnetId' \
 --output text )

#create webtier subnet for AZ2
web_SUB_ID2=$(aws ec2 create-subnet \
 --vpc-id $vpc_id \
 --cidr-block $webtier_SUBNET2_CIDR \
 --availability-zone $AZ2 \
 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=webtier-subnet2}]' \
 --query Subnet.SubnetId \
 --output text )

#create apptier subnet for AZ1
app_SUB_ID1=$(aws ec2 create-subnet \
 --vpc-id $vpc_id \
 --cidr-block $apptier_SUBNET1_CIDR \
 --availability-zone $AZ1 \
 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=apptier-subnet1}]' \
 --query Subnet.SubnetId \
 --output text )

#create apptier subnet for AZ2
app_SUB_ID2=$(aws ec2 create-subnet \
 --vpc-id $vpc_id \
 --cidr-block $apptier_SUBNET2_CIDR \
 --availability-zone $AZ2 \
 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=apptier-subnet2}]' \
 --query Subnet.SubnetId \
 --output text )

#create dbtier subnet for AZ1
db_SUB_ID1=$(aws ec2 create-subnet \
 --vpc-id $vpc_id \
 --cidr-block $db_SUBNET1_CIDR \
 --availability-zone $AZ1 \
 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dbtier-subnet1}]' \
 --query Subnet.SubnetId \
 --output text )

#create dbtier subnet for AZ2
db_SUB_ID2=$(aws ec2 create-subnet \
 --vpc-id $vpc_id \
 --cidr-block $db_SUBNET2_CIDR \
 --availability-zone $AZ2 \
 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dbtier-subnet2}]' \
 --query Subnet.SubnetId \
 --output text )


#create elastic ip for NAT in Az1 public subnet
EIP1=$(aws ec2 allocate-address\
 --domain vpc \
 --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=EIP-AZ1}]' \
 --query AllocationId \
 --output text)

#create elastic ip for NAT in Az2 public subnet
EIP2=$(aws ec2 allocate-address\
 --domain vpc \
 --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=EIP-AZ2}]' \
 --query AllocationId \
 --output text)

# Create NAT for Public Subnet 1
NAT_GW_AZ1=$(aws ec2 create-nat-gateway \
 --subnet-id  $web_SUB_ID1\
 --allocation-id $EIP1 \
 --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=NAT-AZ1}]' \
 --query NatGateway.NatGatewayId \
 --output text )

# Create NAT for Public Subnet 2
NAT_GW_AZ2=$(aws ec2 create-nat-gateway \
 --subnet-id  $web_SUB_ID2\
 --allocation-id $EIP2 \
 --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=NAT-AZ2}]' \
 --query NatGateway.NatGatewayId \
 --output text)



# Create Route table for web subnets
RT_web_ID=$(aws ec2 create-route-table \
 --vpc-id $vpc_id \
 --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=webtier-route}]' \
 --query RouteTable.RouteTableId \
 --output text )

#create route for web subnet
aws ec2 create-route \
 --route-table-id $RT_web_ID \
 --destination-cidr-block 0.0.0.0/0 \
 --gateway-id $IGW_ID

# create route table association for web subnet 1
aws ec2 associate-route-table \
 --route-table-id $RT_web_ID \
 --subnet-id $web_SUB_ID1

# create route table association for web subnet 2
aws ec2 associate-route-table \
 --route-table-id $RT_web_ID \
 --subnet-id $web_SUB_ID2

# Create Route table for app subnet1
RT_app_ID1=$(aws ec2 create-route-table \
 --vpc-id $vpc_id \
 --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=apptier-route1}]' \
 --query RouteTable.RouteTableId \
 --output text )

#create route for app subnet 1
aws ec2 create-route \
 --route-table-id $RT_app_ID1 \
 --destination-cidr-block 0.0.0.0/0 \
 --nat-gateway-id $NAT_GW_AZ1

# create route table association for app subnet 1
aws ec2 associate-route-table \
 --route-table-id $RT_app_ID1 \
 --subnet-id $app_SUB_ID1

# Create Route table for app subnet 2
RT_app_ID2=$(aws ec2 create-route-table \
 --vpc-id $vpc_id \
 --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=apptier-route2}]' \
 --query RouteTable.RouteTableId \
 --output text )

#create route for app subnet 2
aws ec2 create-route \
 --route-table-id $RT_app_ID2 \
 --destination-cidr-block 0.0.0.0/0 \
 --nat-gateway-id $NAT_GW_AZ2

# create route table association for app subnet 2
aws ec2 associate-route-table \
 --route-table-id $RT_app_ID2 \
 --subnet-id $app_SUB_ID2

# create Security Group for External load balancer
EXT_LB_SG_ID=$(aws ec2 create-security-group \
 --group-name $EXT_LB_SG \
 --description "External Load balancer security group" \
 --vpc-id $vpc_id \
 --query GroupId \
 --output text )

# create inbound rules for External Load balncer sg
aws ec2 authorize-security-group-ingress \
 --group-id $EXT_LB_SG_ID \
 --protocol tcp \
 --port 80 \
 --cidr $My_IP/32

# create Security Group for web tier 
WebTierSG_ID=$(aws ec2 create-security-group \
 --group-name $WEB_SG \
 --description "SG for web tier" \
 --vpc-id $vpc_id \
 --query GroupId \
 --output text )

# create inbound rules for webtier sg
aws ec2 authorize-security-group-ingress \
 --group-id $WebTierSG_ID \
 --protocol tcp \
 --port 80 \
 --cidr $My_IP/32

# create inbound rules for webtier sg
aws ec2 authorize-security-group-ingress \
 --group-id $WebTierSG_ID \
 --protocol tcp \
 --port 80 \
 --source-group $EXT_LB_SG_ID

# create Security Group for Internal load balancer
INT_LB_SG_ID=$(aws ec2 create-security-group \
 --group-name $INT_LB_SG \
 --description "SG for the internal load balancer" \
 --vpc-id $vpc_id \
 --query GroupId \
 --output text )

 # create inbound rules for Internal load balancer
aws ec2 authorize-security-group-ingress \
 --group-id $INT_LB_SG_ID \
 --protocol tcp \
 --port 80 \
 --source-group $WebTierSG_ID

# create Security Group for Private Instances
PVT_SG_ID=$(aws ec2 create-security-group \
 --group-name $PVT_SG \
 --description "SG for private app tier sg" \
 --vpc-id $vpc_id \
 --query GroupId \
 --output text )

 # create inbound rules for private instances
aws ec2 authorize-security-group-ingress \
 --group-id $PVT_SG_ID \
 --protocol tcp \
 --port 4000 \
 --source-group $INT_LB_SG_ID

 # create inbound rules for private instances
aws ec2 authorize-security-group-ingress \
 --group-id $PVT_SG_ID \
 --protocol tcp \
 --port 4000 \
 --cidr $My_IP/32

# create Security Group for database Instances
DB_SG_ID=$(aws ec2 create-security-group \
 --group-name $DB_SG \
 --description "SG for Databases" \
 --vpc-id $vpc_id \
 --query GroupId \
 --output text )

# create inbound rules for DB sg
aws ec2 authorize-security-group-ingress \
 --group-id $DB_SG_ID \
 --protocol tcp \
 --port 3306 \
 --source-group $PVT_SG_ID


# PART 2 DATABASE


# Create DB Subnet GrouP
aws rds create-db-subnet-group \
    --db-subnet-group-name $DB_SBG_NAME \
    --db-subnet-group-description "subnet group for the database architecture" \
    --subnet-ids $db_SUB_ID1 $db_SUB_ID2

# Crete RDS Cluster
aws rds create-db-cluster \
    --db-cluster-identifier $DB_CLUSTER_IDENTIFIER \
    --engine aurora-mysql \
    --engine-version 8.0 \
    --db-subnet-group-name $DB_SBG_NAME \
    --vpc-security-group-ids $DB_SG_ID \
    --master-user-password $DB_MASTER_PASSWORD \
    --master-username $DB_MASTER_USERNAME \
    --region $REGION

# Create RDS Writer cluster in AZ1
aws rds create-db-instance \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine aurora-mysql \
    --db-cluster-identifier $DB_CLUSTER_IDENTIFIER \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --availability-zone $AZ1

# Create RDS Writer cluster in AZ2
aws rds create-db-instance \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine aurora-mysql \
    --db-cluster-identifier $DB_CLUSTER_IDENTIFIER \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER2 \
    --availability-zone $AZ2 

# Get DB Endpoint
DB_ENDPOINT=$(aws rds describe-db-clusters \
    --db-cluster-identifier $DB_CLUSTER_IDENTIFIER \
    --query 'DBClusters[0].Endpoint' \
    --output text )


#PART 3 APP Instances

# Create IAM Role
aws iam create-role \
    --role-name $EC2_ROLE_NAME \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'


# Attach managed policies
aws iam attach-role-policy \
    --role-name $EC2_ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

aws iam attach-role-policy \
    --role-name $EC2_ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Create IAM instance profile
aws iam create-instance-profile \
 --instance-profile-name $EC2_ROLE_NAME

#Create EC2 instance for App tier
APPTIER_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-04ff98ccbfa41c9ad \
    --instance-type t2.micro \
    --subnet-id $app_SUB_ID1 \
    --iam-instance-profile Name=$EC2_ROLE_NAME \
    --security-group-ids $PVT_SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=AppTier}]' \
    --query "Reservations[*].Instances[*].[InstanceId]" \
    --output text )

WEBTIER_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-04ff98ccbfa41c9ad \
    --instance-type t2.micro \
    --subnet-id $web_SUB_ID1 \
    --iam-instance-profile Name=$EC2_ROLE_NAME \
    --security-group-ids $WebTierSG_ID \
    --subnet-id $web_SUB_ID1 \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=webTier}]' \
    --query "Reservations[*].Instances[*].[InstanceId]" \
    --output text )

# Create S3 bucket
aws s3api create-bucket \
  --bucket $S3_BUCKET_NAME \
  --region us-east-1

# upload app files
aws s3 cp \
  application-code/ \
  s3://$S3_BUCKET_NAME/ \
  --recursive

#

