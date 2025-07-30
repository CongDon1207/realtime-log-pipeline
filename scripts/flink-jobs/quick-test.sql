-- =================================================================================
-- QUICK TEST - DataGen Connector Production Ready
-- =================================================================================

-- 1. CREATE SIMPLE LOG SOURCE
CREATE TABLE quick_test_logs (
    id BIGINT,
    ts TIMESTAMP(3),
    status_code INT,
    response_time INT,
    WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
    'connector' = 'datagen',
    'fields.id.kind' = 'sequence',
    'fields.id.start' = '1',
    'fields.id.end' = '10000',
    'fields.ts.kind' = 'sequence',
    'fields.ts.start' = '2025-07-30 15:50:00',
    'fields.ts.end' = '2025-07-30 16:30:00',
    'fields.status_code.min' = '200',
    'fields.status_code.max' = '500',
    'fields.response_time.min' = '10',
    'fields.response_time.max' = '2000',
    'rows-per-second' = '10'
);

-- 2. CREATE OUTPUT SINK
CREATE TABLE quick_test_output (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    total_requests BIGINT,
    avg_response_time DOUBLE,
    error_count BIGINT,
    error_rate DOUBLE
) WITH (
    'connector' = 'print',
    'print-identifier' = 'QUICK_TEST'
);

-- 3. RUN ANALYTICS
INSERT INTO quick_test_output
SELECT 
    TUMBLE_START(ts, INTERVAL '10' SECOND) as window_start,
    TUMBLE_END(ts, INTERVAL '10' SECOND) as window_end,
    COUNT(*) as total_requests,
    ROUND(AVG(CAST(response_time AS DOUBLE)), 2) as avg_response_time,
    SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) as error_count,
    ROUND(
        SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) as error_rate
FROM quick_test_logs
GROUP BY TUMBLE(ts, INTERVAL '10' SECOND);
