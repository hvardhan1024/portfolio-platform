#!/usr/bin/env python3

"""
AWS Services Connectivity Test Script
Tests RDS PostgreSQL and S3 bucket connectivity for Flask app deployment
"""

import os
import sys
import psycopg2
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from dotenv import load_dotenv
from urllib.parse import urlparse

def load_environment():
    """Load environment variables from .env file"""
    if not os.path.exists('.env'):
        print("❌ .env file not found. Please create it with your AWS and database credentials.")
        print("Required variables: DATABASE_URL, AWS_REGION, S3_BUCKET")
        print("Optional: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY (if not using IAM roles)")
        return False

    load_dotenv()
    return True

def test_rds_connection():
    """Test PostgreSQL RDS connection"""
    print("Testing RDS PostgreSQL connection...")

    database_url = os.getenv('DATABASE_URL')
    if not database_url:
        print("❌ DATABASE_URL not found in environment variables")
        return False

    try:
        # Parse DATABASE_URL
        parsed = urlparse(database_url)

        # Connect to PostgreSQL
        connection = psycopg2.connect(
            host=parsed.hostname,
            port=parsed.port or 5432,
            database=parsed.path[1:] if parsed.path else 'postgres',
            user=parsed.username,
            password=parsed.password
        )

        # Test query
        cursor = connection.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]

        cursor.close()
        connection.close()

        print(f"✅ RDS PostgreSQL connection successful")
        print(f"   Database version: {version.split(',')[0]}")
        return True

    except psycopg2.Error as e:
        print(f"❌ RDS PostgreSQL connection failed: {e}")
        return False
    except Exception as e:
        print(f"❌ RDS connection error: {e}")
        return False

def test_s3_access():
    """Test S3 bucket access"""
    print("Testing S3 bucket access...")

    aws_region = os.getenv('AWS_REGION')
    s3_bucket = os.getenv('S3_BUCKET')

    if not aws_region:
        print("❌ AWS_REGION not found in environment variables")
        return False

    if not s3_bucket:
        print("❌ S3_BUCKET not found in environment variables")
        return False

    try:
        # Initialize S3 client
        aws_access_key_id = os.getenv('AWS_ACCESS_KEY_ID')
        aws_secret_access_key = os.getenv('AWS_SECRET_ACCESS_KEY')

        if aws_access_key_id and aws_secret_access_key:
            s3_client = boto3.client(
                's3',
                aws_access_key_id=aws_access_key_id,
                aws_secret_access_key=aws_secret_access_key,
                region_name=aws_region
            )
            print("   Using explicit AWS credentials")
        else:
            s3_client = boto3.client('s3', region_name=aws_region)
            print("   Using IAM role credentials")

        # Test bucket access
        response = s3_client.list_objects_v2(Bucket=s3_bucket, MaxKeys=1)

        print(f"✅ S3 bucket '{s3_bucket}' is accessible")
        print(f"   Region: {aws_region}")

        # Check bucket permissions for upload
        try:
            s3_client.put_object(
                Bucket=s3_bucket,
                Key='test-connectivity.txt',
                Body=b'Test file for connectivity check',
                ACL='public-read'
            )
            s3_client.delete_object(Bucket=s3_bucket, Key='test-connectivity.txt')
            print("   Upload/delete permissions: ✅")
        except ClientError as e:
            if e.response['Error']['Code'] == 'AccessDenied':
                print("   Upload permissions: ❌ (Access Denied)")
            else:
                print(f"   Upload test error: {e.response['Error']['Message']}")

        return True

    except NoCredentialsError:
        print("❌ AWS credentials not found. Configure AWS credentials or IAM role.")
        return False
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        print(f"❌ S3 access failed ({error_code}): {error_msg}")
        return False
    except Exception as e:
        print(f"❌ S3 access error: {e}")
        return False

def test_ec2_metadata():
    """Test EC2 instance metadata (optional)"""
    print("Testing EC2 instance metadata...")

    try:
        import requests

        # Test metadata service
        instance_id = requests.get(
            "http://169.254.169.254/latest/meta-data/instance-id",
            timeout=3
        ).text

        az = requests.get(
            "http://169.254.169.254/latest/meta-data/placement/availability-zone",
            timeout=3
        ).text

        print(f"✅ Running on EC2 instance: {instance_id}")
        print(f"   Availability Zone: {az}")
        return True

    except Exception as e:
        print(f"⚠️  EC2 metadata not accessible (not running on EC2 or metadata disabled)")
        return False

def main():
    """Main test function"""
    print("=" * 60)
    print("AWS Services Connectivity Test")
    print("=" * 60)

    # Load environment variables
    if not load_environment():
        sys.exit(1)

    results = []

    # Test RDS
    results.append(test_rds_connection())
    print()

    # Test S3
    results.append(test_s3_access())
    print()

    # Test EC2 metadata (optional)
    test_ec2_metadata()
    print()

    # Summary
    print("=" * 60)
    print("Test Summary:")
    print(f"RDS PostgreSQL: {'✅ PASS' if results[0] else '❌ FAIL'}")
    print(f"S3 Access: {'✅ PASS' if results[1] else '❌ FAIL'}")
    print("=" * 60)

    if all(results):
        print("🎉 All critical tests passed! Your Flask app should work properly.")
        sys.exit(0)
    else:
        print("❌ Some tests failed. Please check your configuration.")
        sys.exit(1)

if __name__ == "__main__":
    main()
