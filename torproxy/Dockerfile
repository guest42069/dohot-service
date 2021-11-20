FROM alpine
RUN apk -U upgrade
RUN apk add tor
EXPOSE 9050
VOLUME ["/var/lib/tor"]
USER tor
CMD tor --socksport 0.0.0.0:9050
