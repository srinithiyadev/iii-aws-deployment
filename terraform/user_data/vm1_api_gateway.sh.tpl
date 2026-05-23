#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/vm1-setup.log | logger -t vm1-setup) 2>&1

echo "=== VM1: API Gateway setup starting ==="

yum update -y
yum install -y docker git wget tar

systemctl start docker
systemctl enable docker

III_VERSION="${iii_version}"
III_ARCHIVE="iii-x86_64-unknown-linux-musl.tar.gz"

cd /tmp
wget "https://github.com/iii-hq/iii/releases/download/$${III_VERSION}/$${III_ARCHIVE}"
tar -xzf "$${III_ARCHIVE}"
mv iii /usr/local/bin/iii
chmod +x /usr/local/bin/iii

git clone https://github.com/srinithiyadev/iii-aws-deployment.git /app
cd /app
mkdir -p /app/data

cat > /app/config.yaml << 'CONFIGEOF'
workers:
  - name: iii-observability
    config:
      enabled: true
      service_name: iii
      exporter: memory
      memory_max_spans: 10000
      metrics_enabled: true
      metrics_exporter: memory
      logs_enabled: true
      logs_exporter: memory
      logs_console_output: true
      sampling_ratio: 1.0
  - name: iii-queue
    config:
      adapter:
        name: builtin
  - name: iii-state
    config:
      adapter:
        name: kv
        config:
          store_method: file_based
          file_path: ./data/state_store.db
  - name: iii-http
    config:
      port: 3111
      host: 0.0.0.0
      default_timeout: 30000
      concurrency_request_limit: 1024
      cors:
        allowed_origins:
          - '*'
        allowed_methods:
          - GET
          - POST
          - PUT
          - DELETE
          - OPTIONS
CONFIGEOF

cat > /etc/systemd/system/iii-engine.service << 'SVCEOF'
[Unit]
Description=iii Engine
After=network.target

[Service]
WorkingDirectory=/app
ExecStart=/usr/local/bin/iii engine
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable iii-engine
systemctl start iii-engine

echo "=== VM1: API Gateway setup complete ==="
