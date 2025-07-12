# Custom Apache Pulsar image with auto topic/schema init
FROM apachepulsar/pulsar:3.2.0

# Cài thêm curl, jq nếu cần (tùy ý)
USER root
RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*
USER pulsar

# Copy script và schema avro vào image (hoặc mount từ ngoài cũng được)
COPY init-pulsar.sh /pulsar/init-pulsar.sh
COPY log-nginx-access.avsc /pulsar/schema/log-nginx-access.avsc

RUN chmod +x /pulsar/init-pulsar.sh

EXPOSE 6650 8080

# Dùng script custom thay cho CMD mặc định
CMD ["/pulsar/init-pulsar.sh"]
