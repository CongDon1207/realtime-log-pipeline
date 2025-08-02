#!/bin/bash

# MinIO Iceberg Warehouse Setup Script
# This script creates the necessary buckets and directories for Iceberg tables

set -e

echo "Setting up MinIO buckets for Iceberg warehouse..."

# MinIO connection settings
MINIO_ENDPOINT="http://localhost:9000"
MINIO_ACCESS_KEY="minioadmin"
MINIO_SECRET_KEY="minioadmin123"
MINIO_ALIAS="minio-local"

# Configure MinIO client
echo "Configuring MinIO client..."
mc alias set $MINIO_ALIAS $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

# Create the main Iceberg warehouse bucket
echo "Creating iceberg-warehouse bucket..."
mc mb $MINIO_ALIAS/iceberg-warehouse --ignore-existing

# Create directory structure for different table types
echo "Creating directory structure..."

# Raw logs directories
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/logs/nginx_access/
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/logs/nginx_error/
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/logs/application/

# Processed logs directories  
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/processed/nginx_access/
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/processed/nginx_error/
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/processed/application/

# Analytics directories
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/analytics/hourly_stats/
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/analytics/daily_stats/
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/analytics/weekly_stats/

# Test directories
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/test/

# Metadata directories
mc mkdir -p $MINIO_ALIAS/iceberg-warehouse/metadata/

echo "Bucket structure created successfully!"

# List the created structure
echo "Bucket contents:"
mc tree $MINIO_ALIAS/iceberg-warehouse/

# Set bucket policy for easier access (development only)
echo "Setting bucket policy for development access..."
cat > /tmp/iceberg-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::iceberg-warehouse/*",
        "arn:aws:s3:::iceberg-warehouse"
      ]
    }
  ]
}
EOF

mc anonymous set-json /tmp/iceberg-policy.json $MINIO_ALIAS/iceberg-warehouse
rm /tmp/iceberg-policy.json

echo "MinIO Iceberg warehouse setup completed!"
echo ""
echo "Bucket URL: $MINIO_ENDPOINT/minio/iceberg-warehouse/"
echo "Access Key: $MINIO_ACCESS_KEY"
echo "Secret Key: $MINIO_SECRET_KEY"
echo ""
echo "You can now use Trino to create Iceberg tables in this warehouse."
