-- =================================================================================
-- ADVANCED REAL-TIME ANALYTICS - MACHINE LEARNING & ANOMALY DETECTION
-- Using DataGen for complex pattern analysis
-- =================================================================================

-- 1. CREATE ENHANCED SOURCE with ML Features
CREATE TABLE enhanced_logs (
    ts TIMESTAMP(3),
    client_ip STRING,
    request_method STRING,
    request_uri STRING,
    http_status INT,
    response_size BIGINT,
    user_agent STRING,
    referer STRING,
    processing_time_ms INT,
    session_id STRING,
    country_code STRING,
    device_type STRING,
    WATERMARK FOR ts AS ts - INTERVAL '10' SECOND
) WITH (
    'connector' = 'datagen',
    'fields.ts.kind' = 'sequence',
    'fields.ts.start' = '2025-07-30 00:00:00',
    'fields.ts.end' = '2025-07-30 23:59:59',
    
    'fields.client_ip.kind' = 'random',
    'fields.client_ip.min' = '10.0.0.1',
    'fields.client_ip.max' = '10.255.255.255',
    
    'fields.request_method.length' = '1',
    'fields.request_method.kind' = 'sequence',
    
    'fields.request_uri.kind' = 'sequence',
    'fields.request_uri.length' = '30',
    
    'fields.http_status.min' = '200',
    'fields.http_status.max' = '502',
    
    'fields.response_size.min' = '50',
    'fields.response_size.max' = '100000',
    
    'fields.user_agent.length' = '80',
    'fields.processing_time_ms.min' = '5',
    'fields.processing_time_ms.max' = '5000',
    
    'fields.session_id.kind' = 'random',
    'fields.session_id.length' = '32',
    
    'fields.country_code.length' = '2',
    'fields.device_type.length' = '10',
    
    'rows-per-second' = '150'
);

-- =================================================================================
-- 2. ANOMALY DETECTION ANALYTICS
-- =================================================================================

-- 2.1 Traffic Spike Detection (Detect unusual traffic patterns)
CREATE VIEW traffic_spike_detection AS
SELECT 
    TUMBLE_START(ts, INTERVAL '1' MINUTE) as window_start,
    TUMBLE_END(ts, INTERVAL '1' MINUTE) as window_end,
    client_ip,
    COUNT(*) as request_count,
    AVG(COUNT(*)) OVER (
        PARTITION BY client_ip 
        ORDER BY TUMBLE_START(ts, INTERVAL '1' MINUTE)
        ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING
    ) as avg_requests_last_5min,
    CASE 
        WHEN COUNT(*) > 3 * AVG(COUNT(*)) OVER (
            PARTITION BY client_ip 
            ORDER BY TUMBLE_START(ts, INTERVAL '1' MINUTE)
            ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING
        ) THEN 'SPIKE_DETECTED'
        ELSE 'NORMAL'
    END as anomaly_status
FROM enhanced_logs
GROUP BY 
    TUMBLE(ts, INTERVAL '1' MINUTE),
    client_ip
HAVING COUNT(*) > 20;  -- Only consider IPs with significant traffic

-- 2.2 Bot Detection (Identify suspicious patterns)
CREATE VIEW bot_detection AS
SELECT 
    TUMBLE_START(ts, INTERVAL '5' MINUTE) as window_start,
    TUMBLE_END(ts, INTERVAL '5' MINUTE) as window_end,
    client_ip,
    COUNT(*) as total_requests,
    COUNT(DISTINCT request_uri) as unique_pages,
    COUNT(DISTINCT session_id) as unique_sessions,
    ROUND(AVG(CAST(processing_time_ms AS DOUBLE)), 2) as avg_processing_time,
    ROUND(
        COUNT(*) * 1.0 / COUNT(DISTINCT request_uri), 2
    ) as requests_per_page_ratio,
    CASE 
        WHEN COUNT(*) > 100 
             AND COUNT(DISTINCT request_uri) < 5 
             AND AVG(CAST(processing_time_ms AS DOUBLE)) < 50
        THEN 'SUSPECTED_BOT'
        WHEN COUNT(*) > 200 
             AND COUNT(DISTINCT session_id) = 1
        THEN 'LIKELY_BOT'
        ELSE 'HUMAN'
    END as classification
FROM enhanced_logs
GROUP BY 
    TUMBLE(ts, INTERVAL '5' MINUTE),
    client_ip
HAVING COUNT(*) > 30;

