FROM alpine
RUN apk -U upgrade
RUN apk add tor && rm -rf /var/cache/apk/*
EXPOSE 9050
VOLUME ["/var/lib/tor"]
USER tor
ENTRYPOINT ["/usr/bin/tor", "--socksport", "0.0.0.0:9050"]
