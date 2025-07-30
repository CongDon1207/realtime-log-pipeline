-- Flink SQL job phân tích patterns traffic từ Pulsar
-- Top IPs, URLs, User Agents theo thời gian

-- Source table sử dụng Pulsar (đã định nghĩa trong log-processing.sql)
-- Tạo source table với Pulsar connector
CREATE TABLE nginx_logs (
    remote_addr STRING,
    time_iso8601 STRING,
    request STRING,
    status INT,
    body_bytes_sent BIGINT,
    http_referer STRING,
    http_user_agent STRING,
    hostname STRING,
    event_time AS TO_TIMESTAMP(time_iso8601, 'yyyy-MM-dd''T''HH:mm:ss.SSSX'),
    WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'pulsar',
    'service-url' = 'pulsar://pulsar:6650',
    'admin-url' = 'http://pulsar:8080',
    'topic' = 'persistent://public/default/nginx-logs',
    'value.format' = 'avro',
    'scan.startup.mode' = 'latest'
);

-- Sink table cho traffic analysis
CREATE TABLE traffic_analysis (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    analysis_type STRING,
    top_item STRING,
    request_count BIGINT,
    total_bytes BIGINT,
    unique_ips BIGINT
) WITH (
    'connector' = 'print'
);

-- Job 1: Top IP addresses
INSERT INTO traffic_analysis
SELECT 
    TUMBLE_START(event_time, INTERVAL '2' MINUTE) as window_start,
    TUMBLE_END(event_time, INTERVAL '2' MINUTE) as window_end,
    'TOP_IP' as analysis_type,
    remote_addr as top_item,
    COUNT(*) as request_count,
    SUM(body_bytes_sent) as total_bytes,
    COUNT(DISTINCT remote_addr) as unique_ips
FROM nginx_logs
GROUP BY 
    TUMBLE(event_time, INTERVAL '2' MINUTE),
    remote_addr
HAVING COUNT(*) >= 10  -- Chỉ hiển thị IPs có >= 10 requests
ORDER BY request_count DESC
LIMIT 5;
