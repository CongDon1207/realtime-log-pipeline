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

# Create lib directory and add useful connectors
RUN mkdir -p /opt/flink/lib

# Add stable connectors (commented Pulsar - use file/kafka instead)
# RUN wget -O /opt/flink/lib/flink-sql-connector-kafka-1.17.2.jar \
#     https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/1.17.2/flink-sql-connector-kafka-1.17.2.jar

# Create data directory for file-based processing
RUN mkdir -p /opt/flink/data

WORKDIR /opt/flink