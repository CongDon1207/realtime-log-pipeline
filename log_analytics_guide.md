# Log Analytics Realtime – Hướng Dẫn Tổng Quan

> **Mục tiêu:** Xây dựng hệ thống phân tích log web (Nginx) theo thời gian thực, phát hiện bất thường, lưu trữ lịch sử và trực quan hóa dữ liệu.

---

## 1. Phạm vi dự án

- **Nguồn dữ liệu**: Log HTTP từ Nginx (combined format).
- **Phân tích realtime**: Tính toán chỉ số cơ bản (requests/s, error rate), phát hiện anomaly.
- **Lưu trữ lịch sử**: Sử dụng **Apache Iceberg** làm table format, lưu dữ liệu và metrics trên **MinIO** (object store) với retention tối thiểu 90 ngày.
- **Trực quan**: Dashboard realtime & báo cáo dài hạn.

---

## 2. Tổng quan dự án

| Nội dung          | Mô tả                                                                                                           |
| ----------------- | --------------------------------------------------------------------------------------------------------------- |
| **Bài toán**      | Thu thập log HTTP liên tục, chuyển thành dữ liệu có cấu trúc, phân tích & cảnh báo tức thì.                     |
| **Ý nghĩa**       | ‣ Phát hiện sớm lỗi 4xx/5xx, brute‑force attack.‣ Theo dõi lưu lượng & tối ưu hạ tầng.‣ Báo cáo lịch sử cho BI. |
| **Mô hình xử lý** | Streaming (ngay lập tức) + Batch (truy vấn lịch sử).                                                            |
| **Yêu cầu chính** | - Cảnh báo trong < 1s.- Lưu trữ log tối thiểu 90 ngày.- Dashboard realtime & lịch sử dễ tùy biến.               |

---

## 3. Kiến trúc cấp cao

```
   Nginx ──► Fluent Bit ──► Pulsar ──► Flink (Streaming + CEP) ──► Apache Iceberg (table format)
                                                             stored on MinIO (object store)
                                        │                       │
                                        │                       ▼
                                        ▼                   Trino SQL ──► Superset (Dashboard lịch sử)
                               Prometheus Metrics ──► Grafana (Alert + Realtime)
```

**Luồng chính**

1. **Ingestion**: Fluent Bit tail log Nginx → JSON → topic Pulsar.
2. **Stream Processing**: Flink parse log → window metrics → CEP anomaly.
3. **Storage**: Sink xuống Iceberg trên MinIO.
4. **Realtime Monitoring**: Flink expose metrics → Prometheus → Grafana alert.
5. **BI Lịch sử**: Trino query Iceberg → Superset dashboard.

---

## 4. Cấu trúc thư mục gợi ý

```
log-analytics-flink/
├─ .env.example              # mẫu biến môi trường (PULSAR_SERVICE_URL, MINIO_ENDPOINT, FLINK_JOB_NAME...)
├─ compose/                  # Docker Compose configs
│  ├─ docker-compose.yml     # build & run services chung
│  └─ conf/                  # các file cấu hình dịch vụ
│     ├─ nginx/              # nginx.conf, vhost
│     ├─ fluent-bit/         # fluent-bit.conf
│     ├─ pulsar/             # standalone.conf
│     ├─ prometheus/         # prometheus.yml
│     ├─ grafana/            # provisioning
│     ├─ trino/               # catalog configs
│     └─ flink/              # flink-conf.yaml, sql-client.yaml
├─ scripts/                  # Flink job, log-generator, health-check, migration scripts
├─ docs/                     # tài liệu, sơ đồ
│  └─ architecture.drawio    # sơ đồ kiến trúc chi tiết
└─ README.md                 # hướng dẫn & tổng quan (file này)
```

---

## 5. Quy trình triển khai

**Tóm tắt 5 bước:**

1. Khởi tạo & chuẩn bị môi trường.
2. Cấu hình ingestion.
3. Triển khai stream processing.
4. Thiết lập monitoring & alert.
5. Thiết lập BI lịch sử & kiểm thử.

### 5.1. Bước 1: Khởi tạo & chuẩn bị

- Tạo repo, clone code.
- Sao chép `.env.example` → `.env` và điền biến thích hợp.
- Chuẩn bị Docker Compose: `docker-compose up -d`

### 5.2. Bước 2: Cấu hình ingestion

- Chỉnh `conf/fluent-bit/fluent-bit.conf` để tail `/var/log/nginx/access.log`.
- Định tuyến output đến `PULSAR_SERVICE_URL` (topic `logs/nginx/access`).

### 5.3. Bước 3: Triển khai Flink job

- Deploy job qua Flink CLI hoặc Web UI.
- Job đọc từ Pulsar, parse log, tính window (1m,5m), phát hiện anomaly.
- Thêm sink Iceberg & Prometheus metrics.

### 5.4. Bước 4: Monitoring & Alert

- Thêm data source Prometheus trong Grafana.
- Tạo dashboard realtime: req/s, error rate, anomaly flag.
- Định rule alert (4xx rate > 5% trong 5 phút) gửi Slack/Email.

### 5.5. Bước 5: BI lịch sử & kiểm thử

- Kết nối Trino → Iceberg (MinIO).
- Trong Superset, tạo dataset và các chart (Top URLs, heatmap thời gian).
- Sinh tải giả (ab, wrk); xác thực dashboard & alert hoạt động.

---

## 6. Stack chi tiết cần dùng

| Lớp               | Công cụ                                        | Lý do chọn                                                                                             |                                                |                        |
| ----------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------- | ---------------------- |
| Web Server        | Nginx                                          | Phổ biến, combined log format                                                                          |                                                |                        |
| Log Agent         | Fluent Bit                                     | Nhẹ, sidecar container, plugin output đa dạng                                                          |                                                |                        |
| Message Broker    | Apache Pulsar                                  | Tiered-storage, schema registry, dễ scale                                                              |                                                |                        |
| Stream Processing | Apache Flink 2.x                               | True stream, CEP, latency thấp                                                                         |                                                |                        |
| Table Format      | Apache Iceberg                                 | Định dạng bảng (table format) hỗ trợ time‑travel, schema evolution, lưu metadata trên Iceberg catalogs |                                                |                        |
| Object Store      | MinIO (dev) / S3 (prod)                        | Lưu trữ file Parquet, Iceberg data trên object storage (tương thích S3)                                |                                                |                        |
| DevOps            | Docker Compose (dev), Kubernetes + Helm (prod) | CI/CD & deploy tự động                                                                                 | Docker Compose (dev), Kubernetes + Helm (prod) | CI/CD & deploy tự động |

---

## 7. Kết luận & bước tiếp theo

Hoàn thành pipeline **Ingest → Stream Process → Store → Monitor → Alert → BI**, bạn có:

- Hệ thống giám sát log realtime.
- Cảnh báo sớm sự cố.
- Lưu trữ truy vấn lịch sử.

> **Đề xuất:** Chuẩn hoá CI/CD (GitHub Actions), viết hướng dẫn deploy K8s, thêm bảo mật TLS & auth.

