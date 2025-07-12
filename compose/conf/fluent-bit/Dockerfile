# Fluent Bit with custom configuration
FROM fluent/fluent-bit:2.2
# Add any additional dependencies if needed
RUN apt-get update && apt-get install -y --no-install-recommends ...

# Copy file cấu hình vào image
COPY fluent-bit.conf /fluent-bit/etc/fluent-bit.conf
COPY parsers.conf    /fluent-bit/etc/parsers.conf

# Expose the HTTP server port
EXPOSE 2020

# Default entry point remains unchanged
# ENTRYPOINT ["/fluent-bit/bin/fluent-bit"]

# Default command with our config
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
