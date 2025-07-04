# Nginx with custom configuration
FROM nginx:alpine

# Install additional packages if needed
RUN apk add --no-cache curl ca-certificates

# Custom configuration will be mounted from host
# COPY nginx.conf /etc/nginx/nginx.conf

# Create directory for logs
RUN mkdir -p /var/log/nginx

# Expose ports
EXPOSE 80 443

# Default command
CMD ["nginx", "-g", "daemon off;"]
