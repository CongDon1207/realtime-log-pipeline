# Custom Apache Pulsar image
FROM apachepulsar/pulsar:latest

# Add custom configurations and plugins if needed
# COPY ./conf/ /pulsar/conf/

# Optionally install additional packages
# RUN apt-get update && apt-get install -y --no-install-recommends ...

# Expose needed ports
EXPOSE 6650 8080

# Default command will run Pulsar in standalone mode
CMD ["bin/pulsar", "standalone"]
