#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/vm2-setup.log | logger -t vm2-setup) 2>&1

echo "=== VM2: Caller Worker setup starting ==="

yum update -y
yum install -y docker git nc

systemctl start docker
systemctl enable docker

ENGINE_IP="${engine_private_ip}"
echo "Waiting for iii engine at $ENGINE_IP:49134 ..."
for i in $(seq 1 30); do
  if nc -z "$ENGINE_IP" 49134 2>/dev/null; then
    echo "Engine is up!"
    break
  fi
  echo "Attempt $i/30 — retrying in 10s..."
  sleep 10
done

git clone ${repo_url} /app
cd /app

docker build -t caller-worker:latest ./workers/caller-worker

cat > /etc/systemd/system/caller-worker.service << SVCEOF
[Unit]
Description=Caller Worker (TypeScript)
After=docker.service network.target
Requires=docker.service

[Service]
Restart=always
RestartSec=10
ExecStartPre=-/usr/bin/docker stop caller-worker
ExecStartPre=-/usr/bin/docker rm caller-worker
ExecStart=/usr/bin/docker run --name caller-worker \
  --env III_URL=ws://${engine_private_ip}:49134 \
  caller-worker:latest
ExecStop=/usr/bin/docker stop caller-worker
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable caller-worker
systemctl start caller-worker

echo "=== VM2: Caller Worker setup complete ==="
