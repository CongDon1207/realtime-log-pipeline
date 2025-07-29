# Project Task Completion Guidelines

## Before Committing Code
1. **Test Scripts**
   - Chạy generate test logs: `./scripts/generate-test-logs.sh`
   - Validate log format: `./scripts/test-log-format.sh`
   - Kiểm tra health check: `./scripts/health-check.sh`

2. **Check Services**
   ```bash
   # Kiểm tra logs không có errors
   docker compose -f compose/docker-compose.yml logs fluent-bit
   docker compose -f compose/docker-compose.yml logs pulsar-bridge
   docker compose -f compose/docker-compose.yml logs pulsar
   ```

3. **Verify Data Flow**
   - Kiểm tra logs được thu thập bởi Fluent Bit
   - Verify logs đến được Pulsar topic
   - Check metrics nếu có monitoring

## Code Quality
1. **Documentation**
   - Cập nhật README nếu có thay đổi architecture
   - Thêm comments cho code mới
   - Cập nhật operation guide nếu cần

2. **Clean Up**
   - Xóa test logs: `./scripts/clean-logs.sh`
   - Remove unused containers/images
   - Clean up temporary files

## Git Workflow
1. **Commit Changes**
   ```bash
   git add .
   git commit -m "type: description"
   git push origin branch-name
   ```

2. **Pull Request**
   - Tạo PR với description đầy đủ
   - Link related issues
   - Request review từ team members