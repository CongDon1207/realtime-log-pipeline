#!/usr/bin/env python3
"""
HTTP-to-Pulsar Bridge
Nhận dữ liệu từ Fluent Bit qua HTTP và gửi vào Apache Pulsar
"""

import json
import logging
import time
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
import pulsar
import threading

# Configuration
HTTP_PORT = 3001
PULSAR_URL = "pulsar://pulsar:6650"
PULSAR_TOPIC = "persistent://public/default/nginx-logs"

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)

class PulsarProducer:
    def __init__(self):
        self.client = None
        self.producer = None
        self.connect()
    
    def connect(self):
        """Kết nối đến Pulsar và tạo producer"""
        try:
            self.client = pulsar.Client(PULSAR_URL)
            # Use default producer without explicit schema to avoid schema_class issues
            self.producer = self.client.create_producer(PULSAR_TOPIC)
            logger.info(f"Connected to Pulsar topic: {PULSAR_TOPIC}")
        except Exception as e:
            logger.error(f"Failed to connect to Pulsar: {e}")
            # Retry connection sau 5 giây
            threading.Timer(5.0, self.connect).start()
    
    def send_message(self, message):
        """Gửi message vào Pulsar"""
        try:
            if self.producer:
                # Convert dict to JSON string and encode as bytes
                if isinstance(message, dict):
                    message_bytes = json.dumps(message).encode('utf-8')
                else:
                    message_bytes = str(message).encode('utf-8')
                
                self.producer.send(message_bytes)
                logger.debug(f"Sent message to Pulsar: {message}")
                return True
            else:
                logger.warning("Producer not available, reconnecting...")
                self.connect()
                return False
        except Exception as e:
            logger.error(f"Failed to send message to Pulsar: {e}")
            return False
    
    def close(self):
        """Đóng kết nối"""
        if self.producer:
            self.producer.close()
        if self.client:
            self.client.close()

class LogHandler(BaseHTTPRequestHandler):
    def __init__(self, *args, pulsar_producer=None, **kwargs):
        self.pulsar_producer = pulsar_producer
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Health check endpoint"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {
            "status": "ok",
            "message": "Pulsar bridge is running",
            "timestamp": datetime.now().isoformat()
        }
        self.wfile.write(json.dumps(response).encode())
    
    def do_POST(self):
        """Nhận log data từ Fluent Bit"""
        try:
            # Đọc dữ liệu từ request
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            # Parse JSON data
            log_data = json.loads(post_data.decode('utf-8'))
            
            logger.info(f"Received {len(log_data)} log entries from Fluent Bit")
            
            # Gửi từng log entry vào Pulsar
            success_count = 0
            for log_entry in log_data:
                # Thêm metadata
                enriched_log = {
                    **log_entry,
                    "processed_at": datetime.now().isoformat(),
                    "source": "fluent-bit-nginx"
                }
                
                if self.pulsar_producer.send_message(enriched_log):
                    success_count += 1
            
            # Response
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            response = {
                "status": "success",
                "received": len(log_data),
                "sent_to_pulsar": success_count,
                "timestamp": datetime.now().isoformat()
            }
            self.wfile.write(json.dumps(response).encode())
            
            logger.info(f"Successfully processed {success_count}/{len(log_data)} log entries")
            
        except Exception as e:
            logger.error(f"Error processing request: {e}")
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            error_response = {
                "status": "error",
                "message": str(e),
                "timestamp": datetime.now().isoformat()
            }
            self.wfile.write(json.dumps(error_response).encode())
    
    def log_message(self, format, *args):
        """Override để tắt access log của HTTP server"""
        pass

def create_handler(pulsar_producer):
    """Factory function để tạo handler với pulsar_producer"""
    def handler(*args, **kwargs):
        return LogHandler(*args, pulsar_producer=pulsar_producer, **kwargs)
    return handler

def main():
    """Main function"""
    logger.info("Starting HTTP-to-Pulsar Bridge...")
    
    # Tạo Pulsar producer
    pulsar_producer = PulsarProducer()
    
    # Tạo HTTP server
    handler = create_handler(pulsar_producer)
    server = HTTPServer(('0.0.0.0', HTTP_PORT), handler)
    
    logger.info(f"HTTP server listening on port {HTTP_PORT}")
    logger.info(f"Pulsar topic: {PULSAR_TOPIC}")
    logger.info("Bridge is ready to receive logs from Fluent Bit")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down bridge...")
        pulsar_producer.close()
        server.shutdown()
        logger.info("Bridge stopped")

if __name__ == "__main__":
    main()
