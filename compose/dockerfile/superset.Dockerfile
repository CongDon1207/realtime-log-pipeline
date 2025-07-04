# Apache Superset for data visualization and BI
FROM apache/superset:latest

# Install additional database drivers and dependencies
USER root
RUN pip install --no-cache-dir \
    trino \
    psycopg2-binary \
    sqlalchemy-trino

# Switch back to the superset user
USER superset

# Environment variables will be set in docker-compose.yml
# ENV SUPERSET_SECRET_KEY=your_secret_key_here

# Expose the Superset web UI port
EXPOSE 8088

# The default command is sufficient and will be used
