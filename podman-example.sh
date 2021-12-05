#!/bin/bash
function fail_out() {
  podman pod stop dohot
  podman pod rm dohot
  podman network rm dohot
  echo $1
  exit 1
}
function success_out() {
  echo $1
  exit 0
}
podman build --pull-always -t localhost/dohproxy -f dnscrypt-proxy/Dockerfile || fail_out "Unable to build dohproxy"
podman build --pull-always -t localhost/torproxy -f torproxy/Dockerfile || fail_out "Unable to build torproxy"
podman pull docker.io/pihole/pihole || fail_out "Unable to pull pihole"
podman pod exists dohot && success_out "Done"
if [[ $? -eq 1 ]]; then
  if [[ $# -ne 1 ]]; then
    fail_out "Usage: ${0} <Your IP>"
  else
    echo "Will bind DNS and web to $1"
  fi
  podman network exists dohot || podman network create dohot --subnet 10.69.0.0/29 || fail_out "Unable to create network"
  podman volume exists dohot-var-lib-tor || podman volume create dohot-var-lib-tor || fail_out "Unable to create volume"
  podman volume exists dohot-etc-dnsmasqd || podman volume create dohot-etc-dnsmasqd || fail_out "Unable to create volume"
  podman volume exists dohot-etc-pihole || podman volume create dohot-etc-pihole || fail_out "Unable to create volume"
  podman pod create --name dohot || fail_out "Unable to create pod"
  podman run --rm --name dohot-torproxy \
	  --pod dohot \
	  --network dohot \
	  --ip 10.69.0.4 \
	  -v dohot-var-lib-tor:/var/lib/tor \
	  -d localhost/torproxy || fail_out "Unable to run torproxy"
  podman run --rm --name dohot-dohproxy \
	  --pod dohot \
	  --network dohot \
	  --ip 10.69.0.2 \
	  -d localhost/dohproxy || fail_out "Unable to run dohproxy"
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
	  -d docker.io/pihole/pihole || fail_out "Unable to run pihole"
  # generate systemd service files, install and enable them.
  cd /etc/systemd/system/
  podman generate systemd --new --name --files dohot && systemctl daemon-reload && systemctl enable --now pod-dohot.service || fail_out "Failed to create and enable pod management service."
  success_out "Done"
fi
