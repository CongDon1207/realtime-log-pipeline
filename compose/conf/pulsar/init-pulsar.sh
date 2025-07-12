#!/bin/bash
set -e

# Khởi động Pulsar background
bin/pulsar standalone &

# Đợi Pulsar sẵn sàng (có thể chờ theo port hoặc API)
sleep 20

# Tạo topic và schema
bin/pulsar-admin topics create persistent://public/default/logs-nginx-access
bin/pulsar-admin schemas upload persistent://public/default/logs-nginx-access -f /pulsar/schema/log-nginx-access.avsc

# Giữ container chạy
wait
