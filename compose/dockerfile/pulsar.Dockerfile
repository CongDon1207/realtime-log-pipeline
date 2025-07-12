# Custom Apache Pulsar image
FROM apachepulsar/pulsar:latest

# Create schema directory
RUN mkdir -p /pulsar/schema

# Copy initialization script and schema file
COPY ../conf/pulsar/init-pulsar.sh /pulsar/init-pulsar.sh
COPY ../conf/pulsar/log-nginx-access.avsc /pulsar/schema/log-nginx-access.avsc

# Make script executable
RUN chmod +x /pulsar/init-pulsar.sh

# Expose needed ports
EXPOSE 6650 8080

# Default command will run Pulsar in standalone mode
CMD ["bin/pulsar", "standalone"]
