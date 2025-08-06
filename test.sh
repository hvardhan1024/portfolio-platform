#!/bin/bash

# test.sh: Script to test PostgreSQL RDS and S3 connectivity using .env configuration without awscli

# Exit on any error
set -e

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found in the current directory"
    exit 1
fi

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Validate required environment variables
required_vars=(
    "DATABASE_URL"
    "AWS_REGION"
    "S3_BUCKET"
)
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: Required environment variable $var is not set in .env"
        exit 1
    fi
done

# Extract database connection details from DATABASE_URL
# Expected format: postgresql://username:password@host:port/dbname
if [[ $DATABASE_URL =~ postgresql://([^:]+):([^@]+)@([^:]+):([0-9]+)/(.+) ]]; then
    DB_USER="${BASH_REMATCH[1]}"
    DB_PASSWORD="${BASH_REMATCH[2]}"
    DB_HOST="${BASH_REMATCH[3]}"
    DB_PORT="${BASH_REMATCH[4]}"
    DB_NAME="${BASH_REMATCH[5]}"
else
    echo "❌ Error: Invalid DATABASE_URL format in .env (expected postgresql://username:password@host:port/dbname)"
    exit 1
fi

# Function to test PostgreSQL RDS connectivity
test_rds() {
    echo "🔍 Testing PostgreSQL RDS connectivity to: $DB_HOST:$DB_PORT/$DB_NAME"

    # Check if psql is installed
    if ! command -v psql &> /dev/null; then
        echo "❌ Error: psql is not installed. Install it using 'sudo apt install postgresql-client' or equivalent."
        return 1
    }

    # Test database connection and execute a simple query
    export PGPASSWORD="$DB_PASSWORD"
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null; then
        echo "✅ PostgreSQL RDS connection successful and query executed"
    else
        echo "❌ Error: Failed to connect to PostgreSQL RDS or execute query. Check DATABASE_URL, network, or RDS security group."
        return 1
    fi
}

# Function to test S3 connectivity using curl
test_s3() {
    echo "🔍 Testing S3 connectivity to bucket: $S3_BUCKET in region: $AWS_REGION"

    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "❌ Error: curl is not installed. Install it using 'sudo apt install curl' or equivalent."
        return 1
    }

    # Check if openssl is installed
    if ! command -v openssl &> /dev/null; then
        echo "❌ Error: openssl is not installed. Install it using 'sudo apt install openssl' or equivalent."
        return 1
    }

    # Try a simple GET request to list bucket contents (assuming public read access)
    S3_URL="https://$S3_BUCKET.s3.$AWS_REGION.amazonaws.com/"
    if curl -s -f "$S3_URL" > /dev/null; then
        echo "✅ S3 bucket '$S3_BUCKET' is accessible via public read"
    else
        echo "⚠️ Warning: Public read access to '$S3_BUCKET' failed. Attempting signed request..."

        # Check for AWS credentials for signed request
        if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
            echo "❌ Error: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY required for signed S3 requests"
            return 1
        fi

        # Create a signed request for S3 GET (list objects)
        TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
        DATE=$(date -u +"%Y%m%d")
        SERVICE="s3"
        HTTP_METHOD="GET"
        CANONICAL_URI="/"
        CANONICAL_QUERY=""
        CANONICAL_HEADERS="host:$S3_BUCKET.s3.$AWS_REGION.amazonaws.com\n"
        SIGNED_HEADERS="host"
        PAYLOAD_HASH=$(echo -n "" | openssl dgst -sha256 | cut -d" " -f2)
        CANONICAL_REQUEST="$HTTP_METHOD\n$CANONICAL_URI\n$CANONICAL_QUERY\n$CANONICAL_HEADERS\n$SIGNED_HEADERS\n$PAYLOAD_HASH"
        CANONICAL_REQUEST_HASH=$(echo -en "$CANONICAL_REQUEST" | openssl dgst -sha256 | cut -d" " -f2)
        STRING_TO_SIGN="AWS4-HMAC-SHA256\n$TIMESTAMP\n$DATE/$AWS_REGION/$SERVICE/aws4_request\n$CANONICAL_REQUEST_HASH"
        SIGNING_KEY=$(echo -n "AWS4$AWS_SECRET_ACCESS_KEY" | xxd -p -c 256 | openssl dgst -sha256 -mac HMAC -macopt hexkey:$(echo -n "$DATE" | xxd -p -c 256) | cut -d" " -f2 | openssl dgst -sha256 -mac HMAC -macopt hexkey:$AWS_REGION | cut -d" " -f2 | openssl dgst -sha256 -mac HMAC -macopt hexkey:$SERVICE | cut -d" " -f2 | openssl dgst -sha256 -mac HMAC -macopt hexkey:aws4_request | cut -d" " -f2)
        SIGNATURE=$(echo -en "$STRING_TO_SIGN" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$SIGNING_KEY | cut -d" " -f2)
        AUTH_HEADER="AWS4-HMAC-SHA256 Credential=$AWS_ACCESS_KEY_ID/$DATE/$AWS_REGION/$SERVICE/aws4_request,SignedHeaders=$SIGNED_HEADERS,Signature=$SIGNATURE"

        # Test S3 access with signed request
        if curl -s -f -H "Host: $S3_BUCKET.s3.$AWS_REGION.amazonaws.com" -H "Authorization: $AUTH_HEADER" -H "x-amz-date: $TIMESTAMP" "$S3_URL" > /dev/null; then
            echo "✅ S3 bucket '$S3_BUCKET' is accessible via signed request"
        else
            echo "❌ Error: Failed to access S3 bucket '$S3_BUCKET'. Check AWS credentials or bucket permissions."
            return 1
        fi
    fi

    # Test S3 upload (requires signed PUT request)
    TEST_FILE="test-upload-$(date +%s).txt"
    echo "Test file for S3 upload" > "$TEST_FILE"
    TEST_KEY="test/$TEST_FILE"
    S3_UPLOAD_URL="https://$S3_BUCKET.s3.$AWS_REGION.amazonaws.com/$TEST_KEY"
    CONTENT_TYPE="text/plain"
    PAYLOAD_HASH=$(openssl dgst -sha256 "$TEST_FILE" | cut -d" " -f2)
    CANONICAL_HEADERS="host:$S3_BUCKET.s3.$AWS_REGION.amazonaws.com\nx-amz-acl:public-read\nx-amz-content-sha256:$PAYLOAD_HASH\n"
    SIGNED_HEADERS="host;x-amz-acl;x-amz-content-sha256"
    CANONICAL_REQUEST="PUT\n/$TEST_KEY\n\n$CANONICAL_HEADERS\n$SIGNED_HEADERS\n$PAYLOAD_HASH"
    CANONICAL_REQUEST_HASH=$(echo -en "$CANONICAL_REQUEST" | openssl dgst -sha256 | cut -d" " -f2)
    STRING_TO_SIGN="AWS4-HMAC-SHA256\n$TIMESTAMP\n$DATE/$AWS_REGION/$SERVICE/aws4_request\n$CANONICAL_REQUEST_HASH"
    SIGNATURE=$(echo -en "$STRING_TO_SIGN" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$SIGNING_KEY | cut -d" " -f2)
    AUTH_HEADER="AWS4-HMAC-SHA256 Credential=$AWS_ACCESS_KEY_ID/$DATE/$AWS_REGION/$SERVICE/aws4_request,SignedHeaders=$SIGNED_HEADERS,Signature=$SIGNATURE"

    if curl -s -f -X PUT -H "Host: $S3_BUCKET.s3.$AWS_REGION.amazonaws.com" -H "Authorization: $AUTH_HEADER" -H "x-amz-date: $TIMESTAMP" -H "x-amz-acl: public-read" -H "x-amz-content-sha256: $PAYLOAD_HASH" -H "Content-Type: $CONTENT_TYPE" --data-binary "@$TEST_FILE" "$S3_UPLOAD_URL" > /dev/null; then
        echo "✅ S3 upload test successful: $TEST_FILE uploaded to s3://$S3_BUCKET/test/"
        # Clean up test file
        curl -s -X DELETE -H "Host: $S3_BUCKET.s3.$AWS_REGION.amazonaws.com" -H "Authorization: $AUTH_HEADER" -H "x-amz-date: $TIMESTAMP" "$S3_UPLOAD_URL" > /dev/null
        rm "$TEST_FILE"
    else
        echo "❌ Error: S3 upload test failed. Check bucket write permissions or credentials."
        rm "$TEST_FILE"
        return 1
    fi
}

# Main execution
echo "=== Starting S3 and PostgreSQL RDS Tests ==="

# Run S3 test
test_s3
s3_status=$?

# Run RDS test
test_rds
rds_status=$?

# Summary
echo -e "\n=== Test Summary ==="
if [ $s3_status -eq 0 ]; then
    echo "S3: ✅ Passed"
else
    echo "S3: ❌ Failed"
fi
if [ $rds_status -eq 0 ]; then
    echo "RDS: ✅ Passed"
else
    echo "RDS: ❌ Failed"
fi

# Exit with non-zero status if any test failed
if [ $s3_status -ne 0 ] || [ $rds_status -ne 0 ]; then
    exit 1
fi

echo "✅ All tests passed successfully!"
