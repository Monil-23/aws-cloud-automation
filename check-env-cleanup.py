import boto3
from tqdm import tqdm

# Initialize Boto3 clients for SNS, EC2, ELBv2, RDS, and S3
sns_client = boto3.client('sns')
ec2_client = boto3.client('ec2')
elb_client = boto3.client('elbv2')
rds_client = boto3.client('rds')
s3_client = boto3.client('s3')

# Variables for resource names
SNS_TOPIC_NAME = 'mshah132-topic'  
EXPECTED_TAG = 'module-09'
RDS_IDENTIFIER = 'ms-dbinstance'

# Total score out of 5
total_score = 0

# List of tasks for the grader script
tasks = [
    "Checking SNS Topics",
    "Checking S3 Buckets",
    "Checking ELBs",
    "Checking EC2 Instances",
    "Checking RDS Instances"
]

# Initialize tqdm progress bar
for task in tqdm(tasks, desc="Grading Steps"):

    ##############################################################################
    # Test 1: Check for the existence of zero SNS Topics
    ##############################################################################
    if task == "Checking SNS Topics":
        try:
            response = sns_client.list_topics()
            topics = response['Topics']
            if not topics:
                print("All SNS topics have been deleted.")
                total_score += 1
            else:
                print(f"Found {len(topics)} SNS topics. They still exist.")
        except Exception as e:
            print(f"Error checking SNS topics: {str(e)}")

    ##############################################################################
    # Test 2: Check for the existence of zero S3 Buckets
    ##############################################################################
    if task == "Checking S3 Buckets":
        try:
            response = s3_client.list_buckets()
            buckets = response['Buckets']
            if not buckets:
                print("All S3 buckets have been deleted.")
                total_score += 1
            else:
                print(f"Found {len(buckets)} S3 buckets. They still exist.")
        except Exception as e:
            print(f"Error checking S3 buckets: {str(e)}")

    ##############################################################################
    # Test 3: Check for the existence of zero ELBs
    ##############################################################################
    if task == "Checking ELBs":
        try:
            response = elb_client.describe_load_balancers()
            if not response['LoadBalancers']:
                print("All ELBs have been deleted.")
                total_score += 1
            else:
                print(f"Found {len(response['LoadBalancers'])} ELBs. They still exist.")
        except elb_client.exceptions.ClientError:
            print("No ELBs found (as expected).")
            total_score += 1

    ##############################################################################
    # Test 4: Check for the existence of zero EC2 Instances
    ##############################################################################
    if task == "Checking EC2 Instances":
        try:
            response = ec2_client.describe_instances(
                Filters=[
                    {'Name': 'tag:Module', 'Values': [EXPECTED_TAG]},
                    {'Name': 'instance-state-name', 'Values': ['pending', 'running']}
                ]
            )
            instances = [instance for reservation in response['Reservations'] for instance in reservation['Instances']]
            if not instances:
                print("No EC2 instances found.")
                total_score += 1
            else:
                print(f"Found {len(instances)} EC2 instances. They still exist.")
        except Exception as e:
            print(f"Error checking EC2 instances: {str(e)}")

    ##############################################################################
    # Test 5: Check for the existence of zero RDS Instances
    ##############################################################################
    if task == "Checking RDS Instances":
        try:
            response = rds_client.describe_db_instances(DBInstanceIdentifier=RDS_IDENTIFIER)
            if not response['DBInstances']:
                print(f"RDS instance '{RDS_IDENTIFIER}' has been deleted.")
                total_score += 1
            else:
                print(f"RDS instance '{RDS_IDENTIFIER}' still exists.")
        except rds_client.exceptions.DBInstanceNotFoundFault:
            print(f"RDS instance '{RDS_IDENTIFIER}' not found.")
            total_score += 1

# Print the total score
print("*" * 30)
print(f"Total score: {total_score}/5")
print("*" * 30)
