# Log Analytics Realtime Pipeline

## Tổng quan

Dự án xây dựng hệ thống phân tích log web (Nginx) theo thời gian thực, phát hiện bất thường, lưu trữ lịch sử và trực quan hóa.

## Kiến trúc

Chi tiết kiến trúc và hướng dẫn triển khai có trong file [log_analytics_guide.md](log_analytics_guide.md).

## Cài đặt & Triển khai

1. Sao chép `.env.example` thành `.env` và cấu hình các biến môi trường
2. Khởi chạy các dịch vụ:
   ```
   docker-compose -f compose/docker-compose.yml up -d
   ```
3. Theo dõi logs:
   ```
   docker-compose -f compose/docker-compose.yml logs -f
   ```

## Các thành phần chính

- **Fluent Bit**: Thu thập và chuyển đổi log
- **Apache Pulsar**: Message broker
- **Apache Flink**: Stream processing
- **MinIO & Apache Iceberg**: Lưu trữ dữ liệu
- **Prometheus & Grafana**: Giám sát và cảnh báo
- **Trino & Superset**: BI và phân tích dài hạn

## License

Dự án này được phân phối theo giấy phép MIT.
