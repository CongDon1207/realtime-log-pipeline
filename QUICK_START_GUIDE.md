# Hướng dẫn chạy Real-time Log Pipeline

## Tổng quan hệ thống

Pipeline này xử lý logs NGINX theo thời gian thực với luồng dữ liệu:
```
NGINX Logs → Fluent Bit → HTTP Bridge → Apache Pulsar → Analytics
```

### Các thành phần chính:

1. **Apache Pulsar** (port 6650, 8081): Message broker lưu trữ và phân phối logs
2. **Fluent Bit** (port 2020): Thu thập và gửi logs từ file system
3. **HTTP-to-Pulsar Bridge** (port 3001): Chuyển đổi HTTP requests thành Pulsar messages
4. **Log Generator**: Scripts tạo logs mẫu để test

## Bước 1: Khởi động hệ thống

```bash
cd d:/DockerData/realtime-log-pipeline

# Khởi động toàn bộ stack
docker compose -f compose/docker-compose.yml up -d

# Kiểm tra trạng thái services
docker compose -f compose/docker-compose.yml ps
```

**Chờ 30-60 giây** để các services khởi động hoàn toàn.

## Bước 2: Kiểm tra kết nối

### Test Pulsar Bridge:
```bash
# Health check
curl -X GET http://localhost:3001

# Test gửi message
curl -X POST http://localhost:3001 \
  -H "Content-Type: application/json" \
  -d '[{"message": "Test log", "timestamp": "2025-07-25T16:00:00Z"}]'
```

### Kiểm tra Pulsar Admin UI:
- Mở trình duyệt: http://localhost:8081
- Xem topics, subscriptions, messages

## Bước 3: Tạo logs và test pipeline

### Tạo logs mẫu:
```bash
# Tạo logs trong 30 giây
bash scripts/generate-logs.sh 30

# Hoặc thêm log thủ công
echo '192.168.1.100 - - [25/Jul/2025:16:00:00 +0700] "GET /api/test HTTP/1.1" 200 512 "-" "TestAgent"' >> data/access.log
```

### Theo dõi logs pipeline:
```bash
# Logs của Fluent Bit (đọc file)
docker compose -f compose/docker-compose.yml logs fluent-bit --tail=20

# Logs của Bridge (xử lý HTTP)
docker compose -f compose/docker-compose.yml logs pulsar-bridge --tail=20

# Logs của Pulsar
docker compose -f compose/docker-compose.yml logs pulsar --tail=20
```

## Bước 4: Xem kết quả

### Via Pulsar Admin UI:
1. Truy cập http://localhost:8081
2. Chọn **Tenants → public → Namespaces → default → Topics**
3. Click vào topic `nginx-logs`
4. Xem **Subscriptions** và **Messages**

### Via Command Line (nếu cần):
```bash
# Consume messages từ topic
docker exec pulsar sh -c "cd /pulsar && ./bin/pulsar-client consume persistent://public/default/nginx-logs --subscription-name test-sub --num-messages 5"
```

## Cấu trúc file quan trọng

### `/compose/docker-compose.yml`
- Định nghĩa các services và dependencies
- Volume mapping: `data/` → `/var/log/nginx/` trong Fluent Bit

### `/compose/conf/fluent-bit/fluent-bit.conf`
- Cấu hình Fluent Bit đọc `/var/log/nginx/access.log`
- Parser nginx logs format
- Output HTTP tới bridge

### `/compose/conf/pulsar-bridge/pulsar-bridge.py`
- HTTP server nhận logs từ Fluent Bit
- Enrichment: thêm timestamp, source metadata
- Gửi vào Pulsar topic `nginx-logs`

### `/scripts/generate-logs.sh`
- Tạo logs mẫu NGINX format
- Tham số: số giây tạo logs

## Troubleshooting

### Services không start:
```bash
# Xem logs chi tiết
docker compose -f compose/docker-compose.yml logs [service-name]

# Restart service
docker compose -f compose/docker-compose.yml restart [service-name]
```

### Fluent Bit không đọc logs:
```bash
# Kiểm tra file logs có tồn tại
ls -la data/access.log

# Kiểm tra volume mapping
docker exec fluent-bit ls -la /var/log/nginx/
```

### Bridge không nhận requests:
```bash
# Test kết nối
curl -v http://localhost:3001

# Kiểm tra network
docker network ls
docker network inspect compose_default
```

### Pulsar connection issues:
```bash
# Kiểm tra Pulsar topics
docker exec pulsar sh -c "cd /pulsar && ./bin/pulsar-admin topics list public/default"

# Tạo topic thủ công nếu cần
docker exec pulsar sh -c "cd /pulsar && ./bin/pulsar-admin topics create persistent://public/default/nginx-logs"
```

## Dừng hệ thống

```bash
# Dừng toàn bộ
docker compose -f compose/docker-compose.yml down

# Xóa volumes (nếu muốn clean up hoàn toàn)
docker compose -f compose/docker-compose.yml down -v
```

## Tùy chỉnh

### Thay đổi Pulsar topic:
- Sửa `PULSAR_TOPIC` trong `pulsar-bridge.py`
- Rebuild: `docker compose -f compose/docker-compose.yml build pulsar-bridge`

### Thay đổi log format:
- Sửa parser trong `fluent-bit/parsers.conf`
- Restart Fluent Bit

### Scaling:
- Tăng resources trong docker-compose.yml
- Thêm multiple Fluent Bit instances cho nhiều log sources

---

**Pipeline Status**: ✅ Đã fix hoàn toàn - Pulsar client compatibility issue resolved
**Last tested**: 2025-07-25 15:56 UTC+7
