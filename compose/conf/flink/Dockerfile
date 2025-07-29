# Flink JobManager and TaskManager Dockerfile
FROM flink:latest

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-dev \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install PyFlink and other Python packages
RUN pip3 install apache-flink pandas numpy

# Tải tự động Pulsar connector và client JAR
RUN mkdir -p /opt/flink/lib

# Tải Pulsar client JAR - phiên bản stable 
RUN wget -O /opt/flink/lib/pulsar-client.jar \
    https://repo1.maven.org/maven2/org/apache/pulsar/pulsar-client/2.11.2/pulsar-client-2.11.2.jar

# Tải Pulsar client API JAR
RUN wget -O /opt/flink/lib/pulsar-client-api.jar \
    https://repo1.maven.org/maven2/org/apache/pulsar/pulsar-client-api/2.11.2/pulsar-client-api-2.11.2.jar

# Note: Flink Pulsar connector sẽ được thêm thông qua job deployment
# vì connector không có sẵn trong Maven Central cho tất cả phiên bản

WORKDIR /opt/flink