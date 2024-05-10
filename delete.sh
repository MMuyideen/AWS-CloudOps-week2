#!/bin/bash

# Set variables
REGION="us-east-1"
VPC_NAME="deen3tiervpc"
My_IP="$(curl -s https://checkip.amazonaws.com)"

# Delete Security Groups
aws ec2 delete-security-group --group-name $EXT_LB_SG
aws ec2 delete-security-group --group-name $WEB_SG
aws ec2 delete-security-group --group-name $INT_LB_SG
aws ec2 delete-security-group --group-name $PVT_SG
aws ec2 delete-security-group --group-name $DB_SG

# Detach and delete NAT Gateways
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_AZ1
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_AZ2

# Disassociate and delete Route Tables
aws ec2 disassociate-route-table --association-id $RT_web_ID
aws ec2 disassociate-route-table --association-id $RT_app_ID1
aws ec2 disassociate-route-table --association-id $RT_app_ID2
aws ec2 delete-route-table --route-table-id $RT_web_ID
aws ec2 delete-route-table --route-table-id $RT_app_ID1
aws ec2 delete-route-table --route-table-id $RT_app_ID2

# Delete Subnets
aws ec2 delete-subnet --subnet-id $web_SUB_ID1
aws ec2 delete-subnet --subnet-id $web_SUB_ID2
aws ec2 delete-subnet --subnet-id $app_SUB_ID1
aws ec2 delete-subnet --subnet-id $app_SUB_ID2
aws ec2 delete-subnet --subnet-id $db_SUB_ID1
aws ec2 delete-subnet --subnet-id $db_SUB_ID2

# Delete VPC
aws ec2 delete-vpc --vpc-id $vpc_id

# Release Elastic IPs
aws ec2 release-address --allocation-id $EIP1
aws ec2 release-address --allocation-id $EIP2


#!/bin/bash

REGION="us-east-1"
VPC_ID="YOUR_VPC_ID"
EXT_LB_SG="internet-facing-lb-sg"
WEB_SG="WebTierSG"
INT_LB_SG="internal-lb-sg"
PVT_SG="PrivateInstanceSG"
DB_SG="DatbaseSG"

# Delete security groups
EXT_LB_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$EXT_LB_SG" --query "SecurityGroups[*].GroupId" --output text --region $REGION)
aws ec2 delete-security-group --group-id $EXT_LB_SG_ID --region $REGION

WEB_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$WEB_SG" --query "SecurityGroups[*].GroupId" --output text --region $REGION)
aws ec2 delete-security-group --group-id $WEB_SG_ID --region $REGION

INT_LB_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$INT_LB_SG" --query "SecurityGroups[*].GroupId" --output text --region $REGION)
aws ec2 delete-security-group --group-id $INT_LB_SG_ID --region $REGION

PVT_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$PVT_SG" --query "SecurityGroups[*].GroupId" --output text --region $REGION)
aws ec2 delete-security-group --group-id $PVT_SG_ID --region $REGION

DB_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$DB_SG" --query "SecurityGroups[*].GroupId" --output text --region $REGION)
aws ec2 delete-security-group --group-id $DB_SG_ID --region $REGION

# Delete NAT Gateways
NAT_GW_IDS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[*].NatGatewayId" --output text --region $REGION)
for NAT_GW_ID in $NAT_GW_IDS; do
  aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID --region $REGION
done

# Delete Route Tables
ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[*].RouteTableId" --output text --region $REGION)
for ROUTE_TABLE_ID in $ROUTE_TABLE_IDS; do
  aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID --region $REGION
done

# Delete Subnets
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text --region $REGION)
for SUBNET_ID in $SUBNET_IDS; do
  aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION
done

# Delete Internet Gateway
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[*].InternetGatewayId" --output text --region $REGION)
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION

# Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION








DB_CLUSTER_IDENTIFIER="three-tier-db-cluster"
DB_INSTANCE_IDENTIFIER="my-db-instance"
DB_ENGINE="aurora"
DB_ENGINE_VERSION="5.7.mysql_aurora.2.07.2"
DB_INSTANCE_CLASS="db.t3.medium"
DB_MASTER_USERNAME="dbadmin"
DB_MASTER_PASSWORD="Qwertyuiop123"
TEMPLATE_NAME="Dev/Test"
MULTI_AZ="true"
PUBLIC_ACCESS="false"

aws rds create-db-cluster \
    --db-cluster-identifier your-cluster-name \
    --engine aurora-mysql \
    --engine-version 5.7.12 \
    --db-subnet-group-name your-db-subnet-group-name \
    --vpc-security-group-ids your-security-group-id \
    --master-user-password your-master-password \
    --master-username your-master-username \
    --backup-retention-period 1 \
    --deletion-protection \
    --region your-aws-region

aws rds create-db-instance \
    --db-instance-class db.t3.medium \
    --engine aurora-mysql \
    --db-cluster-identifier your-cluster-name \
    --db-instance-identifier your-writer-instance-name \
    --region your-aws-region

aws rds create-db-instance \
    --db-instance-class db.t3.medium \
    --engine aurora-mysql \
    --db-cluster-identifier your-cluster-name \
    --db-instance-identifier your-reader-instance-name \
    --availability-zone your-other-availability-zone \
    --region your-aws-region

    aws rds describe-db-clusters \
    --db-cluster-identifier your-cluster-name \
    --query 'DBClusters[0].WriterEndpoint' \
    --output text