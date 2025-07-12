# Custom Apache Pulsar image with auto topic/schema init
FROM apachepulsar/pulsar:3.2.0

# Cài thêm curl, jq nếu cần (tùy ý)
USER root
RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*

# Tạo thư mục schema
RUN mkdir -p /pulsar/schema

# Copy files và set permissions ngay lập tức
COPY --chmod=755 init-pulsar.sh /pulsar/init-pulsar.sh
COPY --chmod=644 log-nginx-access.avsc /pulsar/schema/log-nginx-access.avsc

USER pulsar

EXPOSE 6650 8080

# Dùng script custom thay cho CMD mặc định
CMD ["/pulsar/init-pulsar.sh"]
