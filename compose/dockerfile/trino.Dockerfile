# Trino (formerly PrestoSQL) query engine
FROM trinodb/trino:latest

# Add additional connectors or plugins if needed
# COPY ./connectors/ /usr/lib/trino/plugin/

# Our custom configuration will be mounted from the host
# COPY ./etc/catalog/ /etc/trino/catalog/
# COPY ./etc/config.properties /etc/trino/config.properties

# Expose the Trino web UI and API port
EXPOSE 8080

# The default command is sufficient and will be used
