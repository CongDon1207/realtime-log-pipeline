# 🚀 Realtime Log Pipeline

## 📋 Tổng quan dự án

Pipeline xử lý log realtime sử dụng **Fluent Bit**, **Apache Pulsar** và **HTTP Bridge** để thu thập, xử lý và phân phối log nginx một cách tự động.

## ✅ Trạng thái hiện tại

**HOÀN THÀNH & ĐANG HOẠT ĐỘNG:**
- ✅ Fluent Bit: Thu thập & parse nginx access logs
- ✅ HTTP Bridge: Nhận dữ liệu từ Fluent Bit qua HTTP
- ✅ Pulsar: Message broker standalone mode
- ✅ Docker Compose: Tự động orchestration
- ✅ Health monitoring: Script kiểm tra hệ thống
- ✅ Operation guide: Hướng dẫn vận hành đầy đủ

**LUỒNG DỮ LIỆU:**
```
nginx access.log → Fluent Bit → HTTP Bridge → Pulsar Topic
```

## 🚀 Khởi động hệ thống

```bash
# Clone repository
git clone <repo-url>
cd realtime-log-pipeline

# Khởi động tất cả services
docker compose -f compose/docker-compose.yml up -d

# Kiểm tra trạng thái
./scripts/health-check.sh
```

## 📊 Kiểm tra hoạt động

### Thêm log mới để test:
```bash
echo '192.168.1.200 - - [25/Jul/2025:15:30:00 +0700] "GET /api/health HTTP/1.1" 200 512 "https://monitor.com" "HealthChecker/1.0"' >> data/access.log

# Copy vào container
docker cp data/access.log fluent-bit:/var/log/nginx/access.log
```

### Xem kết quả:
```bash
# Logs của Bridge (sẽ thấy data received)
docker logs pulsar-bridge --tail 10

# Stats của Pulsar topic
curl http://localhost:8081/admin/v2/persistent/public/default/nginx-logs/stats
```

## 🎯 Services & Ports

| Service | Port | Description |
|---------|------|-------------|
| Fluent Bit | 2020 | Log collector & parser |
| Pulsar | 8081 | Message broker admin |
| Pulsar Bridge | 3001 | HTTP-to-Pulsar bridge |

## 📁 Cấu trúc dự án

```
realtime-log-pipeline/
├── compose/
│   ├── docker-compose.yml          # Main orchestration
│   └── conf/                       # Service configurations
├── data/
│   └── access.log                  # Sample nginx logs
├── scripts/
│   ├── health-check.sh             # System monitoring
│   └── generate-logs.sh            # Log generation
├── OPERATION_GUIDE.md              # Hướng dẫn vận hành
└── README.md                       # File này
```

## 🔧 Troubleshooting

### Restart services:
```bash
# Restart individual service
docker compose -f compose/docker-compose.yml restart pulsar-bridge

# Restart all
docker compose -f compose/docker-compose.yml restart
```

### Xem logs:
```bash
docker logs fluent-bit --tail 20
docker logs pulsar-bridge --tail 20
docker logs pulsar --tail 20
```

### Reset toàn bộ:
```bash
docker compose -f compose/docker-compose.yml down
docker compose -f compose/docker-compose.yml up -d
```

## 🎯 Roadmap

### Phase 2 - Analytics (Coming Soon)
- [ ] Apache Flink stream processing
- [ ] Trino SQL engine
- [ ] Real-time dashboards

### Phase 3 - Monitoring
- [ ] Prometheus metrics
- [ ] Grafana dashboards  
- [ ] Alert notifications

### Phase 4 - Production
- [ ] Authentication & authorization
- [ ] Backup & recovery
- [ ] Horizontal scaling

## 📞 Hỗ trợ

- **Operation Guide**: Xem `OPERATION_GUIDE.md` để biết chi tiết
- **Health Check**: Chạy `./scripts/health-check.sh` để kiểm tra hệ thống
- **Logs**: Sử dụng `docker logs <container-name>` để debug

---

**Trạng thái**: ✅ Production Ready (với schema fix nhỏ đang pending)  
**Last Updated**: July 25, 2025
