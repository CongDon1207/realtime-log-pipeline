#!/bin/bash
# Deploy tất cả Flink jobs để xử lý logs

echo "🚀 Deploying All Flink Log Processing Jobs..."

# Job 1: Basic log processing
echo "📊 1. Deploying basic log processing..."
powershell -c "docker exec -d flink-jobmanager /opt/flink/bin/sql-client.sh -f /opt/flink/flink-jobs/log-processing.sql"

sleep 2

# Job 2: Error analysis
echo "🚨 2. Deploying error analysis..."
powershell -c "docker exec -d flink-jobmanager /opt/flink/bin/sql-client.sh -f /opt/flink/flink-jobs/error-analysis.sql"

sleep 2

# Job 3: Traffic analysis  
echo "📈 3. Deploying traffic analysis..."
powershell -c "docker exec -d flink-jobmanager /opt/flink/bin/sql-client.sh -f /opt/flink/flink-jobs/traffic-analysis.sql"

echo "✅ All jobs deployed!"

# Kiểm tra jobs
echo "📋 Checking running jobs..."
powershell -c "docker exec flink-jobmanager flink list"
