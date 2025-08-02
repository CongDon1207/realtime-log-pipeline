-- Trino + Iceberg: Setup and Testing Scripts
-- Run these scripts to set up the Iceberg environment and test functionality

-- =========================
-- ENVIRONMENT SETUP
-- =========================

-- Check Trino cluster info
SELECT * FROM system.runtime.nodes;

-- Show all available catalogs
SHOW CATALOGS;

-- Test memory catalog
USE memory.default;
CREATE TABLE test_table AS SELECT 1 as id, 'test' as name;
SELECT * FROM test_table;
DROP TABLE test_table;

-- =========================
-- ICEBERG CATALOG SETUP
-- =========================

-- Switch to Iceberg catalog
USE iceberg_files;

-- Create schemas for different data types
CREATE SCHEMA IF NOT EXISTS raw_logs;
CREATE SCHEMA IF NOT EXISTS processed_logs;
CREATE SCHEMA IF NOT EXISTS analytics;

-- =========================
-- BASIC ICEBERG TESTING
-- =========================

-- Create a simple test table
USE iceberg_files.raw_logs;

CREATE TABLE test_iceberg (
    id bigint,
    name varchar,
    created_at timestamp(6),
    partition_date date
) 
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['partition_date'],
    location = 's3a://iceberg-warehouse/test/test_iceberg/'
);

-- Insert test data
INSERT INTO test_iceberg VALUES
(1, 'Test Record 1', CURRENT_TIMESTAMP, CURRENT_DATE),
(2, 'Test Record 2', CURRENT_TIMESTAMP, CURRENT_DATE),
(3, 'Test Record 3', CURRENT_TIMESTAMP, CURRENT_DATE - INTERVAL '1' DAY);

-- Query test data
SELECT * FROM test_iceberg ORDER BY id;

-- Show table metadata
DESCRIBE test_iceberg;

-- Show table history
SELECT * FROM "test_iceberg$history";

-- Show table snapshots
SELECT * FROM "test_iceberg$snapshots";

-- Show table files
SELECT * FROM "test_iceberg$files";

-- =========================
-- NGINX LOG TABLE SETUP
-- =========================

-- Create the main nginx access logs table
USE iceberg_files.processed_logs;

CREATE TABLE nginx_access_logs (
    -- Basic request info
    remote_addr varchar,
    remote_user varchar,
    time_local timestamp(6),
    request varchar,
    status integer,
    body_bytes_sent bigint,
    
    -- HTTP headers
    http_referer varchar,
    http_user_agent varchar,
    http_x_forwarded_for varchar,
    
    -- Performance metrics
    request_time double,
    upstream_response_time double,
    
    -- Derived fields
    method varchar,
    uri varchar,
    protocol varchar,
    log_timestamp timestamp(6),
    
    -- Partitioning
    processing_date date,
    processing_hour integer
) 
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['processing_date', 'processing_hour'],
    location = 's3a://iceberg-warehouse/logs/nginx_access/',
    sorted_by = ARRAY['time_local']
);

-- =========================
-- ERROR LOGS TABLE
-- =========================

CREATE TABLE nginx_error_logs (
    log_time timestamp(6),
    log_level varchar,
    pid integer,
    tid varchar,
    client_ip varchar,
    message varchar,
    log_timestamp timestamp(6),
    processing_date date
) 
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['processing_date', 'log_level'],
    location = 's3a://iceberg-warehouse/logs/nginx_error/'
);

-- =========================
-- AGGREGATED TABLES FOR ANALYTICS
-- =========================

USE iceberg_files.analytics;

-- Hourly aggregations
CREATE TABLE hourly_stats (
    hour_bucket timestamp(6),
    total_requests bigint,
    unique_ips bigint,
    total_bytes bigint,
    avg_response_time double,
    p95_response_time double,
    error_rate double,
    status_2xx bigint,
    status_3xx bigint,
    status_4xx bigint,
    status_5xx bigint,
    processing_date date
) 
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['processing_date'],
    location = 's3a://iceberg-warehouse/analytics/hourly_stats/'
);

-- Daily aggregations
CREATE TABLE daily_stats (
    date_bucket date,
    total_requests bigint,
    unique_ips bigint,
    total_bytes bigint,
    avg_response_time double,
    p95_response_time double,
    error_rate double,
    top_endpoints array(row(endpoint varchar, requests bigint)),
    top_user_agents array(row(user_agent varchar, requests bigint))
) 
WITH (
    format = 'PARQUET',
    location = 's3a://iceberg-warehouse/analytics/daily_stats/'
);

-- =========================
-- DATA VALIDATION QUERIES
-- =========================

-- Check if tables exist and are accessible
SELECT 
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema IN ('raw_logs', 'processed_logs', 'analytics')
ORDER BY table_schema, table_name;

-- Check table properties
SELECT 
    table_name,
    property_name,
    property_value
FROM information_schema.table_properties 
WHERE table_schema = 'processed_logs'
ORDER BY table_name, property_name;

-- =========================
-- SAMPLE DATA INSERTION
-- =========================

-- Insert sample nginx access log data
USE iceberg_files.processed_logs;

INSERT INTO nginx_access_logs VALUES
(
    '192.168.1.100',
    '-',
    TIMESTAMP '2024-01-15 10:30:00.000000',
    'GET /api/health HTTP/1.1',
    200,
    1024,
    '-',
    'curl/7.68.0',
    NULL,
    0.005,
    0.004,
    'GET',
    '/api/health',
    'HTTP/1.1',
    TIMESTAMP '2024-01-15 10:30:00.000000',
    DATE '2024-01-15',
    10
),
(
    '192.168.1.101',
    '-',
    TIMESTAMP '2024-01-15 10:31:00.000000',
    'POST /api/data HTTP/1.1',
    201,
    2048,
    'https://example.com',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    NULL,
    0.125,
    0.120,
    'POST',
    '/api/data',
    'HTTP/1.1',
    TIMESTAMP '2024-01-15 10:31:00.000000',
    DATE '2024-01-15',
    10
),
(
    '192.168.1.102',
    '-',
    TIMESTAMP '2024-01-15 10:32:00.000000',
    'GET /api/nonexistent HTTP/1.1',
    404,
    512,
    '-',
    'Python-requests/2.25.1',
    NULL,
    0.001,
    NULL,
    'GET',
    '/api/nonexistent',
    'HTTP/1.1',
    TIMESTAMP '2024-01-15 10:32:00.000000',
    DATE '2024-01-15',
    10
);

-- Verify the data was inserted
SELECT 
    remote_addr,
    method,
    uri,
    status,
    request_time,
    processing_date,
    processing_hour
FROM nginx_access_logs 
ORDER BY time_local;

-- =========================
-- PERFORMANCE TESTING
-- =========================

-- Test partition pruning
SELECT COUNT(*) 
FROM nginx_access_logs 
WHERE processing_date = DATE '2024-01-15';

-- Test projection pushdown
SELECT remote_addr, status, request_time 
FROM nginx_access_logs 
WHERE processing_date = DATE '2024-01-15'
    AND status >= 400;

-- =========================
-- CLEANUP SCRIPTS
-- =========================

-- Drop test table when done
-- DROP TABLE IF EXISTS iceberg_files.raw_logs.test_iceberg;

-- Show all tables for verification
SELECT 
    table_schema,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_catalog = 'iceberg_files'
ORDER BY table_schema, table_name;
