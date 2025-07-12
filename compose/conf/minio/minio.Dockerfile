# MinIO Object Storage
FROM minio/minio:latest

# Environment variables for MinIO will be set in docker-compose.yml
# ENV MINIO_ROOT_USER=minioadmin
# ENV MINIO_ROOT_PASSWORD=minioadmin

# Expose API and Console ports
EXPOSE 9000 9001

# MinIO server startup command
# This will be overridden in docker-compose.yml
ENTRYPOINT ["minio"]
CMD ["server", "/data", "--console-address", ":9001"]
