import boto3
import requests
from tqdm import tqdm

# Initialize Boto3 clients
sns_client = boto3.client('sns')
rds_client = boto3.client('rds')
s3_client = boto3.client('s3')
elb_client = boto3.client('elbv2')

# Variables for resource names
SNS_TOPIC_NAME = 'mshah132-topic'  
RDS_IDENTIFIER = 'ms-dbinstance'
EXPECTED_TAG = 'module-09'
S3_BUCKET_NAME = 'mshah-itmo-544-rds-raw-bucket'  
IMAGES_TO_CHECK = ['vegeta.jpg', 'knuth.jpg']
ELB_NAME = 'ms-elb'

# Total score out of 5
total_score = 0

# List of tasks for the grader
tasks = [
    "Checking SNS Topic",
    "Checking RDS Tag",
    "Checking S3 Buckets",
    "Checking S3 Images",
    "Checking ELB HTTP Response"
]

# Progress bar for tasks
for task in tqdm(tasks, desc="Grading Steps"):

    ##############################################################################
    # Test 1: Check for the existence of one SNS Topic
    ##############################################################################
    if task == "Checking SNS Topic":
        try:
            response = sns_client.list_topics()
            topics = response['Topics']
            found_topic = any(SNS_TOPIC_NAME in topic['TopicArn'] for topic in topics)
            if found_topic:
                print(f"SNS Topic '{SNS_TOPIC_NAME}' exists.")
                total_score += 1
            else:
                print(f"SNS Topic '{SNS_TOPIC_NAME}' not found.")
        except Exception as e:
            print(f"Error checking SNS topic: {str(e)}")

    ##############################################################################
    # Test 2: Check for the existence of the 'module-09' tag for the database instance
    ##############################################################################
    if task == "Checking RDS Tag":
        try:
            response = rds_client.list_tags_for_resource(
                ResourceName=f'arn:aws:rds:{boto3.Session().region_name}:{boto3.client("sts").get_caller_identity()["Account"]}:db:{RDS_IDENTIFIER}'
            )
            tags = {tag['Key']: tag['Value'] for tag in response['TagList']}
            if tags.get("name") == EXPECTED_TAG:
                print(f"RDS instance '{RDS_IDENTIFIER}' has tag '{EXPECTED_TAG}'.")
                total_score += 1
            else:
                print(f"RDS instance '{RDS_IDENTIFIER}' does not have the required tag '{EXPECTED_TAG}'.")
        except Exception as e:
            print(f"Error checking RDS tag: {str(e)}")

    ##############################################################################
    # Test 3: Check for the existence of two S3 buckets
    ##############################################################################
    if task == "Checking S3 Buckets":
        try:
            response = s3_client.list_buckets()
            buckets = response['Buckets']
            if len(buckets) >= 2:
                print("At least two S3 buckets exist.")
                total_score += 1
            else:
                print(f"Less than 2 S3 buckets found. Total: {len(buckets)}")
        except Exception as e:
            print(f"Error checking S3 buckets: {str(e)}")

    ##############################################################################
    # Test 4: Check for the existence of two images in the S3 bucket
    ##############################################################################
    if task == "Checking S3 Images":
        try:
            print(f"Checking for images in S3 bucket '{S3_BUCKET_NAME}'...")
            objects = s3_client.list_objects_v2(Bucket=S3_BUCKET_NAME)
            if 'Contents' in objects:
                found_images = [obj['Key'] for obj in objects['Contents'] if obj['Key'] in IMAGES_TO_CHECK]
                if len(found_images) == len(IMAGES_TO_CHECK):
                    print(f"Both images '{IMAGES_TO_CHECK}' exist in bucket '{S3_BUCKET_NAME}'.")
                    total_score += 1
                else:
                    print(f"Not all images found in bucket '{S3_BUCKET_NAME}'. Found: {found_images}")
            else:
                print(f"No objects found in bucket '{S3_BUCKET_NAME}'.")
        except Exception as e:
            print(f"Error checking S3 images: {str(e)}")

    ##############################################################################
    # Test 5: Check ELB HTTP Response
    ##############################################################################
    if task == "Checking ELB HTTP Response":
        try:
            elb_response = elb_client.describe_load_balancers(Names=[ELB_NAME])
            elb_dns = elb_response['LoadBalancers'][0]['DNSName']
            response = requests.get(f"http://{elb_dns}")
            if response.status_code == 200:
                print(f"ELB '{ELB_NAME}' returned HTTP 200.")
                total_score += 1
            else:
                print(f"ELB '{ELB_NAME}' did not return HTTP 200, status code: {response.status_code}")
        except Exception as e:
            print(f"Error checking ELB HTTP status: {str(e)}")

# Print final score
print("*" * 30)
print(f"Total score: {total_score}/5")
print("*" * 30)
