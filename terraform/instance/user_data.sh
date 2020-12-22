#!/usr/bin/env bash

set -o pipefail -o errexit -o nounset

export DEBIAN_FRONTEND=noninteractive

echo "${ssh_identity_ecdsa_key}" | base64 -d > /etc/ssh/ssh_host_ecdsa_key
chmod 600 /etc/ssh/ssh_host_ecdsa_key
echo "${ssh_identity_ecdsa_pub}" | base64 -d > /etc/ssh/ssh_host_ecdsa_key.pub

echo "${ssh_identity_rsa_key}" | base64 -d > /etc/ssh/ssh_host_rsa_key
chmod 600 /etc/ssh/ssh_host_rsa_key.pub
echo "${ssh_identity_rsa_pub}" | base64 -d > /etc/ssh/ssh_host_rsa_key.pub

echo "${ssh_identity_ed25519_key}" | base64 -d > /etc/ssh/ssh_host_ed25519_key
chmod 600 /etc/ssh/ssh_host_ed25519_key.pub
echo "${ssh_identity_ed25519_pub}" | base64 -d > /etc/ssh/ssh_host_ed25519_key.pub

function docker_login {
  echo "${github_token}" | docker login https://docker.pkg.github.com -u ${github_owner} --password-stdin
}

function mount_storage {
    echo "${storage_device} /storage   ext4   defaults  0 0" >> /etc/fstab
    mkdir -p "/storage"
    mount "/storage"
}

function configure_public_ip {
    ip addr add ${public_ip} dev eth0
}

function update_system {
    apt-get update

    apt-get \
        -o Dpkg::Options::="--force-confnew" \
        --force-yes \
        -fuy \
        dist-upgrade
}

function install_prerequisites {
  apt-get install --no-install-recommends -qq -y \
    docker.io \
    docker-compose \
    gnupg2 \
    pass \
    ufw
}

function configure_ufw {
  ufw enable
  ufw allow ssh
  ufw allow http
  ufw allow https
}

function docker_systemd_config {
cat <<-EOF
[Unit]
Description=%i service with docker compose
Requires=docker.service
After=docker.service

[Service]
Restart=always
TimeoutStartSec=1200

WorkingDirectory=/opt/dockerfiles/%i

# Remove old containers, images and volumes and update it
ExecStartPre=/usr/bin/docker-compose down -v
ExecStartPre=/usr/bin/docker-compose rm -fv
ExecStartPre=/usr/bin/docker-compose pull

# Compose up
ExecStart=/usr/bin/docker-compose up

# Compose down, remove containers and volumes
ExecStop=/usr/bin/docker-compose down -v

[Install]
WantedBy=multi-user.target
EOF
}

function docker_compose_config {
cat <<-EOF
version: "3"
services:
  www:
    image: docker.pkg.github.com/pellepelster/pelle.io-infrastructure/www:latest
    environment:
      - "HOSTNAME=${hostname}"
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - "/storage/www:/storage"
EOF
}

mount_storage
configure_public_ip
update_system
install_prerequisites
configure_ufw
docker_login

docker_systemd_config > /etc/systemd/system/docker-compose@.service
mkdir -p /opt/dockerfiles/www
docker_compose_config > /opt/dockerfiles/www/docker-compose.yml

mkdir -p /storage/www/ssl/default
mkdir -p /storage/www/logs
mkdir -p /storage/www/html

echo "${certificate}" | base64 -d > /storage/www/ssl/default/certificate.pem
echo "${private_key}" | base64 -d > /storage/www/ssl/default/private_key.pem

systemctl daemon-reload
systemctl enable docker-compose@www
systemctl start docker-compose@www