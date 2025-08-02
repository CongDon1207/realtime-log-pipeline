# Prometheus monitoring system
FROM prom/prometheus:latest

# Copy our custom configuration file
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Expose the Prometheus web UI and API port
EXPOSE 9090

# Default command with additional parameters
CMD ["--config.file=/etc/prometheus/prometheus.yml", \
     "--storage.tsdb.path=/prometheus", \
     "--web.console.libraries=/etc/prometheus/console_libraries", \
     "--web.console.templates=/etc/prometheus/consoles", \
     "--web.enable-lifecycle"]
