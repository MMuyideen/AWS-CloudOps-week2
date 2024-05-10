#!/bin/bash


# Delete Auto Scaling groups
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $APP_ASG_NAME --force-delete
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $WEB_ASG_NAME --force-delete

# Delete Launch Templates
aws ec2 delete-launch-template --launch-template-name $APP_LAUNCH_TEMPLATE_NAME
aws ec2 delete-launch-template --launch-template-name $WEB_LAUNCH_TEMPLATE_NAME

# Delete Target Groups
aws elbv2 delete-target-group --target-group-arn $APP_TARGET_GROUP_ARN
aws elbv2 delete-target-group --target-group-arn $WEB_TARGET_GROUP_ARN

# Delete Load Balancers
aws elbv2 delete-load-balancer --load-balancer-arn $APP_ALB_ARN
aws elbv2 delete-load-balancer --load-balancer-arn $WEB_ALB_ARN

# Delete RDS instances
aws rds delete-db-instance --db-instance-identifier $DB_INSTANCE_IDENTIFIER --skip-final-snapshot
aws rds delete-db-instance --db-instance-identifier $DB_INSTANCE_IDENTIFIER2 --skip-final-snapshot

# Delete RDS cluster
aws rds delete-db-cluster --db-cluster-identifier $DB_CLUSTER_IDENTIFIER --skip-final-snapshot

# Delete DB Subnet Group
aws rds delete-db-subnet-group --db-subnet-group-name $DB_SBG_NAME

# Delete S3 bucket
aws s3 rb s3://$S3_BUCKET_NAME --force

aws ec2 terminate-instances --instance-ids $APPTier_INSTANCE_ID $WEBTier_INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $APPTier_INSTANCE_ID $WEBTier_INSTANCE_ID

aws ec2 revoke-security-group-ingress --group-id $EXT_LB_SG_ID --protocol tcp --port 80 --cidr $My_IP/32
aws ec2 revoke-security-group-ingress --group-id $WebTierSG_ID --protocol tcp --port 80 --cidr $My_IP/32
aws ec2 revoke-security-group-ingress --group-id $WebTierSG_ID --protocol tcp --port 80 --source-group $EXT_LB_SG_ID
aws ec2 revoke-security-group-ingress --group-id $INT_LB_SG_ID --protocol tcp --port 80 --source-group $WebTierSG_ID
aws ec2 revoke-security-group-ingress --group-id $PVT_SG_ID --protocol tcp --port 4000 --source-group $INT_LB_SG_ID
aws ec2 revoke-security-group-ingress --group-id $PVT_SG_ID --protocol tcp --port 4000 --cidr $My_IP/32
aws ec2 revoke-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --source-group $PVT_SG_ID

# Delete Security Groups
aws ec2 delete-security-group --group-id $EXT_LB_SG_ID
aws ec2 delete-security-group --group-id $WebTierSG_ID
aws ec2 delete-security-group --group-id $INT_LB_SG_ID
aws ec2 delete-security-group --group-id $PVT_SG_ID
aws ec2 delete-security-group --group-id $DB_SG_ID


# Delete Subnets
aws ec2 delete-subnet --subnet-id $web_SUB_ID1
aws ec2 delete-subnet --subnet-id $web_SUB_ID2
aws ec2 delete-subnet --subnet-id $app_SUB_ID1
aws ec2 delete-subnet --subnet-id $app_SUB_ID2
aws ec2 delete-subnet --subnet-id $db_SUB_ID1
aws ec2 delete-subnet --subnet-id $db_SUB_ID2

# Delete Internet Gateway
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $vpc_id
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# Delete NAT Gateways
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_AZ1
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_AZ2

# Release Elastic IPs
aws ec2 release-address --allocation-id $EIP1
aws ec2 release-address --allocation-id $EIP2

# Delete Route Tables
aws ec2 delete-route-table --route-table-id $RT_web_ID
aws ec2 delete-route-table --route-table-id $RT_app_ID1
aws ec2 delete-route-table --route-table-id $RT_app_ID2

# Delete VPC
aws ec2 delete-vpc --vpc-id $vpc_id

# Resources Deleted successfully