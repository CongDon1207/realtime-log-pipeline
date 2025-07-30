-- Flink SQL job phân tích lỗi HTTP
-- Tập trung vào status codes 4xx và 5xx

-- Source table (sử dụng lại nginx_logs từ job trước)

-- Sink table cho alerts
CREATE TABLE error_alerts (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    error_type STRING,
    error_count BIGINT,
    error_rate DOUBLE,
    sample_uri STRING,
    sample_user_agent STRING
) WITH (
    'connector' = 'print'
);

-- Job phân tích lỗi theo window 30 giây
INSERT INTO error_alerts
SELECT 
    TUMBLE_START(event_time, INTERVAL '30' SECOND) as window_start,
    TUMBLE_END(event_time, INTERVAL '30' SECOND) as window_end,
    CASE 
        WHEN http_status >= 400 AND http_status < 500 THEN '4xx_Client_Error'
        WHEN http_status >= 500 THEN '5xx_Server_Error'
        ELSE 'Other'
    END as error_type,
    COUNT(*) as error_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
        PARTITION BY TUMBLE(event_time, INTERVAL '30' SECOND)
    ) as error_rate,
    MAX(request_uri) as sample_uri,
    MAX(http_user_agent) as sample_user_agent
FROM nginx_logs
WHERE http_status >= 400
GROUP BY 
    TUMBLE(event_time, INTERVAL '30' SECOND),
    CASE 
        WHEN http_status >= 400 AND http_status < 500 THEN '4xx_Client_Error'
        WHEN http_status >= 500 THEN '5xx_Server_Error'
        ELSE 'Other'
    END
HAVING COUNT(*) > 5;  -- Chỉ alert khi có > 5 lỗi trong 30s
