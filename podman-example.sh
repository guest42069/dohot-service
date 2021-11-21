#!/bin/bash
if [[ $# -ne 1 ]]; then
  echo "No IP provided..."
  exit 1
else
  echo "Will bind DNS and web to $1"
fi
podman image exists localhost/dohproxy
if [[ $? -eq 1 ]]; then
  podman build -t localhost/dohproxy -f dnscrypt-proxy/Dockerfile
fi
podman image exists localhost/torproxy
if [[ $? -eq 1 ]]; then
  podman build -t localhost/torproxy -f torproxy/Dockerfile
fi
podman image exists docker.io/pihole/pihole
if [[ $? -eq 1 ]]; then
  podman pull docker.io/pihole/pihole
fi
podman network exists dohot
if [[ $? -eq 1 ]]; then
  podman network create dohot --subnet 10.69.0.0/29
fi
podman pod exists dohot
if [[ $? -eq 1 ]]; then
  podman pod create --name dohot --network dohot
  podman volume exists dohot-var-lib-tor
  if [[ $? -eq 1 ]]; then
    podman volume create dohot-var-lib-tor
  fi
  podman volume exists dohot-etc-dnsmasqd
  if [[ $? -eq 1 ]]; then
    podman volume create dohot-etc-dnsmasqd
  fi
  podman volume exists dohot-etc-pihole
  if [[ $? -eq 1 ]]; then
    podman volume create dohot-etc-pihole
  fi
  podman run --rm --name dohot-torproxy \
	  --pod dohot \
	  --network dohot \
	  --ip 10.69.0.4 \
	  -v dohot-var-lib-tor:/var/lib/tor \
	  -d localhost/torproxy
  podman run --rm --name dohot-dohproxy \
	  --pod dohot \
	  --network dohot \
	  --ip 10.69.0.2 \
	  -d localhost/dohproxy
  # binding to privileged ports.
  podman run --rm --name dohot-pihole \
	  --pod dohot \
	  --network dohot \
	  -p "$1":53:53/udp \
	  -p "$1":53:53/tcp \
	  -p "$1":80:80/tcp \
	  --ip 10.69.0.3 \
	  -e 'ServerIP=10.69.0.3' \
	  -e 'PIHOLE_DNS_=10.69.0.2#5054' \
	  -e 'TZ=Europe/London' \
	  -v dohot-etc-dnsmasqd:/etc/dnsmasq.d/ \
	  -v dohot-etc-pihole:/etc/pihole \
	  -d docker.io/pihole/pihole
  # generate systemd service files, install and enable them.
  cd `mktemp -d`
  podman generate systemd --new --name --files dohot
  mv *.service /etc/systemd/system/
  systemctl enable --now pod-dohot.service
fi
