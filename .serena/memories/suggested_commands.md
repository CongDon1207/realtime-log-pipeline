# Các lệnh thường dùng trong dự án

## Docker Compose Commands
```bash
# Khởi động toàn bộ stack
docker compose -f compose/docker-compose.yml up -d

# Dừng toàn bộ stack
docker compose -f compose/docker-compose.yml down

# Restart service cụ thể
docker compose -f compose/docker-compose.yml restart <service-name>

# Xem logs
docker compose -f compose/docker-compose.yml logs <service-name>
```

## Monitoring Commands
```bash
# Kiểm tra sức khỏe hệ thống
./scripts/health-check.sh

# Xem logs từng service
docker logs fluent-bit --tail 20
docker logs pulsar-bridge --tail 20
docker logs pulsar --tail 20
```

## Testing Commands
```bash
# Sinh test logs
./scripts/generate-logs.sh
./scripts/generate-logs-advanced.sh
./scripts/generate-test-logs.sh

# Test format log
./scripts/test-log-format.sh

# Kiểm tra kết quả trên Pulsar
curl http://localhost:8081/admin/v2/persistent/public/default/nginx-logs/stats
```

## Deployment Commands
```bash
# Deploy Flink job
./scripts/deploy-flink-job.sh

# Clean logs
./scripts/clean-logs.sh
```

## Git Commands
```bash
# Clone repository
git clone <repo-url>
cd realtime-log-pipeline

# Check status
git status

# Create new branch
git checkout -b feature/new-feature

# Commit changes
git add .
git commit -m "feat: description"
git push origin feature/new-feature
```