
# Kế hoạch Triển khai Hệ thống **Realtime‐Log‐Pipeline**
> Tài liệu này mô tả **quy trình từng bước**, kèm **điểm kiểm tra (checkpoint)** rõ ràng để triển khai
pipeline phân tích log Nginx theo thời gian thực.  
Nếu một bước **kiểm tra không đạt**, DỪNG lại khắc phục trước khi đi tiếp.

---

## Mục lục
1. [Chuẩn bị môi trường](#1-chuẩn-bị-môi-trường)
2. [Khởi chạy nền tảng (Docker Compose)](#2-khởi-chạy-nền-tảng-docker-compose)
3. [Cấu hình & Kiểm tra **Fluent Bit**](#3-cấu-hình--kiểm-tra-fluent-bit)
4. [Cấu hình & Kiểm tra **Apache Pulsar**](#4-cấu-hình--kiểm-tra-apache-pulsar)
5. [Cấu hình & Kiểm tra **Apache Flink**](#5-cấu-hình--kiểm-tra-apache-flink)
6. [Thiết lập Lưu trữ **Iceberg + MinIO**](#6-thiết-lập-lưu-trữ-iceberg--minio)
7. [Thiết lập Giám sát **Prometheus + Grafana**](#7-thiết-lập-giám-sát-prometheus--grafana)
8. [Tầng BI: **Trino + Superset**](#8-tầng-bi-trino--superset)
9. [Kiểm thử đầu cuối (E2E)](#9-kiểm-thử-đầu-cuối-e2e)
10. [CI/CD & mở rộng](#10-cicd--mở-rộng)

---

## 1. Chuẩn bị môi trường
| Thành phần | Yêu cầu tối thiểu |
|------------|------------------|
| OS         | Linux x86_64 / macOS / WSL2 |
| Docker     | **24.0** trở lên |
| Docker Compose | plugin v2 (`docker compose version`) |
| RAM        | 8 GiB (dev); 16 GiB khuyến nghị |
| Disk       | 20 GiB trống |

```bash
# 1.1 Clone repository
git clone https://github.com/CongDon1207/realtime-log-pipeline.git
cd realtime-log-pipeline

# 1.2 Tạo file môi trường
cp .env.example .env
# → Điền các biến MINIO_ENDPOINT, PULSAR_SERVICE_URL, ...
```

**Checkpoint 1**  
- `docker compose version` trả về v2.<br>
- File `.env` tồn tại và KHÔNG có dòng `TODO`.

---

## 2. Khởi chạy nền tảng (Docker Compose)

```bash
docker compose -f compose/docker-compose.yml pull   # tải image
docker compose -f compose/docker-compose.yml up -d
docker compose ls                                   # liệt kê stack
```

### Cổng dịch vụ (mặc định)

| Dịch vụ | URL | Ghi chú |
|---------|-----|---------|
| MinIO Console | http://localhost:9001 | user: *minioadmin* / pass: *minioadmin* |
| Pulsar Admin  | http://localhost:8080 | standalone mode |
| Flink UI      | http://localhost:8081 | quản lý job |
| Prometheus    | http://localhost:9090 | query metrics |
| Grafana       | http://localhost:3000 | user/pass: *admin* / *admin* |
| Superset      | http://localhost:8088 | user/pass: *admin* / *admin* |
| Trino CLI     | `docker exec -it trino trino` | trong container |

**Checkpoint 2**  
Thực thi:
```bash
docker compose ps
```
Tất cả container có trạng thái **Up** >= 30 s.

---

## 3. Cấu hình & Kiểm tra **Fluent Bit**

### 3.1 Cấu hình
File: `compose/fluent-bit/fluent-bit.conf`

```ini
[SERVICE]
    Parsers_File parsers.conf

[INPUT]
    Name        tail
    Path        /var/log/nginx/access.log
    Tag         nginx.access
    DB          /flb_state.db
    Refresh_Interval 5
    Mem_Buf_Limit 10MB

[FILTER]
    Name        record_modifier
    Match       nginx.*
    Record      hostname ${HOSTNAME}

[OUTPUT]
    Name        pulsar
    Match       *
    Pulsar_Broker       pulsar://pulsar:6650
    Pulsar_Topic        persistent://public/default/logs-nginx-access
    Pulsar_Compression  zstd
```

### 3.2 Khởi động agent

```bash
docker compose up -d fluent-bit
```

### 3.3 Kiểm tra

```bash
# Liệt kê offset & tail thử
docker compose logs --tail=20 fluent-bit

# Dùng pulsar-client (trong container pulsar)
docker exec -it pulsar bin/pulsar-client consume \
  -s testsub -n 5 persistent://public/default/logs-nginx-access
```

**Checkpoint 3**  
- Lệnh `consume` hiển thị ≥ 1 bản ghi JSON hợp lệ.  
- Trường `hostname` được chèn đúng.

---

## 4. Cấu hình & Kiểm tra **Apache Pulsar**

### 4.1 Tạo schema (Avro)

```bash
# schema/log-nginx-access.avsc
{
  "type":"record",
  "name":"NginxAccess",
  "fields":[
    {"name":"remote_addr","type":"string"},
    {"name":"time_iso8601","type":"string"},
    {"name":"request","type":"string"},
    {"name":"status","type":"int"},
    {"name":"body_bytes_sent","type":"long"},
    {"name":"http_referer","type":["null","string"],"default":null},
    {"name":"http_user_agent","type":["null","string"],"default":null},
    {"name":"hostname","type":"string"}
  ]
}
```

```bash
# Đăng ký schema
docker exec pulsar bin/pulsar-admin schemas upload \
  persistent://public/default/logs-nginx-access \
  -f /pulsar/schema/log-nginx-access.avsc
```

### 4.2 Kiểm tra

```bash
docker exec pulsar bin/pulsar-admin schemas get \
  persistent://public/default/logs-nginx-access
```

**Checkpoint 4**  
Schema được trả về & trùng nội dung file Avro.

---

## 5. Cấu hình & Kiểm tra **Apache Flink**

### 5.1 Chuẩn bị JAR
```bash
cd flink-job
mvn clean package -DskipTests
```
Kết quả: `target/log-analytics-job.jar`.

### 5.2 Deploy Job
```bash
docker cp target/log-analytics-job.jar flink-jobmanager:/opt/flink/usrlib/
docker exec flink-jobmanager flink run -d /opt/flink/usrlib/log-analytics-job.jar \
  --pulsar-topic logs-nginx-access \
  --sink-table iceberg.db.nginx_access
```

### 5.3 Kiểm tra
- Truy cập **Flink UI** → tab *Jobs* trạng thái **RUNNING**.  
- Metrics Prometheus: `flink_taskmanager_job_task_numRecordsIn` tăng.

**Checkpoint 5**  
Flink job chạy ≥ 2 phút, không *Restarting*, metrics tăng đều.

---

## 6. Thiết lập Lưu trữ **Iceberg + MinIO**

### 6.1 Tạo bucket
```bash
mc alias set local http://localhost:9000 minioadmin minioadmin
mc mb local/log-warehouse
```

### 6.2 Cấu hình catalog Trino
File: `compose/trino/catalog/iceberg.properties`
```properties
connector.name=iceberg
warehouse=s3a://log-warehouse
format-version=2
s3.endpoint=http://minio:9000
s3.path-style-access=true
s3.aws-access-key=minioadmin
s3.aws-secret-key=minioadmin
```

Khởi động lại container **trino**.

### 6.3 Kiểm tra
```bash
docker exec -it trino trino
trino> SHOW SCHEMAS FROM iceberg;
```

**Checkpoint 6**  
Schema `db` xuất hiện, lệnh `SELECT count(*) FROM iceberg.db.nginx_access;` trả về số bản ghi > 0.

---

## 7. Thiết lập Giám sát **Prometheus + Grafana**

### 7.1 Prometheus
- Mở `compose/prometheus/prometheus.yml`, đảm bảo job `flink`, `pulsar`, `node` đã có.

### 7.2 Grafana
1. Đăng nhập `http://localhost:3000` (admin/admin).  
2. Add **Prometheus** datasource (`http://prometheus:9090`).  
3. Import dashboard mẫu `docs/grafana_flink.json`.  
4. Tạo alert rule Error Rate > 1%.

### 7.3 Kiểm tra
- Dashboard hiển thị số liệu, biểu đồ không lỗi **N/A**.  
- Thay đổi ngưỡng để trigger alert test.

**Checkpoint 7**  
Alert test gửi email/webhook thành công hoặc chuyển sang trạng thái **Alerting** trong Grafana.

---

## 8. Tầng BI: **Trino + Superset**

### 8.1 Kết nối Trino
Trong Superset → *Settings → Database Connections*  
- SQLAlchemy URI: `trino://trino@trino:8080/iceberg/db`

### 8.2 Tạo dataset & chart
1. Dataset: bảng `nginx_access`.  
2. Chart: *Sunburst* "Top URLs" (`request` dimension).  
3. Dashboard: “Web Traffic Realtime”.

### 8.3 Kiểm tra
- `Run` chart trả về số liệu.  
- Dashboard auto‑refresh 10 s.

**Checkpoint 8**  
Dashboard hiển thị biểu đồ có dữ liệu & không lỗi SQL.

---

## 9. Kiểm thử đầu cuối (E2E)

```bash
# Sinh log giả lập
docker compose exec log-generator python generate_nginx_log.py --rate 50
```
Quan sát:
- Fluent Bit throughput > 45 msg/s.
- Flink latency  p99 < 2 s (Flink UI → *Backpressure*).

**Checkpoint 9**  
`SELECT max(time_lag) FROM iceberg.db.nginx_access_lag_view;` < 2 000 ms.

---

## 10. CI/CD & mở rộng

| Nội dung | Việc làm |
|----------|----------|
| **GitHub Actions** | Tạo workflow build JAR, build/push image Docker, scan Trivy. |
| **Kubernetes** | Viết Helm chart cho mỗi thành phần; tích hợp *KEDA* autoscale FlinkOnK8s. |
| **Bảo mật** | Enable SSL/TLS, IAM MinIO, token‑auth Pulsar. |
| **Nhật ký khác** | Mở rộng parser cho Apache, IIS. |
| **Test** | Viết unit‐test CEP rule, e2e GitHub Action daily. |

---

## Hoàn tất
Khi **Checkpoint 1 → 9** đều đạt, hệ thống sẵn sàng cho môi trường staging/production.
