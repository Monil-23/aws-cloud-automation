#!/bin/bash

# Find the auto scaling group
# https://docs.aws.amazon.com/cli/latest/reference/autoscaling/describe-auto-scaling-groups.html
echo "Retrieving autoscaling group name..."
ASGNAME=$(aws autoscaling describe-auto-scaling-groups --output=text --query='AutoScalingGroups[*].AutoScalingGroupName')
echo "*****************************************************************"
echo "Autoscaling group name: $ASGNAME"
echo "*****************************************************************"

# Update the auto scaling group to set min and desired capacity to zero
# https://docs.aws.amazon.com/cli/latest/reference/autoscaling/update-auto-scaling-group.html
echo "Updating $ASGNAME autoscaling group to set minimum and desired capacity to 0..."
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name $ASGNAME \
    --health-check-type ELB \
    --min-size 0 \
    --desired-capacity 0
echo "$ASGNAME autoscaling group was updated!"

# Collect EC2 instance IDS
# First Describe EC2 instances
# https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html
EC2IDS=$(aws ec2 describe-instances \
    --output=text \
    --query='Reservations[*].Instances[*].InstanceId' --filter Name=instance-state-name,Values=pending,running  )

# declaring an array to store the instance ids
declare -a IDSARRAY
IDSARRAY=( $EC2IDS )

# Add ec2 wait instances IDS terminated, so that it will wait till the instances are deleted
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/wait/instance-terminated.html
# Now Terminate all EC2 instances
echo "Waiting for instances..."
aws ec2 wait instance-terminated --instance-ids $EC2IDS
echo "Instances are terminated!"


# Delete listeners after deregistering target group
# describe load balancer, then describe listener, then delete listener and then delete target group
ELBARN=$(aws elbv2 describe-load-balancers --output=text --query='LoadBalancers[*].LoadBalancerArn')
#https://docs.aws.amazon.com/cli/latest/reference/elbv2/describe-listeners.html
LISTARN=$(aws elbv2 describe-listeners --load-balancer-arn $ELBARN --output=text --query='Listeners[*].ListenerArn' )
#https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elbv2/delete-listener.html
aws elbv2 delete-listener --listener-arn $LISTARN
#https://docs.aws.amazon.com/cli/latest/reference/elbv2/describe-target-groups.html
TGARN=$(aws elbv2 describe-target-groups --output=text --query='TargetGroups[*].TargetGroupArn')
echo "TGARN: $TGARN"
aws elbv2 delete-target-group --target-group-arn $TGARN



# First Query to get the ELB name using the --query and --filters
# https://docs.aws.amazon.com/cli/latest/reference/elbv2/describe-listeners.html
ELBARN=$(aws elbv2 describe-load-balancers --output=text --query='LoadBalancers[*].LoadBalancerArn')
echo "*****************************************************************"
echo "Printing ELBARN: $ELBARN"
echo "*****************************************************************"

#Delete loadbalancer
# https://docs.aws.amazon.com/cli/latest/reference/elbv2/delete-load-balancer.html
aws elbv2 delete-load-balancer --load-balancer-arn $ELBARN
aws elbv2 wait load-balancers-deleted --load-balancer-arns $ELBARN
echo "Load balancers deleted!"


# Delete the auto-scaling group
# https://docs.aws.amazon.com/cli/latest/reference/autoscaling/delete-auto-scaling-group.html

# add sleep command and try to see if it works.
# Wait for like 30 seconds until the ASG is no longer updating
echo "Pausing for 30 seconds to allow ASG to complete updates..."
sleep 30

echo "Now Deleting $ASGNAME autoscaling group..."
aws autoscaling delete-auto-scaling-group \
    --auto-scaling-group-name $ASGNAME
echo "$ASGNAME autoscaling group was deleted!"

