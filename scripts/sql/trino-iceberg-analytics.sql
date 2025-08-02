-- Trino + Iceberg: Log Analytics SQL Queries
-- These queries demonstrate how to use Trino to analyze log data stored in Iceberg tables

-- =========================
-- BASIC TABLE OPERATIONS
-- =========================

-- Show available catalogs
SHOW CATALOGS;

-- Use the Iceberg catalog
USE iceberg_files;

-- Show available schemas
SHOW SCHEMAS;

-- Create a schema for log analytics
CREATE SCHEMA IF NOT EXISTS logs_analytics;
USE logs_analytics;

-- =========================
-- NGINX ACCESS LOG ANALYSIS
-- =========================

-- Create Iceberg table for nginx access logs
CREATE TABLE nginx_access_logs (
    remote_addr varchar,
    remote_user varchar,
    time_local timestamp(6),
    request varchar,
    status integer,
    body_bytes_sent bigint,
    http_referer varchar,
    http_user_agent varchar,
    http_x_forwarded_for varchar,
    request_time double,
    upstream_response_time double,
    log_timestamp timestamp(6),
    processing_date date
) 
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['processing_date'],
    location = 's3a://iceberg-warehouse/logs/nginx_access/'
);

-- =========================
-- SAMPLE ANALYTICS QUERIES
-- =========================

-- Top 10 IP addresses by request count
SELECT 
    remote_addr,
    COUNT(*) as request_count,
    COUNT(DISTINCT DATE(time_local)) as active_days
FROM nginx_access_logs 
WHERE processing_date >= CURRENT_DATE - INTERVAL '7' DAY
GROUP BY remote_addr 
ORDER BY request_count DESC 
LIMIT 10;

-- HTTP status code distribution
SELECT 
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM nginx_access_logs 
WHERE processing_date >= CURRENT_DATE - INTERVAL '1' DAY
GROUP BY status 
ORDER BY count DESC;

-- Hourly request pattern
SELECT 
    HOUR(time_local) as hour,
    COUNT(*) as requests,
    AVG(request_time) as avg_response_time,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY request_time) as p95_response_time
FROM nginx_access_logs 
WHERE processing_date = CURRENT_DATE
GROUP BY HOUR(time_local) 
ORDER BY hour;

-- Top requested endpoints
SELECT 
    REGEXP_EXTRACT(request, '^[A-Z]+ ([^ ]+)', 1) as endpoint,
    COUNT(*) as requests,
    AVG(request_time) as avg_response_time
FROM nginx_access_logs 
WHERE processing_date >= CURRENT_DATE - INTERVAL '1' DAY
GROUP BY REGEXP_EXTRACT(request, '^[A-Z]+ ([^ ]+)', 1)
ORDER BY requests DESC 
LIMIT 20;

-- =========================
-- TIME SERIES ANALYSIS
-- =========================

-- Request volume over time (5-minute intervals)
SELECT 
    DATE_TRUNC('minute', time_local) - 
    INTERVAL (MINUTE(time_local) % 5) MINUTE as time_bucket,
    COUNT(*) as requests,
    COUNT(DISTINCT remote_addr) as unique_ips,
    SUM(body_bytes_sent) as total_bytes
FROM nginx_access_logs 
WHERE time_local >= CURRENT_TIMESTAMP - INTERVAL '1' HOUR
GROUP BY DATE_TRUNC('minute', time_local) - 
         INTERVAL (MINUTE(time_local) % 5) MINUTE
ORDER BY time_bucket;

-- =========================
-- ERROR ANALYSIS
-- =========================

-- Create view for error analysis
CREATE OR REPLACE VIEW error_analysis AS
SELECT 
    processing_date,
    remote_addr,
    request,
    status,
    time_local,
    request_time,
    CASE 
        WHEN status >= 500 THEN 'Server Error'
        WHEN status >= 400 THEN 'Client Error'
        WHEN status >= 300 THEN 'Redirect'
        WHEN status >= 200 THEN 'Success'
        ELSE 'Other'
    END as status_category
FROM nginx_access_logs;

