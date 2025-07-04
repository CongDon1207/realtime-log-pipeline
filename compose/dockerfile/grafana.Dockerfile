# Grafana for dashboards and alerting
FROM grafana/grafana:latest

# Install any additional Grafana plugins
# Example: installing Prometheus data source and pie chart panel
RUN grafana-cli plugins install grafana-piechart-panel

# Environment variables can be set in docker-compose.yml
# ENV GF_SECURITY_ADMIN_USER=admin
# ENV GF_SECURITY_ADMIN_PASSWORD=admin

# Our custom configuration will be mounted from the host
# COPY ./provisioning /etc/grafana/provisioning

# Expose the Grafana web UI port
EXPOSE 3000

# The default command is sufficient and will be used
