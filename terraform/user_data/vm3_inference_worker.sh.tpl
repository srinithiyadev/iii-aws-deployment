#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/vm3-setup.log | logger -t vm3-setup) 2>&1

echo "=== VM3: Inference Worker setup starting ==="

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

docker build -t inference-worker:latest ./workers/inference-worker

cat > /etc/systemd/system/inference-worker.service << SVCEOF
[Unit]
Description=Inference Worker (Python + Gemma)
After=docker.service network.target
Requires=docker.service

[Service]
Restart=always
RestartSec=10
TimeoutStartSec=300
ExecStartPre=-/usr/bin/docker stop inference-worker
ExecStartPre=-/usr/bin/docker rm inference-worker
ExecStart=/usr/bin/docker run --name inference-worker \
  --env III_URL=ws://${engine_private_ip}:49134 \
  --memory=8g \
  --cpus=4 \
  inference-worker:latest
ExecStop=/usr/bin/docker stop inference-worker
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable inference-worker
systemctl start inference-worker

echo "=== VM3: Inference Worker setup complete ==="