# Find the launch configuration template
echo "Retrieving launch template name..."
LTNAME=$(aws ec2 describe-launch-templates --output=text --query='LaunchTemplates[*].LaunchTemplateId')
echo "*****************************************************************"
echo "Launch template name: $LTNAME"
echo "*****************************************************************"

# Delete the launch configuration template file
# https://docs.aws.amazon.com/cli/latest/reference/autoscaling/delete-launch-configuration.html
echo "Deleting $LTNAME launch template..."
aws ec2 delete-launch-template --launch-template-id $LTNAME
echo "$LTNAME launch template was deleted!"

# Delete the RDS instance
echo "Retrieving RDS instance identifier..." 
RDS_INSTANCE_ID=$(aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier]' --output text)
    echo "Deleting RDS instance: $RDS_INSTANCE_ID..."
    aws rds delete-db-instance --db-instance-identifier $RDS_INSTANCE_ID --skip-final-snapshot
    echo "Waiting for RDS instance $RDS_INSTANCE_ID to be deleted (this may take several minutes)..."
    aws rds wait db-instance-deleted --db-instance-identifier $RDS_INSTANCE_ID
    echo "RDS instance $RDS_INSTANCE_ID deleted."

#DB_SUBNET_GROUP=$(aws rds describe-db-subnet-groups --output=text --query='DBSubnetGroups[*].DBSubnetGroupName')

# Delete the DB Subnet Group
# DB_SUBNET_GROUP="ms-subnet-group"
#echo "Deleting DB Subnet Group: $DB_SUBNET_GROUP..."
#aws rds delete-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP
#echo "DB Subnet Group $DB_SUBNET_GROUP deleted."

#Delete S3 Bucket 
echo "Deleting raw S3 bucket ${21}..."
aws s3 rm s3://${21} --recursive #deleting the objects in the bucket
aws s3api delete-bucket --bucket ${21} --region us-east-2
echo "s3 bucket ${21} deleted!"

echo "Deleting finished S3 bucket ${22}..."
aws s3 rm s3://${22} --recursive
aws s3api delete-bucket --bucket ${22} --region us-east-2
echo "s3 bucket ${22} deleted!"


# Delete SNS Topic and Associated Subscriptions
echo "Deleting SNS Topic ${23}..."

# Get the Topic ARN for the specified topic
TOPIC_ARN=$(aws sns list-topics --output text --query "Topics[?contains(TopicArn, '${23}')].TopicArn" | grep "${23}")

if [ -n "$TOPIC_ARN" ]; then
    echo "Found SNS Topic: $TOPIC_ARN"

    # List all subscriptions for the topic
    echo "Retrieving subscriptions for SNS Topic ${23}..."
    SUBSCRIPTION_ARNS=$(aws sns list-subscriptions-by-topic --topic-arn $TOPIC_ARN --output text --query "Subscriptions[].SubscriptionArn")

    # Delete only valid subscriptions
    if [ -n "$SUBSCRIPTION_ARNS" ]; then
        echo "Deleting subscriptions for SNS Topic ${23}..."
        for SUBSCRIPTION_ARN in $SUBSCRIPTION_ARNS; do
            if [[ "$SUBSCRIPTION_ARN" != "PendingConfirmation" && -n "$SUBSCRIPTION_ARN" && "$SUBSCRIPTION_ARN" != "Deleted" ]]; then
                aws sns unsubscribe --subscription-arn $SUBSCRIPTION_ARN
                echo "Deleted subscription: $SUBSCRIPTION_ARN"
            else
                echo "Skipping invalid or orphaned subscription: $SUBSCRIPTION_ARN"
            fi
        done
    else
        echo "No subscriptions found for SNS Topic ${23}."
    fi

    # Delete the topic
    echo "Deleting SNS Topic ${23}..."
    aws sns delete-topic --topic-arn $TOPIC_ARN
    echo "SNS Topic ${23} deleted."
else
    echo "SNS Topic ${23} not found. Skipping deletion."
fi


echo "*********** Everything Cleared! ************"
