#!/usr/bin/env python3

import http.server
import socketserver
import json
import urllib.parse
from datetime import datetime

class LogReceiver(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            # Parse JSON data from Fluent Bit
            data = json.loads(post_data.decode('utf-8'))
            timestamp = datetime.now().isoformat()
            
            print(f"[{timestamp}] Received log data:")
            print(json.dumps(data, indent=2))
            
            # Send success response
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            response = {"status": "success", "received_at": timestamp}
            self.wfile.write(json.dumps(response).encode())
            
        except Exception as e:
            print(f"Error processing request: {e}")
            self.send_response(400)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            response = {"status": "error", "message": str(e)}
            self.wfile.write(json.dumps(response).encode())
    
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        response = {"status": "ok", "message": "Log receiver is running"}
        self.wfile.write(json.dumps(response).encode())

if __name__ == "__main__":
    PORT = 3001
    
    with socketserver.TCPServer(("", PORT), LogReceiver) as httpd:
        print(f"Log receiver server running on port {PORT}")
        print("Waiting for log data from Fluent Bit...")
        httpd.serve_forever()
