#!/bin/bash
set -e

echo "Starting Pulsar standalone..."
# Khởi động Pulsar background
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
bin/pulsar-admin schemas upload persistent://public/default/logs-nginx-access -f /pulsar/schema/log-nginx-access.avsc || echo "Schema upload failed, but continuing..."

echo "Pulsar initialization completed. Keeping container running..."
# Giữ container chạy
wait $PULSAR_PID
