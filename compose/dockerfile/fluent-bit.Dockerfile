# Fluent Bit with custom configuration
FROM fluent/fluent-bit:latest

# Add any additional dependencies if needed
# RUN apt-get update && apt-get install -y --no-install-recommends ...

# Our custom configuration will be mounted from the host
# COPY fluent-bit.conf /fluent-bit/etc/fluent-bit.conf
# COPY parsers.conf /fluent-bit/etc/parsers.conf

# Expose the HTTP server port
EXPOSE 2020

# Default entry point remains unchanged
# ENTRYPOINT ["/fluent-bit/bin/fluent-bit"]

# Default command with our config
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