-- Error rate by hour
SELECT 
    HOUR(time_local) as hour,
    COUNT(*) as total_requests,
    SUM(CASE WHEN status >= 400 THEN 1 ELSE 0 END) as error_requests,
    ROUND(
        SUM(CASE WHEN status >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) as error_rate_percent
FROM error_analysis 
WHERE processing_date >= CURRENT_DATE - INTERVAL '1' DAY
GROUP BY HOUR(time_local) 
ORDER BY hour;

-- =========================
-- PERFORMANCE ANALYSIS
-- =========================

-- Slow requests analysis
SELECT 
    remote_addr,
    request,
    request_time,
    time_local,
    status
FROM nginx_access_logs 
WHERE request_time > 5.0 
    AND processing_date >= CURRENT_DATE - INTERVAL '1' DAY
ORDER BY request_time DESC 
LIMIT 50;

-- Performance percentiles by endpoint
WITH endpoint_stats AS (
    SELECT 
        REGEXP_EXTRACT(request, '^[A-Z]+ ([^ ]+)', 1) as endpoint,
        request_time
    FROM nginx_access_logs 
    WHERE processing_date >= CURRENT_DATE - INTERVAL '1' DAY
        AND request_time IS NOT NULL
)
SELECT 
    endpoint,
    COUNT(*) as requests,
    ROUND(AVG(request_time), 3) as avg_time,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY request_time), 3) as p50,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY request_time), 3) as p95,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY request_time), 3) as p99,
    ROUND(MAX(request_time), 3) as max_time
FROM endpoint_stats 
GROUP BY endpoint 
HAVING COUNT(*) >= 10
ORDER BY p95 DESC 
LIMIT 20;

-- =========================
-- ICEBERG TABLE MAINTENANCE
-- =========================

-- Show table history
SELECT * FROM "iceberg_files"."logs_analytics"."nginx_access_logs$history";

-- Show table snapshots
SELECT * FROM "iceberg_files"."logs_analytics"."nginx_access_logs$snapshots";

-- Show table files
SELECT * FROM "iceberg_files"."logs_analytics"."nginx_access_logs$files";

-- Show table partitions
SELECT * FROM "iceberg_files"."logs_analytics"."nginx_access_logs$partitions";

-- Optimize table (compact small files)
ALTER TABLE nginx_access_logs EXECUTE optimize;

-- Expire old snapshots (keep last 10)
ALTER TABLE nginx_access_logs EXECUTE expire_snapshots(retention_threshold => '7d');

-- =========================
-- ADVANCED ANALYTICS
-- =========================

-- User session analysis (based on IP and User Agent)
WITH user_sessions AS (
    SELECT 
        remote_addr,
        http_user_agent,
        MIN(time_local) as session_start,
        MAX(time_local) as session_end,
        COUNT(*) as page_views,
        SUM(body_bytes_sent) as total_bytes
    FROM nginx_access_logs 
    WHERE processing_date >= CURRENT_DATE - INTERVAL '1' DAY
    GROUP BY remote_addr, http_user_agent
)
SELECT 
    ROUND(AVG(page_views), 2) as avg_page_views,
    ROUND(AVG(EXTRACT(EPOCH FROM (session_end - session_start))), 2) as avg_session_duration_seconds,
    ROUND(AVG(total_bytes), 2) as avg_bytes_per_session,
    COUNT(*) as total_sessions
FROM user_sessions
WHERE EXTRACT(EPOCH FROM (session_end - session_start)) > 0;

-- Geographic analysis (if available from logs)
SELECT 
    CASE 
        WHEN http_x_forwarded_for IS NOT NULL THEN 
            SPLIT_PART(http_x_forwarded_for, ',', 1)
        ELSE remote_addr 
    END as client_ip,
    COUNT(*) as requests,
    COUNT(DISTINCT DATE(time_local)) as active_days
FROM nginx_access_logs 
WHERE processing_date >= CURRENT_DATE - INTERVAL '7' DAY
GROUP BY CASE 
    WHEN http_x_forwarded_for IS NOT NULL THEN 
        SPLIT_PART(http_x_forwarded_for, ',', 1)
    ELSE remote_addr 
END
ORDER BY requests DESC 
LIMIT 100;
