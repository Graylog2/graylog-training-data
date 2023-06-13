#!/bin/bash

wget https://github.com/traefik/traefik/releases/download/v2.10.1/traefik_v2.10.1_linux_amd64.tar.gz
tar -xzvf traefik_v2.10.1_linux_amd64.tar.gz
chmod +x traefik_v2.10.1_linux_amd64.tar.gz
mv traefik /usr/local/bin/traefik
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/traefik
sudo groupadd -g 321 traefik
sudo useradd \
  -g traefik --no-user-group \
  --home-dir /var/www --no-create-home \
  --shell /usr/sbin/nologin \
  --system --uid 321 traefik
sudo mkdir /etc/traefik
sudo mkdir /etc/traefik/acme
## copy traefik.toml once created
sudo cp /path/to/traefik.toml /etc/traefik

sudo chown -R root:root /etc/traefik
sudo chown -R traefik:traefik /etc/traefik/acme
sudo chown root:root /etc/traefik/traefik.toml
sudo chmod 644 /etc/traefik/traefik.toml

## copy traefik service file once created
sudo cp /path/to/traefik.service /etc/systemd/system/

sudo chown root:root /etc/systemd/system/traefik.service
sudo chmod 644 /etc/systemd/system/traefik.service
sudo systemctl daemon-reload
sudo systemctl start traefik.service
sudo systemctl enable traefik.service

