-- Flink SQL để test log processing (sử dụng DataGen thay vì Pulsar)
-- Test job trước, sau đó sẽ connect Pulsar

-- Tạo source table với DataGen để giả lập logs
CREATE TABLE nginx_logs (
    remote_addr STRING,
    request_method STRING,
    request_uri STRING,
    http_status INT,
    body_bytes_sent BIGINT,
    http_user_agent STRING,
    event_time AS LOCALTIMESTAMP,
    WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'datagen',
    'rows-per-second' = '5',
    'fields.remote_addr.length' = '15',
    'fields.request_method.length' = '4',
    'fields.request_uri.length' = '20',
    'fields.http_status.min' = '200',
    'fields.http_status.max' = '500',
    'fields.body_bytes_sent.min' = '100',
    'fields.body_bytes_sent.max' = '50000',
    'fields.http_user_agent.length' = '30'
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
    http_status as status_code,
    COUNT(*) as request_count,
    SUM(body_bytes_sent) as total_bytes,
    AVG(CAST(body_bytes_sent AS DOUBLE)) as avg_bytes,
    MAX(http_user_agent) as top_user_agent
FROM nginx_logs
GROUP BY 
    TUMBLE(event_time, INTERVAL '1' MINUTE),
    http_status;
