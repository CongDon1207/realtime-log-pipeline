# HƯỚNG DẪN VẬN HÀNH REALTIME LOG PIPELINE

## 🚀 1. KHỞI ĐỘNG HỆ THỐNG

### Khởi động tất cả services:
```bash
cd d:/DockerData/realtime-log-pipeline
docker compose -f compose/docker-compose.yml up -d
```

### Kiểm tra trạng thái:
```bash
docker ps
```

## 📊 2. KIỂM TRA HOẠT ĐỘNG

### Kiểm tra Pulsar:
```bash
curl http://localhost:8081/admin/v2/persistent/public/default/nginx-logs/stats
```

### Kiểm tra Bridge:
```bash
curl http://localhost:3001/
```

### Kiểm tra Fluent Bit:
```bash
curl http://localhost:2020/api/v1/health
```

## 📥 3. THÊM LOG MỚI

### Thêm log entry:
```bash
echo '192.168.1.109 - - [25/Jul/2025:15:25:00 +0700] "GET /api/test HTTP/1.1" 200 1024 "https://example.com" "TestClient/1.0"' >> data/access.log
```

### Copy vào container:
```bash
docker cp data/access.log fluent-bit:/var/log/nginx/access.log
```

## 🔧 4. TROUBLESHOOTING

### Xem logs chi tiết:
```bash
# Fluent Bit logs
docker logs fluent-bit --tail 20

# Bridge logs  
docker logs pulsar-bridge --tail 20

# Pulsar logs
docker logs pulsar --tail 20
```

### Restart services:
```bash
# Restart individual service
docker compose -f compose/docker-compose.yml restart fluent-bit

# Restart all
docker compose -f compose/docker-compose.yml restart
```

## 📈 5. MONITORING

### Health checks:
```bash
#!/bin/bash
echo "=== Pipeline Health Check ==="
echo "Fluent Bit: $(curl -s http://localhost:2020/api/v1/health)"
echo "Bridge: $(curl -s http://localhost:3001/ | jq -r .status)"
echo "Pulsar: $(curl -s http://localhost:8081/admin/v2/brokers/health)"
```

### Log processing stats:
```bash
# Xem số message trong Pulsar topic
curl -s http://localhost:8081/admin/v2/persistent/public/default/nginx-logs/stats | jq '.msgInCounter'
```

## ⚠️ 6. KNOWN ISSUES

### Schema Issue (đang fix):
- Bridge nhận dữ liệu từ Fluent Bit OK
- Lỗi khi gửi vào Pulsar: schema type mismatch
- Workaround: Sử dụng HTTP endpoint để monitor dữ liệu

### Volume Mount Issue:
- Windows/WSL volume mounting có thể không stable
- Workaround: Copy file trực tiếp vào container

## 🔄 7. DAILY OPERATIONS

### Morning checklist:
1. `docker ps` - Kiểm tra containers running
2. `curl http://localhost:3001/` - Test bridge
3. Xem logs của ngày hôm trước
4. Clean up old logs nếu cần

### Weekly maintenance:
1. Restart toàn bộ stack
2. Backup configuration files
3. Check disk usage
4. Update images nếu có

## 📁 8. PROJECT STRUCTURE

```
realtime-log-pipeline/
├── compose/
│   ├── docker-compose.yml          # Main orchestration
│   └── conf/
│       ├── fluent-bit/             # Log collector config
│       ├── pulsar/                 # Message broker config
│       └── pulsar-bridge/          # HTTP-to-Pulsar bridge
├── data/
│   └── access.log                  # Sample nginx logs
└── scripts/
    ├── health-check.sh             # Health monitoring
    ├── generate-logs.sh            # Log generation
    └── pulsar-bridge.py           # Bridge implementation
```

## 🎯 9. NEXT PHASE ROADMAP

### Phase 2: Analytics Layer
- [ ] Add Flink for stream processing
- [ ] Setup Trino for SQL queries
- [ ] Implement real-time dashboards

### Phase 3: Alerting
- [ ] Prometheus metrics collection
- [ ] Grafana dashboards
- [ ] Alert rules for anomalies

### Phase 4: Production Ready
- [ ] Fix Pulsar schema issue
- [ ] Implement proper volume mounts
- [ ] Add authentication & authorization
- [ ] Setup backup & recovery

## 📞 10. SUPPORT

### Quick fixes:
```bash
# Reset entire pipeline
docker compose -f compose/docker-compose.yml down
docker compose -f compose/docker-compose.yml up -d

# Clear all data and restart fresh
docker compose -f compose/docker-compose.yml down -v
docker compose -f compose/docker-compose.yml up -d
```
