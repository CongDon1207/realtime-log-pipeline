-- =================================================================================
-- REAL-TIME LOG ANALYTICS PIPELINE - PRODUCTION VERSION
-- Using DataGen Connector for realistic log data streaming
-- =================================================================================

-- 1. CREATE SOURCE: Simulated Nginx Access Logs
CREATE TABLE access_logs (
    ts TIMESTAMP(3),
    client_ip STRING,
    request_method STRING,
    request_uri STRING,
    http_status INT,
    response_size BIGINT,
    user_agent STRING,
    referer STRING,
    processing_time_ms INT,
    WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
    'connector' = 'datagen',
    'fields.ts.kind' = 'sequence',
    'fields.ts.start' = '2025-07-30 00:00:00',
    'fields.ts.end' = '2025-07-30 23:59:59',
    
    'fields.client_ip.kind' = 'random',
    'fields.client_ip.min' = '192.168.1.1',
    'fields.client_ip.max' = '192.168.1.255',
    
    'fields.request_method.length' = '1',
    'fields.request_method.kind' = 'sequence',
    
    'fields.request_uri.kind' = 'sequence',
    'fields.request_uri.length' = '20',
    
    'fields.http_status.min' = '200',
    'fields.http_status.max' = '500',
    
    'fields.response_size.min' = '100',
    'fields.response_size.max' = '50000',
    
    'fields.user_agent.length' = '50',
    'fields.processing_time_ms.min' = '10',
    'fields.processing_time_ms.max' = '2000',
    
    'rows-per-second' = '100'
);

-- =================================================================================
-- 2. REAL-TIME ANALYTICS VIEWS
-- =================================================================================

-- 2.1 Traffic Overview (1-minute windows)
CREATE VIEW traffic_overview AS
SELECT 
    TUMBLE_START(ts, INTERVAL '1' MINUTE) as window_start,
    TUMBLE_END(ts, INTERVAL '1' MINUTE) as window_end,
    COUNT(*) as total_requests,
    COUNT(DISTINCT client_ip) as unique_visitors,
    ROUND(AVG(CAST(response_size AS DOUBLE)), 2) as avg_response_size,
    ROUND(AVG(CAST(processing_time_ms AS DOUBLE)), 2) as avg_processing_time,
    SUM(CASE WHEN http_status >= 400 THEN 1 ELSE 0 END) as error_count,
    ROUND(
        SUM(CASE WHEN http_status >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) as error_rate_percent
FROM access_logs
GROUP BY TUMBLE(ts, INTERVAL '1' MINUTE);

-- 2.2 Top Pages by Traffic (5-minute windows)
CREATE VIEW top_pages AS
SELECT 
    TUMBLE_START(ts, INTERVAL '5' MINUTE) as window_start,
    TUMBLE_END(ts, INTERVAL '5' MINUTE) as window_end,
    request_uri,
    COUNT(*) as request_count,
    ROUND(AVG(CAST(processing_time_ms AS DOUBLE)), 2) as avg_processing_time,
    ROUND(
        SUM(CASE WHEN http_status >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) as error_rate_percent
FROM access_logs
GROUP BY 
    TUMBLE(ts, INTERVAL '5' MINUTE),
    request_uri
HAVING COUNT(*) >= 10;  -- Only show pages with significant traffic

-- 2.3 Error Analysis (Real-time alerts)
CREATE VIEW error_analysis AS
SELECT 
    TUMBLE_START(ts, INTERVAL '30' SECOND) as window_start,
    TUMBLE_END(ts, INTERVAL '30' SECOND) as window_end,
    http_status,
    COUNT(*) as error_count,
    request_uri,
    client_ip
FROM access_logs
WHERE http_status >= 400
GROUP BY 
    TUMBLE(ts, INTERVAL '30' SECOND),
    http_status,
    request_uri,
    client_ip
HAVING COUNT(*) >= 3;  -- Alert threshold: 3+ errors in 30 seconds

-- 2.4 Performance Monitoring
CREATE VIEW performance_monitoring AS
SELECT 
    TUMBLE_START(ts, INTERVAL '2' MINUTE) as window_start,
    TUMBLE_END(ts, INTERVAL '2' MINUTE) as window_end,
    request_uri,
    COUNT(*) as request_count,
    MIN(processing_time_ms) as min_response_time,
    MAX(processing_time_ms) as max_response_time,
    ROUND(AVG(CAST(processing_time_ms AS DOUBLE)), 2) as avg_response_time,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY processing_time_ms) as p50_response_time,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY processing_time_ms) as p95_response_time,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY processing_time_ms) as p99_response_time
FROM access_logs
GROUP BY 
    TUMBLE(ts, INTERVAL '2' MINUTE),
    request_uri
HAVING COUNT(*) >= 5;

-- =================================================================================
-- 3. CREATE SINKS FOR REAL-TIME OUTPUT
-- =================================================================================

-- 3.1 Real-time Traffic Dashboard Sink
CREATE TABLE traffic_dashboard (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    total_requests BIGINT,
    unique_visitors BIGINT,
    avg_response_size DOUBLE,
    avg_processing_time DOUBLE,
    error_count BIGINT,
    error_rate_percent DOUBLE,
    PRIMARY KEY (window_start) NOT ENFORCED
) WITH (
    'connector' = 'print',
    'print-identifier' = 'TRAFFIC_DASHBOARD'
);

-- 3.2 Error Alert Sink
CREATE TABLE error_alerts (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    http_status INT,
    error_count BIGINT,
    request_uri STRING,
    client_ip STRING,
    PRIMARY KEY (window_start, http_status, request_uri, client_ip) NOT ENFORCED
) WITH (
    'connector' = 'print',
    'print-identifier' = 'ERROR_ALERTS'
);

-- 3.3 Performance Metrics Sink
CREATE TABLE performance_metrics (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    request_uri STRING,
    request_count BIGINT,
    min_response_time INT,
    max_response_time INT,
    avg_response_time DOUBLE,
    p50_response_time DOUBLE,
    p95_response_time DOUBLE,
    p99_response_time DOUBLE,
    PRIMARY KEY (window_start, request_uri) NOT ENFORCED
) WITH (
    'connector' = 'print',
    'print-identifier' = 'PERFORMANCE_METRICS'
);

-- =================================================================================
-- 4. INSERT QUERIES - PRODUCTION DATA PIPELINE
-- =================================================================================

-- 4.1 Populate Traffic Dashboard
INSERT INTO traffic_dashboard
SELECT * FROM traffic_overview;

-- 4.2 Populate Error Alerts  
INSERT INTO error_alerts
SELECT * FROM error_analysis;

-- 4.3 Populate Performance Metrics
INSERT INTO performance_metrics
SELECT * FROM performance_monitoring;

-- =================================================================================
-- END OF PRODUCTION PIPELINE
-- =================================================================================
