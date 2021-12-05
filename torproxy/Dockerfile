FROM alpine
RUN apk -U upgrade --no-cache
RUN apk add tor --no-cache
EXPOSE 9050
VOLUME ["/var/log/tor"]
VOLUME ["/var/lib/tor"]
USER tor
ENTRYPOINT ["/usr/bin/tor", "--socksport", "0.0.0.0:9050"]
