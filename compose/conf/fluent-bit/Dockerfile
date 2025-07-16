# Fluent Bit with custom configuration
### Stage 1: build Pulsar output plugin from source
FROM golang:1.22 AS builder

WORKDIR /src
RUN git clone --depth 1 https://github.com/transnano/fluent-bit-go-pulsar-output . \
    && go build -buildmode=c-shared -o out_pulsar.so .

### Stage 2: final Fluent Bit image
FROM fluent/fluent-bit:2.2

COPY --from=builder /src/out_pulsar.so /fluent-bit/out_pulsar.so



# Copy file cấu hình vào image
COPY fluent-bit.conf /fluent-bit/etc/fluent-bit.conf
COPY parsers.conf    /fluent-bit/etc/parsers.conf

# Expose the HTTP server port
EXPOSE 2020

# Default entry point remains unchanged
# ENTRYPOINT ["/fluent-bit/bin/fluent-bit"]

# Default command with our config
CMD ["/fluent-bit/bin/fluent-bit", "-e", "/fluent-bit/out_pulsar.so", "-c", "/fluent-bit/etc/fluent-bit.conf"]
