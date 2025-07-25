#!/bin/bash

# Realtime Log Pipeline Health Check Script
# Usage: ./scripts/health-check.sh

echo "================================================"
echo "🔍 REALTIME LOG PIPELINE HEALTH CHECK"
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_service() {
    local service_name=$1
    local url=$2
    local expected_text=$3
    
    echo -n "Checking $service_name... "
    
    if response=$(curl -s --connect-timeout 5 "$url" 2>/dev/null); then
        if [[ "$response" == *"$expected_text"* ]]; then
            echo -e "${GREEN}✅ OK${NC}"
        else
            echo -e "${YELLOW}⚠️  Response: $response${NC}"
        fi
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
}

# Check Docker containers
echo -e "\n📦 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(fluent-bit|pulsar|bridge)"

echo -e "\n🌐 Service Health Checks:"

# Check Fluent Bit
check_service "Fluent Bit" "http://localhost:2020/api/v1/health" "ok"

# Check Pulsar Bridge  
check_service "Pulsar Bridge" "http://localhost:3001/" "ok"

# Check Pulsar
check_service "Pulsar" "http://localhost:8081/admin/v2/brokers/health" "ok"

# Check Pulsar topic stats
echo -e "\n📊 Pulsar Topic Stats:"
if stats=$(curl -s http://localhost:8081/admin/v2/persistent/public/default/nginx-logs/stats 2>/dev/null); then
    if echo "$stats" | jq . >/dev/null 2>&1; then
        echo "Messages in: $(echo "$stats" | jq -r '.msgInCounter // "N/A"')"
        echo "Messages out: $(echo "$stats" | jq -r '.msgOutCounter // "N/A"')"
        echo "Storage size: $(echo "$stats" | jq -r '.storageSize // "N/A"') bytes"
    else
        echo -e "${YELLOW}⚠️  Topic may not exist yet${NC}"
    fi
else
    echo -e "${RED}❌ Cannot connect to Pulsar${NC}"
fi

# Check recent logs
echo -e "\n📝 Recent Activity:"
echo "Last 5 lines from Bridge logs:"
docker logs pulsar-bridge --tail 5 2>/dev/null | sed 's/^/  /'

echo -e "\n💡 Quick Actions:"
echo "  - Add test log: echo 'test log' >> data/access.log"
echo "  - Copy to container: docker cp data/access.log fluent-bit:/var/log/nginx/access.log"
echo "  - Restart bridge: docker compose -f compose/docker-compose.yml restart pulsar-bridge"

echo -e "\n================================================"
echo "✅ Health check completed!"
echo "================================================"
