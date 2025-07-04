# Flink JobManager and TaskManager Dockerfile
FROM flink:latest

# Add any dependencies needed for our specific job
# RUN apt-get update && apt-get install -y --no-install-recommends ...

# Install additional Python dependencies if using PyFlink
# RUN pip install pandas numpy

# Add any custom Flink plugins or connectors
# COPY ./plugins/ /opt/flink/plugins/

# Environment variables can be set in docker-compose.yml
# ENV JOB_MANAGER_RPC_ADDRESS=flink-jobmanager

# Default command will be set in docker-compose.yml
# (either "jobmanager" or "taskmanager")
