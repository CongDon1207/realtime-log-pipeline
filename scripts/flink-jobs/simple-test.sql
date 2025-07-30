-- =================================================================================
-- QUICK TEST - DataGen Connector Compatible Version
-- =================================================================================

-- 1. CREATE SIMPLE LOG SOURCE
CREATE TABLE quick_test_logs (
    id BIGINT,
    log_time BIGINT,
    status_code INT,
    response_time INT
) WITH (
    'connector' = 'datagen',
    'fields.id.kind' = 'sequence',
    'fields.id.start' = '1',
    'fields.id.end' = '10000',
    'fields.log_time.kind' = 'random',
    'fields.log_time.min' = '1722345000000',
    'fields.log_time.max' = '1722348600000',
    'fields.status_code.min' = '200',
    'fields.status_code.max' = '500',
    'fields.response_time.min' = '10',
    'fields.response_time.max' = '2000',
    'rows-per-second' = '5'
);

-- 2. CREATE OUTPUT SINK
CREATE TABLE quick_test_output (
    total_requests BIGINT,
    avg_response_time DOUBLE,
    error_count BIGINT,
    error_rate DOUBLE
) WITH (
    'connector' = 'print',
    'print-identifier' = 'QUICK_TEST'
);

-- 3. RUN SIMPLE ANALYTICS
INSERT INTO quick_test_output
SELECT 
    COUNT(*) as total_requests,
    ROUND(AVG(CAST(response_time AS DOUBLE)), 2) as avg_response_time,
    SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) as error_count,
    ROUND(
        SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) as error_rate
FROM quick_test_logs;
