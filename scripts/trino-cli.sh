#!/bin/bash
# Script để chạy Trino CLI mà không gặp lỗi JVM

docker exec -e JAVA_TOOL_OPTIONS= trino trino "$@"
