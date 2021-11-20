#!/bin/bash
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
podman network exists dohot-net
if [[ $? -eq 1 ]]; then
  podman network create dohot-net --subnet 10.69.0.0/29
fi
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
podman run --rm --name dohot-torproxy --network=dohot-net --ip 10.69.0.4 -v dohot-var-lib-tor:/var/lib/tor -d localhost/torproxy
podman run --rm --name dohot-dohproxy --network=dohot-net --ip 10.69.0.2 -d localhost/dohproxy
# binding to privileged ports.
podman run --rm --name dohot-pihole --network=dohot-net -p 53:53/udp -p 53:53/tcp -p 80:80/tcp --ip 10.69.0.3 -e 'ServerIP=10.69.0.3' -e 'PIHOLE_DNS_=10.69.0.2#5054' -e 'TZ=Europe/London' -v dohot-etc-dnsmasqd:/etc/dnsmasq.d/ -v dohot-etc-pihole:/etc/pihole -d docker.io/pihole/pihole
