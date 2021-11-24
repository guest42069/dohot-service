FROM golang:1.17-alpine AS build
ENV CGO_ENABLED=0
RUN go install -tags netgo -a -installsuffix netgo -ldflags '-extldflags "-static"' github.com/dnscrypt/dnscrypt-proxy/dnscrypt-proxy@2.1.1
FROM alpine
COPY --from=build /go/bin/dnscrypt-proxy /dnscrypt-proxy
RUN apk -U upgrade
RUN apk add --no-cache ca-certificates && rm -rf /var/cache/apk/* && mkdir -p /etc/dnscrypt-proxy/ /var/log/dnscrypt-proxy/
COPY dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
RUN addgroup -S dnscrypt && adduser -S dnscrypt -G dnscrypt
USER dnscrypt
EXPOSE 5054/udp
EXPOSE 5054/tcp
VOLUME [ "/var/log/dnscrypt-proxy/" ]
VOLUME [ "/etc/dnscrypt-proxy/" ]
ENTRYPOINT [ "/dnscrypt-proxy", "-config", "/etc/dnscrypt-proxy/dnscrypt-proxy.toml" ]
