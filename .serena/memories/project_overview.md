# Realtime Log Pipeline Overview

## Mục đích dự án
Pipeline xử lý log realtime tự động sử dụng các công nghệ hiện đại để thu thập, xử lý và phân tích logs từ Nginx.

## Tech Stack
- **Ingestion**: Fluent Bit (thu thập & parse logs)
- **Transport**: HTTP Bridge + Apache Pulsar (message broker)
- **Storage**: MinIO (object storage)
- **Processing**: Apache Flink (stream processing)
- **Analytics**: 
  - Trino (SQL engine)
  - Apache Iceberg (table format)
  - Apache Superset (visualization)
- **Monitoring**: 
  - Prometheus (metrics)
  - Grafana (dashboards)

## Trạng thái hiện tại

### Đã cấu hình & hoạt động:
1. **Data Collection**:
   - Fluent Bit parse & thu thập Nginx logs
   - HTTP Bridge nhận data từ Fluent Bit
   - Pulsar standalone làm message broker

2. **Deployment**:
   - Docker Compose cho orchestration
   - Health check scripts
   - Operation guides đầy đủ

3. **Data Flow**:
```
nginx access.log → Fluent Bit → HTTP Bridge → Pulsar Topic
```

### Đang trong kế hoạch:
1. **Phase 2 - Analytics**: 
   - Flink stream processing
   - Trino SQL engine
   - Real-time dashboards

2. **Phase 3 - Monitoring**:
   - Prometheus metrics
   - Grafana dashboards
   - Alert notifications

3. **Phase 4 - Production**:
   - Authentication & authorization
   - Backup & recovery 
   - Horizontal scaling