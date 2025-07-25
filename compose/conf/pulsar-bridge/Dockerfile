FROM python:3.9-slim

WORKDIR /app

# Install dependencies
RUN pip install pulsar-client==2.8.4

# Copy bridge script
COPY pulsar-bridge.py .

# Make script executable
RUN chmod +x pulsar-bridge.py

EXPOSE 3001

CMD ["python", "pulsar-bridge.py"]
