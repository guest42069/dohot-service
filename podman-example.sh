#!/bin/bash
function fail_out() {
  podman pod stop dohot
  podman pod rm dohot
  echo $1
  exit 1
}
function success_out() {
  echo $1
  exit 0
}
podman pull ghcr.io/guest42069/dohproxy:latest || fail_out "Unable to pull dohproxy"
podman pull ghcr.io/guest42069/torproxy:latest || fail_out "Unable to pull torproxy"
podman pull docker.io/pihole/pihole:latest || fail_out "Unable to pull pihole"
podman pod exists dohot && success_out "Done"
if [[ $? -eq 1 ]]; then
  if [[ $# -ne 1 ]]; then
    fail_out "Usage: ${0} <Your IP>"
  else
    echo "Will bind DNS and web to $1"
  fi
  podman volume exists dohot-var-lib-tor || podman volume create dohot-var-lib-tor || fail_out "Unable to create volume"
  podman volume exists dohot-etc-dnsmasqd || podman volume create dohot-etc-dnsmasqd || fail_out "Unable to create volume"
  podman volume exists dohot-etc-pihole || podman volume create dohot-etc-pihole || fail_out "Unable to create volume"
  podman pod create --name dohot -p ${1}:53:53/udp -p ${1}:53:53/tcp -p ${1}:80:80/tcp || fail_out "Unable to create pod"
  podman run --rm --name dohot-torproxy \
    --label "io.containers.autoupdate=registry" \
    --pod dohot \
    -v dohot-var-lib-tor:/var/lib/tor \
    -d ghcr.io/guest42069/torproxy:latest || fail_out "Unable to run torproxy"
  podman run --rm --name dohot-dohproxy \
    --label "io.containers.autoupdate=registry" \
    --pod dohot \
    -d ghcr.io/guest42069/dohproxy:latest || fail_out "Unable to run dohproxy"
  # binding to privileged ports.
  podman run --rm --name dohot-pihole \
    --label "io.containers.autoupdate=registry" \
    --pod dohot \
    -e 'ServerIP=127.0.0.1' \
    -e 'PIHOLE_DNS_=127.0.0.1#5054' \
    -e 'TZ=Europe/London' \
    -v dohot-etc-dnsmasqd:/etc/dnsmasq.d/ \
    -v dohot-etc-pihole:/etc/pihole \
    -d docker.io/pihole/pihole:latest || fail_out "Unable to run pihole"
  # generate systemd service files, install and enable them.
  (cd /etc/systemd/system/ && podman generate systemd --new --name --files dohot && systemctl daemon-reload && systemctl enable --now pod-dohot.service)
  success_out "Done"
fi
