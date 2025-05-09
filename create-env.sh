#!/bin/bash

# Disable AWS CLI pager for long outputs
export AWS_PAGER=""

# Create ELB - 3 EC2 instances attached

# ${1} image-id 
# ${2} instance-type 
# ${3} key-name
# ${4} security-group-ids
# ${5} count
# ${6} user-data file name
# ${7} availability-zone
# ${8} elb name
# ${9} target group name
# ${10} us-east-2a
# ${11} us-east-2b
# ${12} us-east-2c
# ${13} tag value
# ${14} asg name
# ${15} launch template name
# ${16} asg min
# ${17} asg max
# ${18} asg desired
# ${19} RDS Database Instance Identifier (no punctuation) --db-instance-identifier
# ${20} IAM Instance Profile Name
# ${21} S3 Bucket Raw
# ${22} S3 Bucket Finished
# ${23} SNS Topic

echo "Finding and storing the subnet IDs for defined in arguments.txt Availability Zone 1 and 2..."
SUBNET2A=$(aws ec2 describe-subnets --output=text --query='Subnets[*].SubnetId' --filter "Name=availability-zone,Values=${10}")
SUBNET2B=$(aws ec2 describe-subnets --output=text --query='Subnets[*].SubnetId' --filter "Name=availability-zone,Values=${11}")
SUBNET2C=$(aws ec2 describe-subnets --output=text --query='Subnets[*].SubnetId' --filter "Name=availability-zone,Values=${12}")
echo $SUBNET2A
echo $SUBNET2B
echo $SUBNET2C

# Create launch template
# https://docs.aws.amazon.com/cli/latest/reference/ec2/create-launch-template.html
aws ec2 create-launch-template \
    --launch-template-name ${15} \
    --version-description version1 \
    --launch-template-data file://config.json

# https://docs.aws.amazon.com/cli/latest/reference/elbv2/create-load-balancer.html
aws elbv2 create-load-balancer \
    --name ${8} \
    --subnets $SUBNET2A $SUBNET2B $SUBNET2C \
    --security-groups ${4} \
    --tags Key='name',Value=${13}  
    
# https://docs.aws.amazon.com/cli/latest/reference/elbv2/describe-listeners.html
ELBARN=$(aws elbv2 describe-load-balancers --output=text --query='LoadBalancers[*].LoadBalancerArn')
echo "*****************************************************************"
echo "Printing ELBARN: $ELBARN"
echo "*****************************************************************"

# add elv2 wait running reference
# https://docs.aws.amazon.com/cli/latest/reference/elbv2/wait/
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elbv2/wait/load-balancer-available.html
echo "Waiting for ELB to become available..."
aws elbv2 wait load-balancer-available --load-balancer-arns $ELBARN
echo "ELB is available..."
  
# Find the VPC
# Note: the way I did it, I added a new argument on the arguments.txt file for VPC ID
#https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-vpcs.html
MYVPCID=$(aws ec2 describe-vpcs --output=text --query='Vpcs[*].VpcId' )

# https://docs.aws.amazon.com/cli/latest/reference/elbv2/create-target-group.html
aws elbv2 create-target-group \
    --name ${9} \
    --protocol HTTP \
    --port 80 \
    --target-type instance \
    --vpc-id $MYVPCID
 
#https://docs.aws.amazon.com/cli/latest/reference/elbv2/describe-target-groups.html
TGARN=$(aws elbv2 describe-target-groups --output=text --query='TargetGroups[*].TargetGroupArn' --names ${9})
echo "Target group ARN: $TGARN"

#Creating listener
#https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elbv2/create-listener.html
echo "Creating elbv2 listener..."
aws elbv2 create-listener --load-balancer-arn $ELBARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TGARN
echo "Created elbv2 listener..."

# Create auto-scalng groups
# https://docs.aws.amazon.com/cli/latest/reference/autoscaling/create-auto-scaling-group.html
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name ${14} \
    --launch-template LaunchTemplateName=${15} \
    --target-group-arns $TGARN \
    --health-check-type ELB \
    --health-check-grace-period 120 \
    --min-size ${16} \
    --max-size ${17} \
    --desired-capacity ${18}

echo "Retrieving Instance ID"
EC2IDS=$(aws ec2 describe-instances \
    --output=text \
    --query='Reservations[*].Instances[*].InstanceId' --filter Name=instance-state-name,Values=pending,running)

echo "Waiting for instances..."
#https://docs.aws.amazon.com/cli/latest/reference/ec2/wait/instance-running.html
aws ec2 wait instance-running --instance-ids $EC2IDS
echo "Instances are up!"

# GO to the elbv2 describe-load-balancers
# find DNS URL in the return object - and print the URL to the screen

DNSNAME=$(aws elbv2 describe-load-balancers --output=text --query='LoadBalancers[*].DNSName')
DNSNAME="http://$DNSNAME"
echo "DNS URL: $DNSNAME"



#Describe Security Group
SG=$(aws ec2 describe-security-groups --query "SecurityGroups[*].GroupId" --filters "Name=tag:Name,Values=module-06")

# Create S3 buckets
echo "Creating S3 buckets..."
aws s3api create-bucket --bucket ${21} --region us-east-2 --create-bucket-configuration LocationConstraint=us-east-2
aws s3api create-bucket --bucket ${22} --region us-east-2 --create-bucket-configuration LocationConstraint=us-east-2
echo "S3 buckets ${21} and ${22} created."

# Create RDS instance from snapshot
echo "Creating RDS instance from snapshot..."
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier ${19} \
    --db-snapshot-identifier module07snapshot \
    --db-instance-class db.t3.micro \
    --vpc-security-group-ids $SG \
    --tags Key='name',Value=${13}
echo "RDS instance creation from snapshot initiated."

# Wait for RDS instance to become available
echo "Waiting for RDS instance ${19} to become available..."
aws rds wait db-instance-available --db-instance-identifier ${19}
echo "RDS instance ${19} is now available."

# Modify RDS instance to generate a new password
aws rds modify-db-instance \
    --db-instance-identifier ${19} \
    --manage-master-user-password

# added code for s3 bucket policy
aws s3api put-public-access-block --bucket ${21} --public-access-block-configuration "BlockPublicPolicy=false"
aws s3api put-bucket-policy --bucket ${21} --policy file://raw-bucket-policy.json

 # added code to create sns-topic
 # https://docs.aws.amazon.com/cli/latest/reference/sns/create-topic.html#
echo "Creating SNS Topic ${23}..."
aws sns create-topic \
    --name ${23}
echo "SNS Topic ${23} created."


echo "*********** Done ************"
