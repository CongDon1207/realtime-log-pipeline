# Hướng dẫn kiểm tra và test Apache Pulsar trong container

## 1. Kiểm tra trạng thái container

Trước tiên, kiểm tra xem container Pulsar đã chạy chưa:

```bash
docker compose ps
```

Kết quả mong đợi sẽ hiển thị container `pulsar` với status `Up`.

## 2. Truy cập vào container Pulsar

### Cách 1: Truy cập interactive shell
```bash
docker exec -it pulsar /bin/bash
```

### Cách 2: Chạy lệnh trực tiếp từ bên ngoài
```bash
docker exec pulsar [lệnh-pulsar]
```

## 3. Các lệnh kiểm tra cơ bản

### 3.1 Kiểm tra trạng thái broker
```bash
# Trong container
bin/pulsar-admin brokers list standalone

# Từ bên ngoài container
docker exec pulsar bin/pulsar-admin brokers list standalone
```

### 3.2 Kiểm tra danh sách tenants
```bash
# Trong container
bin/pulsar-admin tenants list

# Từ bên ngoài container
docker exec pulsar bin/pulsar-admin tenants list
```

### 3.3 Kiểm tra danh sách namespaces
```bash
# Trong container
bin/pulsar-admin namespaces list public

# Từ bên ngoài container
docker exec pulsar bin/pulsar-admin namespaces list public
```

### 3.4 Kiểm tra danh sách topics
```bash
# Trong container
bin/pulsar-admin topics list public/default

# Từ bên ngoài container
docker exec pulsar bin/pulsar-admin topics list public/default
```

## 4. Test gửi và nhận message

### 4.1 Tạo topic mới (tùy chọn)
```bash
# Trong container
bin/pulsar-admin topics create persistent://public/default/test-topic

# Từ bên ngoài container
docker exec pulsar bin/pulsar-admin topics create persistent://public/default/test-topic
```

### 4.2 Gửi message (Producer)
```bash
# Gửi một message đơn
docker exec pulsar bin/pulsar-client produce "persistent://public/default/test-topic" \
  --messages "Hello Pulsar!"

# Gửi nhiều message
docker exec pulsar bin/pulsar-client produce "persistent://public/default/test-topic" \
  --messages "Message 1" "Message 2" "Message 3"

# Gửi message với key
docker exec pulsar bin/pulsar-client produce "persistent://public/default/test-topic" \
  --messages "Message with key" \
  --key "my-key"
```

### 4.3 Nhận message (Consumer)
```bash
# Consumer với subscription mới
docker exec pulsar bin/pulsar-client consume "persistent://public/default/test-topic" \
  --subscription-name "test-subscription" \
  --num-messages 0

# Consumer nhận số lượng message giới hạn
docker exec pulsar bin/pulsar-client consume "persistent://public/default/test-topic" \
  --subscription-name "test-subscription" \
  --num-messages 5
```

## 5. Kiểm tra schema (nếu có)

### 5.1 Xem schema đã đăng ký
```bash
# Trong container
bin/pulsar-admin schemas get persistent://public/default/log-nginx-access

# Từ bên ngoài container
docker exec pulsar bin/pulsar-admin schemas get persistent://public/default/log-nginx-access
```

### 5.2 Đăng ký schema mới
```bash
# Đăng ký schema từ file
docker exec pulsar bin/pulsar-admin schemas upload persistent://public/default/my-topic \
  --filename /pulsar/schema/log-nginx-access.avsc
```

## 6. Monitoring và debugging

### 6.1 Xem logs của container
```bash
docker logs pulsar
docker logs pulsar -f  # Follow logs real-time
```

### 6.2 Kiểm tra stats của topic
```bash
docker exec pulsar bin/pulsar-admin topics stats persistent://public/default/test-topic
```

### 6.3 Kiểm tra subscriptions
```bash
docker exec pulsar bin/pulsar-admin topics subscriptions persistent://public/default/test-topic
```

### 6.4 Kiểm tra thông tin cluster
```bash
docker exec pulsar bin/pulsar-admin clusters list
docker exec pulsar bin/pulsar-admin clusters get standalone
```

## 7. REST API (thông qua curl)

Pulsar cũng cung cấp REST API qua port 8080 (mapped sang 8081):

### 7.1 Kiểm tra trạng thái broker
```bash
curl http://localhost:8081/admin/v2/brokers/standalone
```

### 7.2 Lấy danh sách topics
```bash
curl http://localhost:8081/admin/v2/persistent/public/default
```

### 7.3 Gửi message qua REST API
```bash
curl -X POST http://localhost:8081/admin/v2/persistent/public/default/test-topic/publish \
  -H "Content-Type: application/json" \
  -d '{"payload": "SGVsbG8gUHVsc2Fy"}'  # Base64 encoded "Hello Pulsar"
```

## 8. Cleanup

### 8.1 Xóa topic
```bash
docker exec pulsar bin/pulsar-admin topics delete persistent://public/default/test-topic
```

### 8.2 Xóa subscription
```bash
docker exec pulsar bin/pulsar-admin topics unsubscribe persistent://public/default/test-topic \
  --subscription "test-subscription"
```

## 9. Troubleshooting

### 9.1 Container không khởi động được
- Kiểm tra logs: `docker logs pulsar`
- Kiểm tra port conflicts: `docker port pulsar`
- Rebuild image: `docker compose build pulsar`

### 9.2 Không kết nối được
- Kiểm tra firewall/port mapping
- Kiểm tra service discovery: `docker exec pulsar bin/pulsar-admin brokers healthcheck`

### 9.3 Message không được consume
- Kiểm tra subscription type và position
- Kiểm tra topic stats để xem message có được publish không

## 10. Demo script hoàn chỉnh

```bash
#!/bin/bash

echo "=== Demo Pulsar Test ==="

# 1. Kiểm tra trạng thái
echo "1. Checking Pulsar status..."
docker exec pulsar bin/pulsar-admin brokers healthcheck

# 2. Tạo topic
echo "2. Creating test topic..."
docker exec pulsar bin/pulsar-admin topics create persistent://public/default/demo-topic

# 3. Gửi message
echo "3. Sending messages..."
docker exec pulsar bin/pulsar-client produce persistent://public/default/demo-topic \
  --messages "Demo message 1" "Demo message 2" "Demo message 3"

# 4. Nhận message
echo "4. Consuming messages..."
docker exec pulsar bin/pulsar-client consume persistent://public/default/demo-topic \
  --subscription-name "demo-sub" \
  --num-messages 3

# 5. Kiểm tra stats
echo "5. Topic stats:"
docker exec pulsar bin/pulsar-admin topics stats persistent://public/default/demo-topic

echo "=== Demo completed ==="
```

Lưu script này vào file `test-pulsar.sh` và chạy với `chmod +x test-pulsar.sh && ./test-pulsar.sh`
