-- Flink SQL job phân tích patterns traffic
-- Top IPs, URLs, User Agents theo thời gian

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
