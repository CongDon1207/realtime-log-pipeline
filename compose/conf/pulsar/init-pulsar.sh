#!/bin/bash
set -e

echo "Starting Pulsar standalone..."

# Khởi động Pulsar background với cấu hình mặc định
bin/pulsar standalone &
PULSAR_PID=$!

echo "Waiting for Pulsar to be ready..."
# Đợi Pulsar sẵn sàng - kiểm tra health endpoint
for i in {1..30}; do
    if curl -s http://localhost:8080/admin/v2/broker-stats/topics > /dev/null 2>&1; then
        echo "Pulsar is ready!"
        break
    fi
    echo "Waiting for Pulsar... ($i/30)"
    sleep 2
done

echo "Creating topic and schema..."
# Tạo topic và schema
bin/pulsar-admin topics create persistent://public/default/logs-nginx-access || echo "Topic may already exist"

# Create a simple HTTP producer endpoint for Fluent Bit
echo "Setting up HTTP producer endpoint..."
bin/pulsar-admin namespaces set-retention public/default --size 1G --time 7d || echo "Retention policy set failed, continuing..."

echo "Enabling HTTP producer on topic..."
# Note: We'll use the built-in REST API for message publishing

echo "Pulsar initialization completed. Keeping container running..."
# Giữ container chạy
wait $PULSAR_PID
