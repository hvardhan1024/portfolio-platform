#!/usr/bin/env python3

import os
import sys
import boto3
import psycopg2
from dotenv import load_dotenv
from botocore.exceptions import ClientError

def test_environment():
    """Test AWS RDS and S3 connectivity"""

    # Load environment variables
    load_dotenv()

    print("=" * 50)
    print("AWS SERVICES CONNECTIVITY TEST")
    print("=" * 50)

    # Check if all required environment variables are set
    required_vars = [
        'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_REGION', 'S3_BUCKET',
        'DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME'
    ]

    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)

    if missing_vars:
        print("ERROR: Missing environment variables:")
        for var in missing_vars:
            print(f"  - {var}")
        print("\nPlease check your .env file")
        return False

    print("Environment variables check: PASSED")
    print()

    # Test RDS Connection
    print("Testing RDS PostgreSQL connection...")
    try:
        db_host = os.getenv('DB_HOST')
        db_port = os.getenv('DB_PORT', '5432')
        db_user = os.getenv('DB_USER')
        db_password = os.getenv('DB_PASSWORD')
        db_name = os.getenv('DB_NAME')

        connection = psycopg2.connect(
            host=db_host,
            port=db_port,
            user=db_user,
            password=db_password,
            database=db_name
        )

        cursor = connection.cursor()
        cursor.execute("SELECT version();")
        db_version = cursor.fetchone()[0]
        cursor.close()
        connection.close()

        print(f"RDS Connection: SUCCESS")
        print(f"Database Version: {db_version}")
        print()

    except Exception as e:
        print(f"RDS Connection: FAILED")
        print(f"Error: {str(e)}")
        print()
        return False

    # Test S3 Connection
    print("Testing S3 bucket access...")
    try:
        aws_access_key_id = os.getenv('AWS_ACCESS_KEY_ID')
        aws_secret_access_key = os.getenv('AWS_SECRET_ACCESS_KEY')
        aws_region = os.getenv('AWS_REGION')
        s3_bucket = os.getenv('S3_BUCKET')

        s3_client = boto3.client(
            's3',
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
            region_name=aws_region
        )

        # Test bucket access
        response = s3_client.list_objects_v2(Bucket=s3_bucket, MaxKeys=1)

        print(f"S3 Connection: SUCCESS")
        print(f"Bucket: {s3_bucket}")
        print(f"Region: {aws_region}")
        print()

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'NoSuchBucket':
            print(f"S3 Connection: FAILED")
            print(f"Error: Bucket '{s3_bucket}' does not exist")
        else:
            print(f"S3 Connection: FAILED")
            print(f"Error: {e.response['Error']['Message']}")
        print()
        return False
    except Exception as e:
        print(f"S3 Connection: FAILED")
        print(f"Error: {str(e)}")
        print()
        return False

    # Test EC2 metadata (optional - only works on EC2)
    print("Testing EC2 metadata access...")
    try:
        import requests
        instance_id = requests.get("http://169.254.169.254/latest/meta-data/instance-id", timeout=2).text
        az = requests.get("http://169.254.169.254/latest/meta-data/placement/availability-zone", timeout=2).text

        print(f"EC2 Metadata: SUCCESS")
        print(f"Instance ID: {instance_id}")
        print(f"Availability Zone: {az}")
        print()

    except Exception as e:
        print(f"EC2 Metadata: Not available (not running on EC2 or network issue)")
        print()

    print("=" * 50)
    print("ALL TESTS COMPLETED SUCCESSFULLY!")
    print("Your Flask app should be able to connect to AWS services.")
    print("=" * 50)

    return True

def main():
    if not test_environment():
        print("Some tests failed. Please check your configuration.")
        sys.exit(1)
    else:
        print("All tests passed! You can now run your Flask app.")

if __name__ == "__main__":
    main()