-- 2.3 Geographic Analysis
CREATE VIEW geographic_analysis AS
SELECT 
    TUMBLE_START(ts, INTERVAL '10' MINUTE) as window_start,
    TUMBLE_END(ts, INTERVAL '10' MINUTE) as window_end,
    country_code,
    device_type,
    COUNT(*) as request_count,
    COUNT(DISTINCT client_ip) as unique_ips,
    ROUND(AVG(CAST(response_size AS DOUBLE)), 2) as avg_response_size,
    ROUND(AVG(CAST(processing_time_ms AS DOUBLE)), 2) as avg_processing_time,
    SUM(CASE WHEN http_status >= 400 THEN 1 ELSE 0 END) as error_count,
    ROUND(
        SUM(CASE WHEN http_status >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) as error_rate
FROM enhanced_logs
GROUP BY 
    TUMBLE(ts, INTERVAL '10' MINUTE),
    country_code,
    device_type;

-- 2.4 Session Analysis & User Journey
CREATE VIEW session_analysis AS
SELECT 
    TUMBLE_START(ts, INTERVAL '15' MINUTE) as window_start,
    TUMBLE_END(ts, INTERVAL '15' MINUTE) as window_end,
    session_id,
    client_ip,
    COUNT(*) as page_views,
    COUNT(DISTINCT request_uri) as unique_pages,
    MIN(ts) as session_start,
    MAX(ts) as session_end,
    ROUND(
        EXTRACT(EPOCH FROM (MAX(ts) - MIN(ts))) / 60.0, 2
    ) as session_duration_minutes,
    SUM(response_size) as total_bytes_transferred,
    ROUND(AVG(CAST(processing_time_ms AS DOUBLE)), 2) as avg_page_load_time
FROM enhanced_logs
GROUP BY 
    TUMBLE(ts, INTERVAL '15' MINUTE),
    session_id,
    client_ip
HAVING COUNT(*) > 5;  -- Sessions with meaningful activity

-- =================================================================================
-- 3. ADVANCED PERFORMANCE INSIGHTS
-- =================================================================================

-- 3.1 Resource Usage Optimization
CREATE VIEW resource_optimization AS
SELECT 
    TUMBLE_START(ts, INTERVAL '5' MINUTE) as window_start,
    TUMBLE_END(ts, INTERVAL '5' MINUTE) as window_end,
    request_uri,
    device_type,
    COUNT(*) as request_count,
    ROUND(AVG(CAST(processing_time_ms AS DOUBLE)), 2) as avg_processing_time,
    ROUND(AVG(CAST(response_size AS DOUBLE)), 2) as avg_response_size,
    ROUND(
        SUM(response_size) * 1.0 / (1024 * 1024), 2
    ) as total_mb_transferred,
    CASE 
        WHEN AVG(CAST(processing_time_ms AS DOUBLE)) > 1000 
             AND AVG(CAST(response_size AS DOUBLE)) > 10000
        THEN 'OPTIMIZE_NEEDED'
        WHEN AVG(CAST(processing_time_ms AS DOUBLE)) > 500
        THEN 'MONITOR_PERFORMANCE'
        ELSE 'GOOD_PERFORMANCE'
    END as performance_status
FROM enhanced_logs
GROUP BY 
    TUMBLE(ts, INTERVAL '5' MINUTE),
    request_uri,
    device_type
HAVING COUNT(*) >= 10;

-- =================================================================================
-- 4. OUTPUT SINKS FOR ADVANCED ANALYTICS
-- =================================================================================

-- 4.1 Anomaly Alerts Sink
CREATE TABLE anomaly_alerts (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    client_ip STRING,
    request_count BIGINT,
    avg_requests_last_5min DOUBLE,
    anomaly_status STRING,
    PRIMARY KEY (window_start, client_ip) NOT ENFORCED
) WITH (
    'connector' = 'print',
    'print-identifier' = 'ANOMALY_ALERTS'
);

-- 4.2 Bot Detection Sink
CREATE TABLE bot_alerts (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    client_ip STRING,
    total_requests BIGINT,
    unique_pages BIGINT,
    unique_sessions BIGINT,
    requests_per_page_ratio DOUBLE,
    classification STRING,
    PRIMARY KEY (window_start, client_ip) NOT ENFORCED
) WITH (
    'connector' = 'print',
    'print-identifier' = 'BOT_DETECTION'
);

-- 4.3 Geographic Insights Sink
CREATE TABLE geographic_insights (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    country_code STRING,
    device_type STRING,
    request_count BIGINT,
    unique_ips BIGINT,
    avg_response_size DOUBLE,
    avg_processing_time DOUBLE,
    error_count BIGINT,
    error_rate DOUBLE,
    PRIMARY KEY (window_start, country_code, device_type) NOT ENFORCED
) WITH (
    'connector' = 'print',
    'print-identifier' = 'GEOGRAPHIC_INSIGHTS'
);

-- 4.4 Session Analytics Sink
CREATE TABLE session_insights (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    session_id STRING,
    client_ip STRING,
    page_views BIGINT,
    unique_pages BIGINT,
    session_duration_minutes DOUBLE,
    total_bytes_transferred BIGINT,
    avg_page_load_time DOUBLE,
    PRIMARY KEY (window_start, session_id) NOT ENFORCED
) WITH (
    'connector' = 'print',
    'print-identifier' = 'SESSION_INSIGHTS'
);

-- =================================================================================
-- 5. POPULATE ADVANCED ANALYTICS SINKS
-- =================================================================================

-- 5.1 Real-time Anomaly Detection
INSERT INTO anomaly_alerts
SELECT 
    window_start,
    window_end,
    client_ip,
    request_count,
    avg_requests_last_5min,
    anomaly_status
FROM traffic_spike_detection
WHERE anomaly_status = 'SPIKE_DETECTED';

-- 5.2 Bot Detection Pipeline
INSERT INTO bot_alerts
SELECT 
    window_start,
    window_end,
    client_ip,
    total_requests,
    unique_pages,
    unique_sessions,
    requests_per_page_ratio,
    classification
FROM bot_detection
WHERE classification IN ('SUSPECTED_BOT', 'LIKELY_BOT');

-- 5.3 Geographic Analytics
INSERT INTO geographic_insights
SELECT * FROM geographic_analysis;

-- 5.4 Session Intelligence
INSERT INTO session_insights
SELECT * FROM session_analysis;

-- =================================================================================
-- END OF ADVANCED ANALYTICS PIPELINE
-- =================================================================================
