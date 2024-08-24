#!/bin/bash

# Docker 설치를 위한 필수 패키지 업데이트 및 설치
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker 공식 GPG 키 추가
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker 저장소 설정
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 설치
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker 서비스 시작 및 활성화
sudo systemctl start docker
sudo systemctl enable docker

# 일반 사용자에게 Docker 권한 부여
sudo groupadd docker
sudo usermod -aG docker $USER

# 권한 변경 적용을 위해 newgrp 명령어 실행
newgrp docker

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Node Exporter 설치
ARCH=$(uname -m)

if [ "$ARCH" == "x86_64" ]; then
    NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz"
elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ]; then
    NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-arm64.tar.gz"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Node Exporter 다운로드 및 설치
curl -LO $NODE_EXPORTER_URL
tar xvf node_exporter-*.tar.gz
sudo mv node_exporter-*/node_exporter /usr/local/bin/
rm -rf node_exporter-*

# Node Exporter 서비스 등록
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=default.target
EOF

# 서비스 리로드 및 시작
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter


# 전체 포트 오픈 (어쩌피 vnc에서 포트를 열고 닫음)
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -F
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
sudo systemctl disable ufw


# Docker 및 Docker Compose 버전 확인
docker --version
docker-compose --version
sudo systemctl status node_exporter