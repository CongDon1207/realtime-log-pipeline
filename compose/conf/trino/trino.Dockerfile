# Trino SQL query engine with Iceberg connector
FROM trinodb/trino:latest

# Switch to root for configuration setup
USER root

# Create required directories and set permissions
RUN mkdir -p /etc/trino/catalog /tmp/trino-data \
    && chown -R trino:trino /etc/trino /tmp/trino-data

# Copy Trino configuration files
COPY config.properties /etc/trino/config.properties
COPY jvm.config /etc/trino/jvm.config
COPY log.properties /etc/trino/log.properties
COPY node.properties /etc/trino/node.properties

# Copy catalog configurations
COPY catalog/ /etc/trino/catalog/

# Set proper ownership and switch back to trino user
RUN chown -R trino:trino /etc/trino
USER trino

# Expose the Trino web UI and API port
EXPOSE 8080
