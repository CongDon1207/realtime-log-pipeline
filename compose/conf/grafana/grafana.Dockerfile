# Grafana Dockerfile for Realtime Log Pipeline
FROM grafana/grafana:latest

# Set timezone
ENV TZ=Asia/Ho_Chi_Minh

# Install additional plugins for enhanced visualization
RUN grafana-cli plugins install grafana-piechart-panel && \
    grafana-cli plugins install grafana-clock-panel && \
    grafana-cli plugins install flant-statusmap-panel

# Copy configuration files
COPY grafana.ini /etc/grafana/grafana.ini
COPY provisioning/ /etc/grafana/provisioning/

# Create directories and copy dashboards
USER root
RUN mkdir -p /var/lib/grafana/dashboards
COPY dashboards/ /var/lib/grafana/dashboards/

# Switch back to grafana user
USER grafana

# Expose Grafana port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1
