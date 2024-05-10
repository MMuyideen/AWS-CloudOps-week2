#!/bin/bash

#APP VARS
APP_IMAGE_NAME="AppTierImage"
APP_TARGET_GROUP_NAME="three-tier-target-group"
APP_ALB_NAME="apptier-internal-lb"
APP_LAUNCH_TEMPLATE_NAME="apptier-launch-template"
APP_ASG_NAME="threetier-ASG"

#WEB VARS
WEB_IMAGE_NAME="WebTierImage"
WEB_TARGET_GROUP_NAME="three-tier-web-target-group"
WEB_ALB_NAME="webtier-internal-lb"
WEB_LAUNCH_TEMPLATE_NAME="webtier-launch-template"
WEB_ASG_NAME="threetier-web-ASG"

# upload app files
aws s3 cp \
  application-code/ \
  s3://$S3_BUCKET_NAME/ \
  --recursive


# Get instance Id for app tier
APPTier_INSTANCE_ID=$(aws ec2 describe-instances \
 --filters "Name=tag-value,Values=AppTier" \
 --query "Reservations[*].Instances[*].[InstanceId]" \
 --output text )
echo $APPTier_INSTANCE_ID

# Create Image for app tier
APPTier_IMAGE_ID=$(aws ec2 create-image \
    --instance-id $APPTier_INSTANCE_ID \
    --name $APP_IMAGE_NAME \
    --description "An AMI for my App tier" \
    --tag-specifications "ResourceType=image,Tags=[{Key=cost-center,Value=cc123}]" "ResourceType=snapshot,Tags=[{Key=cost-center,Value=cc123}]" \
    --query 'ImageId' \
    --output text )

echo $APPTier_IMAGE_ID


# Create Target group without health, remember to update in console with /health
APP_TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name $APP_TARGET_GROUP_NAME \
    --protocol HTTP \
    --port 4000 \
    --vpc-id vpc-0aa37fc1cd2b0a8b8 \
    --target-type instance \
    --query 'TargetGroups[*].TargetGroupArn' \
    --output text)

echo $TARGET_GROUP_ARN

# Create ALB for app tier
APP_ALB_ARN=$(aws elbv2 create-load-balancer \
    --name $APP_ALB_NAME \
    --scheme internal \
    --type application \
    --security-groups $INT_LB_SG_ID \
    --subnets $app_SUB_ID1 $app_SUB_ID2 \
    --query 'LoadBalancers[*].LoadBalancerArn'\
    --output text )

#create Alb lister to target group for app tier
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN

# Create Launch Templates app tier
aws ec2 create-launch-template \
    --launch-template-name $APP_LAUNCH_TEMPLATE_NAME \
    --version-description "Version 1" \
    --launch-template-data file://app-launch-template-data.json

# Create Auto Scaling group app tier
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name $APP_ASG_NAME \
    --launch-template LaunchTemplateName=$APP_LAUNCH_TEMPLATE_NAME,Version=1 \
    --min-size 2 \
    --max-size 2 \
    --desired-capacity 2 \
    --target-group-arns $TARGET_GROUP_ARN \
    --vpc-zone-identifier "$app_SUB_ID1, $app_SUB_ID2"

#Create for WEB tier

# reupload app files after updating the nginx file with lb dns
aws s3 cp \
  application-code/ \
  s3://$S3_BUCKET_NAME/ \
  --recursive

# Get instance Id for web tier
WEBTier_INSTANCE_ID=$(aws ec2 describe-instances \
 --filters "Name=tag-value,Values=webTier" \
 --query "Reservations[*].Instances[*].[InstanceId]" \
 --output text )
echo $WEBTier_INSTANCE_ID

# Create Image for web tier
WEBTier_IMAGE_ID=$(aws ec2 create-image \
    --instance-id $WEBTier_INSTANCE_ID \
    --name $WEB_IMAGE_NAME \
    --description "An AMI for my WEB tier" \
    --tag-specifications "ResourceType=image,Tags=[{Key=cost-center,Value=cc123}]" "ResourceType=snapshot,Tags=[{Key=cost-center,Value=cc123}]" \
    --query 'ImageId' \
    --output text )

echo $WEBTier_IMAGE_ID


# Create Target group without health, remember to update in console with /health
WEB_TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name $WEB_TARGET_GROUP_NAME \
    --protocol HTTP \
    --port 80 \
    --vpc-id vpc-0aa37fc1cd2b0a8b8 \
    --target-type instance \
    --query 'TargetGroups[*].TargetGroupArn' \
    --output text)

echo $WEB_TARGET_GROUP_ARN

# Create ALB for app tier
WEB_ALB_ARN=$(aws elbv2 create-load-balancer \
    --name $WEB_ALB_NAME \
    --scheme internet-facing \
    --type application \
    --security-groups $EXT_LB_SG_ID \
    --subnets $web_SUB_ID1 $web_SUB_ID2 \
    --query 'LoadBalancers[*].LoadBalancerArn'\
    --output text )

#create Alb lister to target group for app tier
aws elbv2 create-listener \
    --load-balancer-arn $WEB_ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$WEB_TARGET_GROUP_ARN

# Create Launch Templates app tier
aws ec2 create-launch-template \
    --launch-template-name $WEB_LAUNCH_TEMPLATE_NAME \
    --version-description "Version 1" \
    --launch-template-data file://web-launch-template-data.json

# Create Auto Scaling group app tier
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name $WEB_ASG_NAME \
    --launch-template LaunchTemplateName=$WEB_LAUNCH_TEMPLATE_NAME,Version=1 \
    --min-size 2 \
    --max-size 2 \
    --desired-capacity 2 \
    --target-group-arns $WEB_TARGET_GROUP_ARN \
    --vpc-zone-identifier "$web_SUB_ID1, $web_SUB_ID2"

URL=$(aws elbv2 describe-load-balancers \
 --names $WEB_ALB_NAME \
 --query LoadBalancers[0].DNSName \
 --output text )

 echo $URL


