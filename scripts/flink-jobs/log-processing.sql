-- Flink SQL để xử lý log realtime từ Pulsar
-- Connect trực tiếp với Pulsar topic nginx-logs

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

-- Tạo sink table để output kết quả
CREATE TABLE processed_logs (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    status_code INT,
    request_count BIGINT,
    total_bytes BIGINT,
    avg_bytes DOUBLE,
    top_user_agent STRING
) WITH (
    'connector' = 'print'
);

-- Job xử lý: Phân tích logs theo window 1 phút
INSERT INTO processed_logs
SELECT 
    TUMBLE_START(event_time, INTERVAL '1' MINUTE) as window_start,
    TUMBLE_END(event_time, INTERVAL '1' MINUTE) as window_end,
    status as status_code,
    COUNT(*) as request_count,
    SUM(body_bytes_sent) as total_bytes,
    AVG(CAST(body_bytes_sent AS DOUBLE)) as avg_bytes,
    MAX(http_user_agent) as top_user_agent
FROM nginx_logs
GROUP BY 
    TUMBLE(event_time, INTERVAL '1' MINUTE),
    status;
